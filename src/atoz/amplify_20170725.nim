
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_CreateApp_603060 = ref object of OpenApiRestCall_602466
proc url_CreateApp_603062(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_603061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Algorithm")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Algorithm", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_CreateApp_603060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_CreateApp_603060; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_603073 = newJObject()
  if body != nil:
    body_603073 = body
  result = call_603072.call(nil, nil, nil, nil, body_603073)

var createApp* = Call_CreateApp_603060(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_603061,
                                    base: "/", url: url_CreateApp_603062,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_602803 = ref object of OpenApiRestCall_602466
proc url_ListApps_602805(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApps_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602917 = query.getOrDefault("maxResults")
  valid_602917 = validateParameter(valid_602917, JInt, required = false, default = nil)
  if valid_602917 != nil:
    section.add "maxResults", valid_602917
  var valid_602918 = query.getOrDefault("nextToken")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "nextToken", valid_602918
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
  var valid_602919 = header.getOrDefault("X-Amz-Date")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Date", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Algorithm")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Algorithm", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Signature")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Signature", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-SignedHeaders", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Credential")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Credential", valid_602925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602948: Call_ListApps_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_602948.validator(path, query, header, formData, body)
  let scheme = call_602948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602948.url(scheme.get, call_602948.host, call_602948.base,
                         call_602948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602948, url, valid)

proc call*(call_603019: Call_ListApps_602803; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  var query_603020 = newJObject()
  add(query_603020, "maxResults", newJInt(maxResults))
  add(query_603020, "nextToken", newJString(nextToken))
  result = call_603019.call(nil, query_603020, nil, nil, nil)

var listApps* = Call_ListApps_602803(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_602804, base: "/",
                                  url: url_ListApps_602805,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_603105 = ref object of OpenApiRestCall_602466
proc url_CreateBranch_603107(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBranch_603106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603108 = path.getOrDefault("appId")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "appId", valid_603108
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
  var valid_603109 = header.getOrDefault("X-Amz-Date")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Date", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Security-Token")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Security-Token", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Content-Sha256", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Algorithm")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Algorithm", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Signature")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Signature", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-SignedHeaders", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Credential")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Credential", valid_603115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603117: Call_CreateBranch_603105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_603117.validator(path, query, header, formData, body)
  let scheme = call_603117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603117.url(scheme.get, call_603117.host, call_603117.base,
                         call_603117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603117, url, valid)

proc call*(call_603118: Call_CreateBranch_603105; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_603119 = newJObject()
  var body_603120 = newJObject()
  add(path_603119, "appId", newJString(appId))
  if body != nil:
    body_603120 = body
  result = call_603118.call(path_603119, nil, nil, nil, body_603120)

var createBranch* = Call_CreateBranch_603105(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_603106,
    base: "/", url: url_CreateBranch_603107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_603074 = ref object of OpenApiRestCall_602466
proc url_ListBranches_603076(protocol: Scheme; host: string; base: string;
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

proc validate_ListBranches_603075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603091 = path.getOrDefault("appId")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = nil)
  if valid_603091 != nil:
    section.add "appId", valid_603091
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  section = newJObject()
  var valid_603092 = query.getOrDefault("maxResults")
  valid_603092 = validateParameter(valid_603092, JInt, required = false, default = nil)
  if valid_603092 != nil:
    section.add "maxResults", valid_603092
  var valid_603093 = query.getOrDefault("nextToken")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "nextToken", valid_603093
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
  var valid_603094 = header.getOrDefault("X-Amz-Date")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Date", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Security-Token")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Security-Token", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Algorithm")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Algorithm", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-SignedHeaders", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Credential")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Credential", valid_603100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_ListBranches_603074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603101, url, valid)

proc call*(call_603102: Call_ListBranches_603074; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  var path_603103 = newJObject()
  var query_603104 = newJObject()
  add(path_603103, "appId", newJString(appId))
  add(query_603104, "maxResults", newJInt(maxResults))
  add(query_603104, "nextToken", newJString(nextToken))
  result = call_603102.call(path_603103, query_603104, nil, nil, nil)

var listBranches* = Call_ListBranches_603074(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_603075,
    base: "/", url: url_ListBranches_603076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_603121 = ref object of OpenApiRestCall_602466
proc url_CreateDeployment_603123(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_603122(path: JsonNode; query: JsonNode;
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
  var valid_603124 = path.getOrDefault("appId")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "appId", valid_603124
  var valid_603125 = path.getOrDefault("branchName")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "branchName", valid_603125
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
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Security-Token")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Security-Token", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Content-Sha256", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Credential")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Credential", valid_603132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_CreateDeployment_603121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_CreateDeployment_603121; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603136 = newJObject()
  var body_603137 = newJObject()
  add(path_603136, "appId", newJString(appId))
  if body != nil:
    body_603137 = body
  add(path_603136, "branchName", newJString(branchName))
  result = call_603135.call(path_603136, nil, nil, nil, body_603137)

var createDeployment* = Call_CreateDeployment_603121(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_603122, base: "/",
    url: url_CreateDeployment_603123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_603155 = ref object of OpenApiRestCall_602466
proc url_CreateDomainAssociation_603157(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainAssociation_603156(path: JsonNode; query: JsonNode;
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
  var valid_603158 = path.getOrDefault("appId")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "appId", valid_603158
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
  var valid_603159 = header.getOrDefault("X-Amz-Date")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Date", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Security-Token")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Security-Token", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Content-Sha256", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Algorithm")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Algorithm", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Signature")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Signature", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-SignedHeaders", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Credential")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Credential", valid_603165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_CreateDomainAssociation_603155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_CreateDomainAssociation_603155; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_603169 = newJObject()
  var body_603170 = newJObject()
  add(path_603169, "appId", newJString(appId))
  if body != nil:
    body_603170 = body
  result = call_603168.call(path_603169, nil, nil, nil, body_603170)

var createDomainAssociation* = Call_CreateDomainAssociation_603155(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_603156, base: "/",
    url: url_CreateDomainAssociation_603157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_603138 = ref object of OpenApiRestCall_602466
proc url_ListDomainAssociations_603140(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomainAssociations_603139(path: JsonNode; query: JsonNode;
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
  var valid_603141 = path.getOrDefault("appId")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "appId", valid_603141
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  section = newJObject()
  var valid_603142 = query.getOrDefault("maxResults")
  valid_603142 = validateParameter(valid_603142, JInt, required = false, default = nil)
  if valid_603142 != nil:
    section.add "maxResults", valid_603142
  var valid_603143 = query.getOrDefault("nextToken")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "nextToken", valid_603143
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
  var valid_603144 = header.getOrDefault("X-Amz-Date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Date", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Security-Token")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Security-Token", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Content-Sha256", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Algorithm")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Algorithm", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-SignedHeaders", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Credential")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Credential", valid_603150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603151: Call_ListDomainAssociations_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_603151.validator(path, query, header, formData, body)
  let scheme = call_603151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603151.url(scheme.get, call_603151.host, call_603151.base,
                         call_603151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603151, url, valid)

proc call*(call_603152: Call_ListDomainAssociations_603138; appId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  var path_603153 = newJObject()
  var query_603154 = newJObject()
  add(path_603153, "appId", newJString(appId))
  add(query_603154, "maxResults", newJInt(maxResults))
  add(query_603154, "nextToken", newJString(nextToken))
  result = call_603152.call(path_603153, query_603154, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_603138(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_603139, base: "/",
    url: url_ListDomainAssociations_603140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_603188 = ref object of OpenApiRestCall_602466
proc url_CreateWebhook_603190(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_603189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603191 = path.getOrDefault("appId")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "appId", valid_603191
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603200: Call_CreateWebhook_603188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_603200.validator(path, query, header, formData, body)
  let scheme = call_603200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603200.url(scheme.get, call_603200.host, call_603200.base,
                         call_603200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603200, url, valid)

proc call*(call_603201: Call_CreateWebhook_603188; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_603202 = newJObject()
  var body_603203 = newJObject()
  add(path_603202, "appId", newJString(appId))
  if body != nil:
    body_603203 = body
  result = call_603201.call(path_603202, nil, nil, nil, body_603203)

var createWebhook* = Call_CreateWebhook_603188(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_603189,
    base: "/", url: url_CreateWebhook_603190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_603171 = ref object of OpenApiRestCall_602466
proc url_ListWebhooks_603173(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_603172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603174 = path.getOrDefault("appId")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "appId", valid_603174
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  section = newJObject()
  var valid_603175 = query.getOrDefault("maxResults")
  valid_603175 = validateParameter(valid_603175, JInt, required = false, default = nil)
  if valid_603175 != nil:
    section.add "maxResults", valid_603175
  var valid_603176 = query.getOrDefault("nextToken")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "nextToken", valid_603176
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
  if body != nil:
    result.add "body", body

proc call*(call_603184: Call_ListWebhooks_603171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_603184.validator(path, query, header, formData, body)
  let scheme = call_603184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603184.url(scheme.get, call_603184.host, call_603184.base,
                         call_603184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603184, url, valid)

proc call*(call_603185: Call_ListWebhooks_603171; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  var path_603186 = newJObject()
  var query_603187 = newJObject()
  add(path_603186, "appId", newJString(appId))
  add(query_603187, "maxResults", newJInt(maxResults))
  add(query_603187, "nextToken", newJString(nextToken))
  result = call_603185.call(path_603186, query_603187, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_603171(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_603172,
    base: "/", url: url_ListWebhooks_603173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_603218 = ref object of OpenApiRestCall_602466
proc url_UpdateApp_603220(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_603219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603221 = path.getOrDefault("appId")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "appId", valid_603221
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603230: Call_UpdateApp_603218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_603230.validator(path, query, header, formData, body)
  let scheme = call_603230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603230.url(scheme.get, call_603230.host, call_603230.base,
                         call_603230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603230, url, valid)

proc call*(call_603231: Call_UpdateApp_603218; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_603232 = newJObject()
  var body_603233 = newJObject()
  add(path_603232, "appId", newJString(appId))
  if body != nil:
    body_603233 = body
  result = call_603231.call(path_603232, nil, nil, nil, body_603233)

var updateApp* = Call_UpdateApp_603218(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_603219,
                                    base: "/", url: url_UpdateApp_603220,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_603204 = ref object of OpenApiRestCall_602466
proc url_GetApp_603206(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_603205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603207 = path.getOrDefault("appId")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = nil)
  if valid_603207 != nil:
    section.add "appId", valid_603207
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
  var valid_603208 = header.getOrDefault("X-Amz-Date")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Date", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Security-Token")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Security-Token", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603215: Call_GetApp_603204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_603215.validator(path, query, header, formData, body)
  let scheme = call_603215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603215.url(scheme.get, call_603215.host, call_603215.base,
                         call_603215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603215, url, valid)

proc call*(call_603216: Call_GetApp_603204; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_603217 = newJObject()
  add(path_603217, "appId", newJString(appId))
  result = call_603216.call(path_603217, nil, nil, nil, nil)

var getApp* = Call_GetApp_603204(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_603205,
                              base: "/", url: url_GetApp_603206,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_603234 = ref object of OpenApiRestCall_602466
proc url_DeleteApp_603236(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_603235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603237 = path.getOrDefault("appId")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "appId", valid_603237
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
  var valid_603238 = header.getOrDefault("X-Amz-Date")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Date", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Security-Token")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Security-Token", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_DeleteApp_603234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_DeleteApp_603234; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_603247 = newJObject()
  add(path_603247, "appId", newJString(appId))
  result = call_603246.call(path_603247, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_603234(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_603235,
                                    base: "/", url: url_DeleteApp_603236,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_603263 = ref object of OpenApiRestCall_602466
proc url_UpdateBranch_603265(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBranch_603264(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603266 = path.getOrDefault("appId")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "appId", valid_603266
  var valid_603267 = path.getOrDefault("branchName")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "branchName", valid_603267
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
  var valid_603268 = header.getOrDefault("X-Amz-Date")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Date", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Security-Token")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Security-Token", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_UpdateBranch_603263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_UpdateBranch_603263; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_603278 = newJObject()
  var body_603279 = newJObject()
  add(path_603278, "appId", newJString(appId))
  if body != nil:
    body_603279 = body
  add(path_603278, "branchName", newJString(branchName))
  result = call_603277.call(path_603278, nil, nil, nil, body_603279)

var updateBranch* = Call_UpdateBranch_603263(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_603264, base: "/", url: url_UpdateBranch_603265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_603248 = ref object of OpenApiRestCall_602466
proc url_GetBranch_603250(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBranch_603249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603251 = path.getOrDefault("appId")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "appId", valid_603251
  var valid_603252 = path.getOrDefault("branchName")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "branchName", valid_603252
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
  var valid_603253 = header.getOrDefault("X-Amz-Date")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Date", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Security-Token")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Security-Token", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603260: Call_GetBranch_603248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_603260.validator(path, query, header, formData, body)
  let scheme = call_603260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603260.url(scheme.get, call_603260.host, call_603260.base,
                         call_603260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603260, url, valid)

proc call*(call_603261: Call_GetBranch_603248; appId: string; branchName: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_603262 = newJObject()
  add(path_603262, "appId", newJString(appId))
  add(path_603262, "branchName", newJString(branchName))
  result = call_603261.call(path_603262, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_603248(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_603249,
                                    base: "/", url: url_GetBranch_603250,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_603280 = ref object of OpenApiRestCall_602466
proc url_DeleteBranch_603282(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBranch_603281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603283 = path.getOrDefault("appId")
  valid_603283 = validateParameter(valid_603283, JString, required = true,
                                 default = nil)
  if valid_603283 != nil:
    section.add "appId", valid_603283
  var valid_603284 = path.getOrDefault("branchName")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "branchName", valid_603284
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Content-Sha256", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Algorithm")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Algorithm", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Signature")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Signature", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-SignedHeaders", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Credential")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Credential", valid_603291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603292: Call_DeleteBranch_603280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_603292.validator(path, query, header, formData, body)
  let scheme = call_603292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603292.url(scheme.get, call_603292.host, call_603292.base,
                         call_603292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603292, url, valid)

proc call*(call_603293: Call_DeleteBranch_603280; appId: string; branchName: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_603294 = newJObject()
  add(path_603294, "appId", newJString(appId))
  add(path_603294, "branchName", newJString(branchName))
  result = call_603293.call(path_603294, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_603280(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_603281, base: "/", url: url_DeleteBranch_603282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_603310 = ref object of OpenApiRestCall_602466
proc url_UpdateDomainAssociation_603312(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainAssociation_603311(path: JsonNode; query: JsonNode;
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
  var valid_603313 = path.getOrDefault("appId")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = nil)
  if valid_603313 != nil:
    section.add "appId", valid_603313
  var valid_603314 = path.getOrDefault("domainName")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = nil)
  if valid_603314 != nil:
    section.add "domainName", valid_603314
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Algorithm")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Algorithm", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Signature", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-SignedHeaders", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_UpdateDomainAssociation_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603323, url, valid)

proc call*(call_603324: Call_UpdateDomainAssociation_603310; appId: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  ##   body: JObject (required)
  var path_603325 = newJObject()
  var body_603326 = newJObject()
  add(path_603325, "appId", newJString(appId))
  add(path_603325, "domainName", newJString(domainName))
  if body != nil:
    body_603326 = body
  result = call_603324.call(path_603325, nil, nil, nil, body_603326)

var updateDomainAssociation* = Call_UpdateDomainAssociation_603310(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_603311, base: "/",
    url: url_UpdateDomainAssociation_603312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_603295 = ref object of OpenApiRestCall_602466
proc url_GetDomainAssociation_603297(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainAssociation_603296(path: JsonNode; query: JsonNode;
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
  var valid_603298 = path.getOrDefault("appId")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = nil)
  if valid_603298 != nil:
    section.add "appId", valid_603298
  var valid_603299 = path.getOrDefault("domainName")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "domainName", valid_603299
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Content-Sha256", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Algorithm")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Algorithm", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Signature")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Signature", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-SignedHeaders", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Credential")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Credential", valid_603306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603307: Call_GetDomainAssociation_603295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_603307.validator(path, query, header, formData, body)
  let scheme = call_603307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603307.url(scheme.get, call_603307.host, call_603307.base,
                         call_603307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603307, url, valid)

proc call*(call_603308: Call_GetDomainAssociation_603295; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_603309 = newJObject()
  add(path_603309, "appId", newJString(appId))
  add(path_603309, "domainName", newJString(domainName))
  result = call_603308.call(path_603309, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_603295(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_603296, base: "/",
    url: url_GetDomainAssociation_603297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_603327 = ref object of OpenApiRestCall_602466
proc url_DeleteDomainAssociation_603329(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainAssociation_603328(path: JsonNode; query: JsonNode;
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
  var valid_603330 = path.getOrDefault("appId")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = nil)
  if valid_603330 != nil:
    section.add "appId", valid_603330
  var valid_603331 = path.getOrDefault("domainName")
  valid_603331 = validateParameter(valid_603331, JString, required = true,
                                 default = nil)
  if valid_603331 != nil:
    section.add "domainName", valid_603331
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
  var valid_603332 = header.getOrDefault("X-Amz-Date")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Date", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Security-Token")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Security-Token", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Content-Sha256", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Algorithm")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Algorithm", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Signature")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Signature", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-SignedHeaders", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Credential")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Credential", valid_603338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DeleteDomainAssociation_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DeleteDomainAssociation_603327; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_603341 = newJObject()
  add(path_603341, "appId", newJString(appId))
  add(path_603341, "domainName", newJString(domainName))
  result = call_603340.call(path_603341, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_603327(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_603328, base: "/",
    url: url_DeleteDomainAssociation_603329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_603342 = ref object of OpenApiRestCall_602466
proc url_GetJob_603344(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_603343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603345 = path.getOrDefault("jobId")
  valid_603345 = validateParameter(valid_603345, JString, required = true,
                                 default = nil)
  if valid_603345 != nil:
    section.add "jobId", valid_603345
  var valid_603346 = path.getOrDefault("appId")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = nil)
  if valid_603346 != nil:
    section.add "appId", valid_603346
  var valid_603347 = path.getOrDefault("branchName")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "branchName", valid_603347
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
  var valid_603348 = header.getOrDefault("X-Amz-Date")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Date", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Security-Token")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Security-Token", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Content-Sha256", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Algorithm")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Algorithm", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Signature")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Signature", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-SignedHeaders", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Credential")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Credential", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603355: Call_GetJob_603342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_603355.validator(path, query, header, formData, body)
  let scheme = call_603355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603355.url(scheme.get, call_603355.host, call_603355.base,
                         call_603355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603355, url, valid)

proc call*(call_603356: Call_GetJob_603342; jobId: string; appId: string;
          branchName: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603357 = newJObject()
  add(path_603357, "jobId", newJString(jobId))
  add(path_603357, "appId", newJString(appId))
  add(path_603357, "branchName", newJString(branchName))
  result = call_603356.call(path_603357, nil, nil, nil, nil)

var getJob* = Call_GetJob_603342(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_603343, base: "/",
                              url: url_GetJob_603344,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_603358 = ref object of OpenApiRestCall_602466
proc url_DeleteJob_603360(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_603359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603361 = path.getOrDefault("jobId")
  valid_603361 = validateParameter(valid_603361, JString, required = true,
                                 default = nil)
  if valid_603361 != nil:
    section.add "jobId", valid_603361
  var valid_603362 = path.getOrDefault("appId")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = nil)
  if valid_603362 != nil:
    section.add "appId", valid_603362
  var valid_603363 = path.getOrDefault("branchName")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "branchName", valid_603363
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603371: Call_DeleteJob_603358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_603371.validator(path, query, header, formData, body)
  let scheme = call_603371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603371.url(scheme.get, call_603371.host, call_603371.base,
                         call_603371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603371, url, valid)

proc call*(call_603372: Call_DeleteJob_603358; jobId: string; appId: string;
          branchName: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603373 = newJObject()
  add(path_603373, "jobId", newJString(jobId))
  add(path_603373, "appId", newJString(appId))
  add(path_603373, "branchName", newJString(branchName))
  result = call_603372.call(path_603373, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_603358(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_603359,
                                    base: "/", url: url_DeleteJob_603360,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_603388 = ref object of OpenApiRestCall_602466
proc url_UpdateWebhook_603390(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_603389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603391 = path.getOrDefault("webhookId")
  valid_603391 = validateParameter(valid_603391, JString, required = true,
                                 default = nil)
  if valid_603391 != nil:
    section.add "webhookId", valid_603391
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
  var valid_603392 = header.getOrDefault("X-Amz-Date")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Date", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Security-Token")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Security-Token", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Content-Sha256", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Algorithm")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Algorithm", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Signature")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Signature", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-SignedHeaders", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Credential")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Credential", valid_603398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_UpdateWebhook_603388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_UpdateWebhook_603388; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_603402 = newJObject()
  var body_603403 = newJObject()
  add(path_603402, "webhookId", newJString(webhookId))
  if body != nil:
    body_603403 = body
  result = call_603401.call(path_603402, nil, nil, nil, body_603403)

var updateWebhook* = Call_UpdateWebhook_603388(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_603389,
    base: "/", url: url_UpdateWebhook_603390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_603374 = ref object of OpenApiRestCall_602466
proc url_GetWebhook_603376(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetWebhook_603375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603377 = path.getOrDefault("webhookId")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = nil)
  if valid_603377 != nil:
    section.add "webhookId", valid_603377
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
  var valid_603378 = header.getOrDefault("X-Amz-Date")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Date", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Security-Token")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Security-Token", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Content-Sha256", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Algorithm")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Algorithm", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Signature")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Signature", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-SignedHeaders", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Credential")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Credential", valid_603384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603385: Call_GetWebhook_603374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_603385.validator(path, query, header, formData, body)
  let scheme = call_603385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603385.url(scheme.get, call_603385.host, call_603385.base,
                         call_603385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603385, url, valid)

proc call*(call_603386: Call_GetWebhook_603374; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_603387 = newJObject()
  add(path_603387, "webhookId", newJString(webhookId))
  result = call_603386.call(path_603387, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_603374(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_603375,
                                      base: "/", url: url_GetWebhook_603376,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_603404 = ref object of OpenApiRestCall_602466
proc url_DeleteWebhook_603406(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_603405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603407 = path.getOrDefault("webhookId")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = nil)
  if valid_603407 != nil:
    section.add "webhookId", valid_603407
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
  var valid_603408 = header.getOrDefault("X-Amz-Date")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Date", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Security-Token")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Security-Token", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Algorithm")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Algorithm", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Signature")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Signature", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-SignedHeaders", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_DeleteWebhook_603404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_DeleteWebhook_603404; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_603417 = newJObject()
  add(path_603417, "webhookId", newJString(webhookId))
  result = call_603416.call(path_603417, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_603404(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_603405,
    base: "/", url: url_DeleteWebhook_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_603418 = ref object of OpenApiRestCall_602466
proc url_GenerateAccessLogs_603420(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateAccessLogs_603419(path: JsonNode; query: JsonNode;
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
  var valid_603421 = path.getOrDefault("appId")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = nil)
  if valid_603421 != nil:
    section.add "appId", valid_603421
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_GenerateAccessLogs_603418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_GenerateAccessLogs_603418; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_603432 = newJObject()
  var body_603433 = newJObject()
  add(path_603432, "appId", newJString(appId))
  if body != nil:
    body_603433 = body
  result = call_603431.call(path_603432, nil, nil, nil, body_603433)

var generateAccessLogs* = Call_GenerateAccessLogs_603418(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_603419, base: "/",
    url: url_GenerateAccessLogs_603420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_603434 = ref object of OpenApiRestCall_602466
proc url_GetArtifactUrl_603436(protocol: Scheme; host: string; base: string;
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

proc validate_GetArtifactUrl_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = path.getOrDefault("artifactId")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = nil)
  if valid_603437 != nil:
    section.add "artifactId", valid_603437
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
  var valid_603438 = header.getOrDefault("X-Amz-Date")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Date", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Security-Token")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Security-Token", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Content-Sha256", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Algorithm")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Algorithm", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Signature")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Signature", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-SignedHeaders", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Credential")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Credential", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_GetArtifactUrl_603434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_GetArtifactUrl_603434; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_603447 = newJObject()
  add(path_603447, "artifactId", newJString(artifactId))
  result = call_603446.call(path_603447, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_603434(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_603435,
    base: "/", url: url_GetArtifactUrl_603436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_603448 = ref object of OpenApiRestCall_602466
proc url_ListArtifacts_603450(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_603449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603451 = path.getOrDefault("jobId")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = nil)
  if valid_603451 != nil:
    section.add "jobId", valid_603451
  var valid_603452 = path.getOrDefault("appId")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = nil)
  if valid_603452 != nil:
    section.add "appId", valid_603452
  var valid_603453 = path.getOrDefault("branchName")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "branchName", valid_603453
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  section = newJObject()
  var valid_603454 = query.getOrDefault("maxResults")
  valid_603454 = validateParameter(valid_603454, JInt, required = false, default = nil)
  if valid_603454 != nil:
    section.add "maxResults", valid_603454
  var valid_603455 = query.getOrDefault("nextToken")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "nextToken", valid_603455
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
  var valid_603456 = header.getOrDefault("X-Amz-Date")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Date", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Security-Token")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Security-Token", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Content-Sha256", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Algorithm")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Algorithm", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Signature")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Signature", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-SignedHeaders", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Credential")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Credential", valid_603462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603464: Call_ListArtifacts_603448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_603464.validator(path, query, header, formData, body)
  let scheme = call_603464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603464.url(scheme.get, call_603464.host, call_603464.base,
                         call_603464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603464, url, valid)

proc call*(call_603465: Call_ListArtifacts_603448; jobId: string; appId: string;
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
  var path_603466 = newJObject()
  var query_603467 = newJObject()
  var body_603468 = newJObject()
  add(path_603466, "jobId", newJString(jobId))
  add(path_603466, "appId", newJString(appId))
  add(query_603467, "maxResults", newJInt(maxResults))
  add(query_603467, "nextToken", newJString(nextToken))
  if body != nil:
    body_603468 = body
  add(path_603466, "branchName", newJString(branchName))
  result = call_603465.call(path_603466, query_603467, nil, nil, body_603468)

var listArtifacts* = Call_ListArtifacts_603448(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_603449, base: "/", url: url_ListArtifacts_603450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_603487 = ref object of OpenApiRestCall_602466
proc url_StartJob_603489(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartJob_603488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603490 = path.getOrDefault("appId")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = nil)
  if valid_603490 != nil:
    section.add "appId", valid_603490
  var valid_603491 = path.getOrDefault("branchName")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = nil)
  if valid_603491 != nil:
    section.add "branchName", valid_603491
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
  var valid_603492 = header.getOrDefault("X-Amz-Date")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Date", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Security-Token")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Security-Token", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Content-Sha256", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Algorithm")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Algorithm", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Signature")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Signature", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-SignedHeaders", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Credential")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Credential", valid_603498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603500: Call_StartJob_603487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_603500.validator(path, query, header, formData, body)
  let scheme = call_603500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603500.url(scheme.get, call_603500.host, call_603500.base,
                         call_603500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603500, url, valid)

proc call*(call_603501: Call_StartJob_603487; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603502 = newJObject()
  var body_603503 = newJObject()
  add(path_603502, "appId", newJString(appId))
  if body != nil:
    body_603503 = body
  add(path_603502, "branchName", newJString(branchName))
  result = call_603501.call(path_603502, nil, nil, nil, body_603503)

var startJob* = Call_StartJob_603487(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_603488, base: "/",
                                  url: url_StartJob_603489,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_603469 = ref object of OpenApiRestCall_602466
proc url_ListJobs_603471(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_603470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603472 = path.getOrDefault("appId")
  valid_603472 = validateParameter(valid_603472, JString, required = true,
                                 default = nil)
  if valid_603472 != nil:
    section.add "appId", valid_603472
  var valid_603473 = path.getOrDefault("branchName")
  valid_603473 = validateParameter(valid_603473, JString, required = true,
                                 default = nil)
  if valid_603473 != nil:
    section.add "branchName", valid_603473
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  section = newJObject()
  var valid_603474 = query.getOrDefault("maxResults")
  valid_603474 = validateParameter(valid_603474, JInt, required = false, default = nil)
  if valid_603474 != nil:
    section.add "maxResults", valid_603474
  var valid_603475 = query.getOrDefault("nextToken")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "nextToken", valid_603475
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

proc call*(call_603483: Call_ListJobs_603469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_603483.validator(path, query, header, formData, body)
  let scheme = call_603483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603483.url(scheme.get, call_603483.host, call_603483.base,
                         call_603483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603483, url, valid)

proc call*(call_603484: Call_ListJobs_603469; appId: string; branchName: string;
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
  var path_603485 = newJObject()
  var query_603486 = newJObject()
  add(path_603485, "appId", newJString(appId))
  add(query_603486, "maxResults", newJInt(maxResults))
  add(query_603486, "nextToken", newJString(nextToken))
  add(path_603485, "branchName", newJString(branchName))
  result = call_603484.call(path_603485, query_603486, nil, nil, nil)

var listJobs* = Call_ListJobs_603469(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_603470, base: "/",
                                  url: url_ListJobs_603471,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603518 = ref object of OpenApiRestCall_602466
proc url_TagResource_603520(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603521 = path.getOrDefault("resourceArn")
  valid_603521 = validateParameter(valid_603521, JString, required = true,
                                 default = nil)
  if valid_603521 != nil:
    section.add "resourceArn", valid_603521
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
  var valid_603522 = header.getOrDefault("X-Amz-Date")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Date", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Security-Token")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Security-Token", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Content-Sha256", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Algorithm")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Algorithm", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Signature")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Signature", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-SignedHeaders", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Credential")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Credential", valid_603528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603530: Call_TagResource_603518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_603530.validator(path, query, header, formData, body)
  let scheme = call_603530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603530.url(scheme.get, call_603530.host, call_603530.base,
                         call_603530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603530, url, valid)

proc call*(call_603531: Call_TagResource_603518; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  var path_603532 = newJObject()
  var body_603533 = newJObject()
  if body != nil:
    body_603533 = body
  add(path_603532, "resourceArn", newJString(resourceArn))
  result = call_603531.call(path_603532, nil, nil, nil, body_603533)

var tagResource* = Call_TagResource_603518(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_603519,
                                        base: "/", url: url_TagResource_603520,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603504 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603506(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_603505(path: JsonNode; query: JsonNode;
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
  var valid_603507 = path.getOrDefault("resourceArn")
  valid_603507 = validateParameter(valid_603507, JString, required = true,
                                 default = nil)
  if valid_603507 != nil:
    section.add "resourceArn", valid_603507
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
  var valid_603508 = header.getOrDefault("X-Amz-Date")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Date", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Algorithm")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Algorithm", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-SignedHeaders", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Credential")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Credential", valid_603514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603515: Call_ListTagsForResource_603504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_603515.validator(path, query, header, formData, body)
  let scheme = call_603515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603515.url(scheme.get, call_603515.host, call_603515.base,
                         call_603515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603515, url, valid)

proc call*(call_603516: Call_ListTagsForResource_603504; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_603517 = newJObject()
  add(path_603517, "resourceArn", newJString(resourceArn))
  result = call_603516.call(path_603517, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603504(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_603505, base: "/",
    url: url_ListTagsForResource_603506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_603534 = ref object of OpenApiRestCall_602466
proc url_StartDeployment_603536(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_603535(path: JsonNode; query: JsonNode;
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
  var valid_603537 = path.getOrDefault("appId")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "appId", valid_603537
  var valid_603538 = path.getOrDefault("branchName")
  valid_603538 = validateParameter(valid_603538, JString, required = true,
                                 default = nil)
  if valid_603538 != nil:
    section.add "branchName", valid_603538
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
  var valid_603539 = header.getOrDefault("X-Amz-Date")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Date", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Security-Token")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Security-Token", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Content-Sha256", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Algorithm")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Algorithm", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Signature")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Signature", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-SignedHeaders", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Credential")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Credential", valid_603545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603547: Call_StartDeployment_603534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_603547.validator(path, query, header, formData, body)
  let scheme = call_603547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603547.url(scheme.get, call_603547.host, call_603547.base,
                         call_603547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603547, url, valid)

proc call*(call_603548: Call_StartDeployment_603534; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603549 = newJObject()
  var body_603550 = newJObject()
  add(path_603549, "appId", newJString(appId))
  if body != nil:
    body_603550 = body
  add(path_603549, "branchName", newJString(branchName))
  result = call_603548.call(path_603549, nil, nil, nil, body_603550)

var startDeployment* = Call_StartDeployment_603534(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_603535, base: "/", url: url_StartDeployment_603536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_603551 = ref object of OpenApiRestCall_602466
proc url_StopJob_603553(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_603552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603554 = path.getOrDefault("jobId")
  valid_603554 = validateParameter(valid_603554, JString, required = true,
                                 default = nil)
  if valid_603554 != nil:
    section.add "jobId", valid_603554
  var valid_603555 = path.getOrDefault("appId")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = nil)
  if valid_603555 != nil:
    section.add "appId", valid_603555
  var valid_603556 = path.getOrDefault("branchName")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = nil)
  if valid_603556 != nil:
    section.add "branchName", valid_603556
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
  var valid_603557 = header.getOrDefault("X-Amz-Date")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Date", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Security-Token")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Security-Token", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Content-Sha256", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Signature")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Signature", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-SignedHeaders", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Credential")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Credential", valid_603563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603564: Call_StopJob_603551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_603564.validator(path, query, header, formData, body)
  let scheme = call_603564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603564.url(scheme.get, call_603564.host, call_603564.base,
                         call_603564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603564, url, valid)

proc call*(call_603565: Call_StopJob_603551; jobId: string; appId: string;
          branchName: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_603566 = newJObject()
  add(path_603566, "jobId", newJString(jobId))
  add(path_603566, "appId", newJString(appId))
  add(path_603566, "branchName", newJString(branchName))
  result = call_603565.call(path_603566, nil, nil, nil, nil)

var stopJob* = Call_StopJob_603551(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_603552, base: "/",
                                url: url_StopJob_603553,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603567 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603569(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603570 = path.getOrDefault("resourceArn")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = nil)
  if valid_603570 != nil:
    section.add "resourceArn", valid_603570
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603571 = query.getOrDefault("tagKeys")
  valid_603571 = validateParameter(valid_603571, JArray, required = true, default = nil)
  if valid_603571 != nil:
    section.add "tagKeys", valid_603571
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
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Security-Token")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Security-Token", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Content-Sha256", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Signature")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Signature", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Credential")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Credential", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_UntagResource_603567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_UntagResource_603567; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  var path_603581 = newJObject()
  var query_603582 = newJObject()
  if tagKeys != nil:
    query_603582.add "tagKeys", tagKeys
  add(path_603581, "resourceArn", newJString(resourceArn))
  result = call_603580.call(path_603581, query_603582, nil, nil, nil)

var untagResource* = Call_UntagResource_603567(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_603568,
    base: "/", url: url_UntagResource_603569, schemes: {Scheme.Https, Scheme.Http})
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
