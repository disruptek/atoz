
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

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_591960 = ref object of OpenApiRestCall_591364
proc url_CreateApp_591962(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_591961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591963 = header.getOrDefault("X-Amz-Signature")
  valid_591963 = validateParameter(valid_591963, JString, required = false,
                                 default = nil)
  if valid_591963 != nil:
    section.add "X-Amz-Signature", valid_591963
  var valid_591964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591964 = validateParameter(valid_591964, JString, required = false,
                                 default = nil)
  if valid_591964 != nil:
    section.add "X-Amz-Content-Sha256", valid_591964
  var valid_591965 = header.getOrDefault("X-Amz-Date")
  valid_591965 = validateParameter(valid_591965, JString, required = false,
                                 default = nil)
  if valid_591965 != nil:
    section.add "X-Amz-Date", valid_591965
  var valid_591966 = header.getOrDefault("X-Amz-Credential")
  valid_591966 = validateParameter(valid_591966, JString, required = false,
                                 default = nil)
  if valid_591966 != nil:
    section.add "X-Amz-Credential", valid_591966
  var valid_591967 = header.getOrDefault("X-Amz-Security-Token")
  valid_591967 = validateParameter(valid_591967, JString, required = false,
                                 default = nil)
  if valid_591967 != nil:
    section.add "X-Amz-Security-Token", valid_591967
  var valid_591968 = header.getOrDefault("X-Amz-Algorithm")
  valid_591968 = validateParameter(valid_591968, JString, required = false,
                                 default = nil)
  if valid_591968 != nil:
    section.add "X-Amz-Algorithm", valid_591968
  var valid_591969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591969 = validateParameter(valid_591969, JString, required = false,
                                 default = nil)
  if valid_591969 != nil:
    section.add "X-Amz-SignedHeaders", valid_591969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591971: Call_CreateApp_591960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_591971.validator(path, query, header, formData, body)
  let scheme = call_591971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591971.url(scheme.get, call_591971.host, call_591971.base,
                         call_591971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591971, url, valid)

proc call*(call_591972: Call_CreateApp_591960; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_591973 = newJObject()
  if body != nil:
    body_591973 = body
  result = call_591972.call(nil, nil, nil, nil, body_591973)

var createApp* = Call_CreateApp_591960(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_591961,
                                    base: "/", url: url_CreateApp_591962,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_591703 = ref object of OpenApiRestCall_591364
proc url_ListApps_591705(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApps_591704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591817 = query.getOrDefault("nextToken")
  valid_591817 = validateParameter(valid_591817, JString, required = false,
                                 default = nil)
  if valid_591817 != nil:
    section.add "nextToken", valid_591817
  var valid_591818 = query.getOrDefault("maxResults")
  valid_591818 = validateParameter(valid_591818, JInt, required = false, default = nil)
  if valid_591818 != nil:
    section.add "maxResults", valid_591818
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
  var valid_591819 = header.getOrDefault("X-Amz-Signature")
  valid_591819 = validateParameter(valid_591819, JString, required = false,
                                 default = nil)
  if valid_591819 != nil:
    section.add "X-Amz-Signature", valid_591819
  var valid_591820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591820 = validateParameter(valid_591820, JString, required = false,
                                 default = nil)
  if valid_591820 != nil:
    section.add "X-Amz-Content-Sha256", valid_591820
  var valid_591821 = header.getOrDefault("X-Amz-Date")
  valid_591821 = validateParameter(valid_591821, JString, required = false,
                                 default = nil)
  if valid_591821 != nil:
    section.add "X-Amz-Date", valid_591821
  var valid_591822 = header.getOrDefault("X-Amz-Credential")
  valid_591822 = validateParameter(valid_591822, JString, required = false,
                                 default = nil)
  if valid_591822 != nil:
    section.add "X-Amz-Credential", valid_591822
  var valid_591823 = header.getOrDefault("X-Amz-Security-Token")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-Security-Token", valid_591823
  var valid_591824 = header.getOrDefault("X-Amz-Algorithm")
  valid_591824 = validateParameter(valid_591824, JString, required = false,
                                 default = nil)
  if valid_591824 != nil:
    section.add "X-Amz-Algorithm", valid_591824
  var valid_591825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-SignedHeaders", valid_591825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591848: Call_ListApps_591703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_591848.validator(path, query, header, formData, body)
  let scheme = call_591848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591848.url(scheme.get, call_591848.host, call_591848.base,
                         call_591848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591848, url, valid)

proc call*(call_591919: Call_ListApps_591703; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_591920 = newJObject()
  add(query_591920, "nextToken", newJString(nextToken))
  add(query_591920, "maxResults", newJInt(maxResults))
  result = call_591919.call(nil, query_591920, nil, nil, nil)

var listApps* = Call_ListApps_591703(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_591704, base: "/",
                                  url: url_ListApps_591705,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_592005 = ref object of OpenApiRestCall_591364
proc url_CreateBranch_592007(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBranch_592006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592008 = path.getOrDefault("appId")
  valid_592008 = validateParameter(valid_592008, JString, required = true,
                                 default = nil)
  if valid_592008 != nil:
    section.add "appId", valid_592008
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
  var valid_592009 = header.getOrDefault("X-Amz-Signature")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Signature", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Content-Sha256", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Date")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Date", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-Credential")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-Credential", valid_592012
  var valid_592013 = header.getOrDefault("X-Amz-Security-Token")
  valid_592013 = validateParameter(valid_592013, JString, required = false,
                                 default = nil)
  if valid_592013 != nil:
    section.add "X-Amz-Security-Token", valid_592013
  var valid_592014 = header.getOrDefault("X-Amz-Algorithm")
  valid_592014 = validateParameter(valid_592014, JString, required = false,
                                 default = nil)
  if valid_592014 != nil:
    section.add "X-Amz-Algorithm", valid_592014
  var valid_592015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592015 = validateParameter(valid_592015, JString, required = false,
                                 default = nil)
  if valid_592015 != nil:
    section.add "X-Amz-SignedHeaders", valid_592015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592017: Call_CreateBranch_592005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_592017.validator(path, query, header, formData, body)
  let scheme = call_592017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592017.url(scheme.get, call_592017.host, call_592017.base,
                         call_592017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592017, url, valid)

proc call*(call_592018: Call_CreateBranch_592005; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592019 = newJObject()
  var body_592020 = newJObject()
  add(path_592019, "appId", newJString(appId))
  if body != nil:
    body_592020 = body
  result = call_592018.call(path_592019, nil, nil, nil, body_592020)

var createBranch* = Call_CreateBranch_592005(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_592006,
    base: "/", url: url_CreateBranch_592007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_591974 = ref object of OpenApiRestCall_591364
proc url_ListBranches_591976(protocol: Scheme; host: string; base: string;
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

proc validate_ListBranches_591975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591991 = path.getOrDefault("appId")
  valid_591991 = validateParameter(valid_591991, JString, required = true,
                                 default = nil)
  if valid_591991 != nil:
    section.add "appId", valid_591991
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_591992 = query.getOrDefault("nextToken")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "nextToken", valid_591992
  var valid_591993 = query.getOrDefault("maxResults")
  valid_591993 = validateParameter(valid_591993, JInt, required = false, default = nil)
  if valid_591993 != nil:
    section.add "maxResults", valid_591993
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
  var valid_591994 = header.getOrDefault("X-Amz-Signature")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Signature", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Content-Sha256", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Date")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Date", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-Credential")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-Credential", valid_591997
  var valid_591998 = header.getOrDefault("X-Amz-Security-Token")
  valid_591998 = validateParameter(valid_591998, JString, required = false,
                                 default = nil)
  if valid_591998 != nil:
    section.add "X-Amz-Security-Token", valid_591998
  var valid_591999 = header.getOrDefault("X-Amz-Algorithm")
  valid_591999 = validateParameter(valid_591999, JString, required = false,
                                 default = nil)
  if valid_591999 != nil:
    section.add "X-Amz-Algorithm", valid_591999
  var valid_592000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592000 = validateParameter(valid_592000, JString, required = false,
                                 default = nil)
  if valid_592000 != nil:
    section.add "X-Amz-SignedHeaders", valid_592000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592001: Call_ListBranches_591974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_592001.validator(path, query, header, formData, body)
  let scheme = call_592001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592001.url(scheme.get, call_592001.host, call_592001.base,
                         call_592001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592001, url, valid)

proc call*(call_592002: Call_ListBranches_591974; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_592003 = newJObject()
  var query_592004 = newJObject()
  add(query_592004, "nextToken", newJString(nextToken))
  add(path_592003, "appId", newJString(appId))
  add(query_592004, "maxResults", newJInt(maxResults))
  result = call_592002.call(path_592003, query_592004, nil, nil, nil)

var listBranches* = Call_ListBranches_591974(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_591975,
    base: "/", url: url_ListBranches_591976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_592021 = ref object of OpenApiRestCall_591364
proc url_CreateDeployment_592023(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_592022(path: JsonNode; query: JsonNode;
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
  var valid_592024 = path.getOrDefault("branchName")
  valid_592024 = validateParameter(valid_592024, JString, required = true,
                                 default = nil)
  if valid_592024 != nil:
    section.add "branchName", valid_592024
  var valid_592025 = path.getOrDefault("appId")
  valid_592025 = validateParameter(valid_592025, JString, required = true,
                                 default = nil)
  if valid_592025 != nil:
    section.add "appId", valid_592025
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
  var valid_592026 = header.getOrDefault("X-Amz-Signature")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Signature", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-Content-Sha256", valid_592027
  var valid_592028 = header.getOrDefault("X-Amz-Date")
  valid_592028 = validateParameter(valid_592028, JString, required = false,
                                 default = nil)
  if valid_592028 != nil:
    section.add "X-Amz-Date", valid_592028
  var valid_592029 = header.getOrDefault("X-Amz-Credential")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "X-Amz-Credential", valid_592029
  var valid_592030 = header.getOrDefault("X-Amz-Security-Token")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = nil)
  if valid_592030 != nil:
    section.add "X-Amz-Security-Token", valid_592030
  var valid_592031 = header.getOrDefault("X-Amz-Algorithm")
  valid_592031 = validateParameter(valid_592031, JString, required = false,
                                 default = nil)
  if valid_592031 != nil:
    section.add "X-Amz-Algorithm", valid_592031
  var valid_592032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592032 = validateParameter(valid_592032, JString, required = false,
                                 default = nil)
  if valid_592032 != nil:
    section.add "X-Amz-SignedHeaders", valid_592032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592034: Call_CreateDeployment_592021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_592034.validator(path, query, header, formData, body)
  let scheme = call_592034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592034.url(scheme.get, call_592034.host, call_592034.base,
                         call_592034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592034, url, valid)

proc call*(call_592035: Call_CreateDeployment_592021; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592036 = newJObject()
  var body_592037 = newJObject()
  add(path_592036, "branchName", newJString(branchName))
  add(path_592036, "appId", newJString(appId))
  if body != nil:
    body_592037 = body
  result = call_592035.call(path_592036, nil, nil, nil, body_592037)

var createDeployment* = Call_CreateDeployment_592021(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_592022, base: "/",
    url: url_CreateDeployment_592023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_592055 = ref object of OpenApiRestCall_591364
proc url_CreateDomainAssociation_592057(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainAssociation_592056(path: JsonNode; query: JsonNode;
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
  var valid_592058 = path.getOrDefault("appId")
  valid_592058 = validateParameter(valid_592058, JString, required = true,
                                 default = nil)
  if valid_592058 != nil:
    section.add "appId", valid_592058
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
  var valid_592059 = header.getOrDefault("X-Amz-Signature")
  valid_592059 = validateParameter(valid_592059, JString, required = false,
                                 default = nil)
  if valid_592059 != nil:
    section.add "X-Amz-Signature", valid_592059
  var valid_592060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592060 = validateParameter(valid_592060, JString, required = false,
                                 default = nil)
  if valid_592060 != nil:
    section.add "X-Amz-Content-Sha256", valid_592060
  var valid_592061 = header.getOrDefault("X-Amz-Date")
  valid_592061 = validateParameter(valid_592061, JString, required = false,
                                 default = nil)
  if valid_592061 != nil:
    section.add "X-Amz-Date", valid_592061
  var valid_592062 = header.getOrDefault("X-Amz-Credential")
  valid_592062 = validateParameter(valid_592062, JString, required = false,
                                 default = nil)
  if valid_592062 != nil:
    section.add "X-Amz-Credential", valid_592062
  var valid_592063 = header.getOrDefault("X-Amz-Security-Token")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "X-Amz-Security-Token", valid_592063
  var valid_592064 = header.getOrDefault("X-Amz-Algorithm")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-Algorithm", valid_592064
  var valid_592065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-SignedHeaders", valid_592065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592067: Call_CreateDomainAssociation_592055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_592067.validator(path, query, header, formData, body)
  let scheme = call_592067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592067.url(scheme.get, call_592067.host, call_592067.base,
                         call_592067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592067, url, valid)

proc call*(call_592068: Call_CreateDomainAssociation_592055; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592069 = newJObject()
  var body_592070 = newJObject()
  add(path_592069, "appId", newJString(appId))
  if body != nil:
    body_592070 = body
  result = call_592068.call(path_592069, nil, nil, nil, body_592070)

var createDomainAssociation* = Call_CreateDomainAssociation_592055(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_592056, base: "/",
    url: url_CreateDomainAssociation_592057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_592038 = ref object of OpenApiRestCall_591364
proc url_ListDomainAssociations_592040(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomainAssociations_592039(path: JsonNode; query: JsonNode;
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
  var valid_592041 = path.getOrDefault("appId")
  valid_592041 = validateParameter(valid_592041, JString, required = true,
                                 default = nil)
  if valid_592041 != nil:
    section.add "appId", valid_592041
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_592042 = query.getOrDefault("nextToken")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "nextToken", valid_592042
  var valid_592043 = query.getOrDefault("maxResults")
  valid_592043 = validateParameter(valid_592043, JInt, required = false, default = nil)
  if valid_592043 != nil:
    section.add "maxResults", valid_592043
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
  var valid_592044 = header.getOrDefault("X-Amz-Signature")
  valid_592044 = validateParameter(valid_592044, JString, required = false,
                                 default = nil)
  if valid_592044 != nil:
    section.add "X-Amz-Signature", valid_592044
  var valid_592045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Content-Sha256", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-Date")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-Date", valid_592046
  var valid_592047 = header.getOrDefault("X-Amz-Credential")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "X-Amz-Credential", valid_592047
  var valid_592048 = header.getOrDefault("X-Amz-Security-Token")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Security-Token", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Algorithm")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Algorithm", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-SignedHeaders", valid_592050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592051: Call_ListDomainAssociations_592038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_592051.validator(path, query, header, formData, body)
  let scheme = call_592051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592051.url(scheme.get, call_592051.host, call_592051.base,
                         call_592051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592051, url, valid)

proc call*(call_592052: Call_ListDomainAssociations_592038; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_592053 = newJObject()
  var query_592054 = newJObject()
  add(query_592054, "nextToken", newJString(nextToken))
  add(path_592053, "appId", newJString(appId))
  add(query_592054, "maxResults", newJInt(maxResults))
  result = call_592052.call(path_592053, query_592054, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_592038(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_592039, base: "/",
    url: url_ListDomainAssociations_592040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_592088 = ref object of OpenApiRestCall_591364
proc url_CreateWebhook_592090(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_592089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592091 = path.getOrDefault("appId")
  valid_592091 = validateParameter(valid_592091, JString, required = true,
                                 default = nil)
  if valid_592091 != nil:
    section.add "appId", valid_592091
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
  var valid_592092 = header.getOrDefault("X-Amz-Signature")
  valid_592092 = validateParameter(valid_592092, JString, required = false,
                                 default = nil)
  if valid_592092 != nil:
    section.add "X-Amz-Signature", valid_592092
  var valid_592093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592093 = validateParameter(valid_592093, JString, required = false,
                                 default = nil)
  if valid_592093 != nil:
    section.add "X-Amz-Content-Sha256", valid_592093
  var valid_592094 = header.getOrDefault("X-Amz-Date")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-Date", valid_592094
  var valid_592095 = header.getOrDefault("X-Amz-Credential")
  valid_592095 = validateParameter(valid_592095, JString, required = false,
                                 default = nil)
  if valid_592095 != nil:
    section.add "X-Amz-Credential", valid_592095
  var valid_592096 = header.getOrDefault("X-Amz-Security-Token")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "X-Amz-Security-Token", valid_592096
  var valid_592097 = header.getOrDefault("X-Amz-Algorithm")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "X-Amz-Algorithm", valid_592097
  var valid_592098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592098 = validateParameter(valid_592098, JString, required = false,
                                 default = nil)
  if valid_592098 != nil:
    section.add "X-Amz-SignedHeaders", valid_592098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592100: Call_CreateWebhook_592088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_592100.validator(path, query, header, formData, body)
  let scheme = call_592100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592100.url(scheme.get, call_592100.host, call_592100.base,
                         call_592100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592100, url, valid)

proc call*(call_592101: Call_CreateWebhook_592088; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592102 = newJObject()
  var body_592103 = newJObject()
  add(path_592102, "appId", newJString(appId))
  if body != nil:
    body_592103 = body
  result = call_592101.call(path_592102, nil, nil, nil, body_592103)

var createWebhook* = Call_CreateWebhook_592088(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_592089,
    base: "/", url: url_CreateWebhook_592090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_592071 = ref object of OpenApiRestCall_591364
proc url_ListWebhooks_592073(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_592072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592074 = path.getOrDefault("appId")
  valid_592074 = validateParameter(valid_592074, JString, required = true,
                                 default = nil)
  if valid_592074 != nil:
    section.add "appId", valid_592074
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_592075 = query.getOrDefault("nextToken")
  valid_592075 = validateParameter(valid_592075, JString, required = false,
                                 default = nil)
  if valid_592075 != nil:
    section.add "nextToken", valid_592075
  var valid_592076 = query.getOrDefault("maxResults")
  valid_592076 = validateParameter(valid_592076, JInt, required = false, default = nil)
  if valid_592076 != nil:
    section.add "maxResults", valid_592076
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
  var valid_592077 = header.getOrDefault("X-Amz-Signature")
  valid_592077 = validateParameter(valid_592077, JString, required = false,
                                 default = nil)
  if valid_592077 != nil:
    section.add "X-Amz-Signature", valid_592077
  var valid_592078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "X-Amz-Content-Sha256", valid_592078
  var valid_592079 = header.getOrDefault("X-Amz-Date")
  valid_592079 = validateParameter(valid_592079, JString, required = false,
                                 default = nil)
  if valid_592079 != nil:
    section.add "X-Amz-Date", valid_592079
  var valid_592080 = header.getOrDefault("X-Amz-Credential")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "X-Amz-Credential", valid_592080
  var valid_592081 = header.getOrDefault("X-Amz-Security-Token")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Security-Token", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Algorithm")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Algorithm", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-SignedHeaders", valid_592083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592084: Call_ListWebhooks_592071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_592084.validator(path, query, header, formData, body)
  let scheme = call_592084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592084.url(scheme.get, call_592084.host, call_592084.base,
                         call_592084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592084, url, valid)

proc call*(call_592085: Call_ListWebhooks_592071; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_592086 = newJObject()
  var query_592087 = newJObject()
  add(query_592087, "nextToken", newJString(nextToken))
  add(path_592086, "appId", newJString(appId))
  add(query_592087, "maxResults", newJInt(maxResults))
  result = call_592085.call(path_592086, query_592087, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_592071(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_592072,
    base: "/", url: url_ListWebhooks_592073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_592118 = ref object of OpenApiRestCall_591364
proc url_UpdateApp_592120(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_592119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592121 = path.getOrDefault("appId")
  valid_592121 = validateParameter(valid_592121, JString, required = true,
                                 default = nil)
  if valid_592121 != nil:
    section.add "appId", valid_592121
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
  var valid_592122 = header.getOrDefault("X-Amz-Signature")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "X-Amz-Signature", valid_592122
  var valid_592123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "X-Amz-Content-Sha256", valid_592123
  var valid_592124 = header.getOrDefault("X-Amz-Date")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-Date", valid_592124
  var valid_592125 = header.getOrDefault("X-Amz-Credential")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Credential", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-Security-Token")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-Security-Token", valid_592126
  var valid_592127 = header.getOrDefault("X-Amz-Algorithm")
  valid_592127 = validateParameter(valid_592127, JString, required = false,
                                 default = nil)
  if valid_592127 != nil:
    section.add "X-Amz-Algorithm", valid_592127
  var valid_592128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "X-Amz-SignedHeaders", valid_592128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592130: Call_UpdateApp_592118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_592130.validator(path, query, header, formData, body)
  let scheme = call_592130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592130.url(scheme.get, call_592130.host, call_592130.base,
                         call_592130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592130, url, valid)

proc call*(call_592131: Call_UpdateApp_592118; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592132 = newJObject()
  var body_592133 = newJObject()
  add(path_592132, "appId", newJString(appId))
  if body != nil:
    body_592133 = body
  result = call_592131.call(path_592132, nil, nil, nil, body_592133)

var updateApp* = Call_UpdateApp_592118(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_592119,
                                    base: "/", url: url_UpdateApp_592120,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_592104 = ref object of OpenApiRestCall_591364
proc url_GetApp_592106(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_592105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592107 = path.getOrDefault("appId")
  valid_592107 = validateParameter(valid_592107, JString, required = true,
                                 default = nil)
  if valid_592107 != nil:
    section.add "appId", valid_592107
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
  var valid_592108 = header.getOrDefault("X-Amz-Signature")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-Signature", valid_592108
  var valid_592109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-Content-Sha256", valid_592109
  var valid_592110 = header.getOrDefault("X-Amz-Date")
  valid_592110 = validateParameter(valid_592110, JString, required = false,
                                 default = nil)
  if valid_592110 != nil:
    section.add "X-Amz-Date", valid_592110
  var valid_592111 = header.getOrDefault("X-Amz-Credential")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-Credential", valid_592111
  var valid_592112 = header.getOrDefault("X-Amz-Security-Token")
  valid_592112 = validateParameter(valid_592112, JString, required = false,
                                 default = nil)
  if valid_592112 != nil:
    section.add "X-Amz-Security-Token", valid_592112
  var valid_592113 = header.getOrDefault("X-Amz-Algorithm")
  valid_592113 = validateParameter(valid_592113, JString, required = false,
                                 default = nil)
  if valid_592113 != nil:
    section.add "X-Amz-Algorithm", valid_592113
  var valid_592114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592114 = validateParameter(valid_592114, JString, required = false,
                                 default = nil)
  if valid_592114 != nil:
    section.add "X-Amz-SignedHeaders", valid_592114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592115: Call_GetApp_592104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_592115.validator(path, query, header, formData, body)
  let scheme = call_592115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592115.url(scheme.get, call_592115.host, call_592115.base,
                         call_592115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592115, url, valid)

proc call*(call_592116: Call_GetApp_592104; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592117 = newJObject()
  add(path_592117, "appId", newJString(appId))
  result = call_592116.call(path_592117, nil, nil, nil, nil)

var getApp* = Call_GetApp_592104(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_592105,
                              base: "/", url: url_GetApp_592106,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_592134 = ref object of OpenApiRestCall_591364
proc url_DeleteApp_592136(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_592135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592137 = path.getOrDefault("appId")
  valid_592137 = validateParameter(valid_592137, JString, required = true,
                                 default = nil)
  if valid_592137 != nil:
    section.add "appId", valid_592137
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
  var valid_592138 = header.getOrDefault("X-Amz-Signature")
  valid_592138 = validateParameter(valid_592138, JString, required = false,
                                 default = nil)
  if valid_592138 != nil:
    section.add "X-Amz-Signature", valid_592138
  var valid_592139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "X-Amz-Content-Sha256", valid_592139
  var valid_592140 = header.getOrDefault("X-Amz-Date")
  valid_592140 = validateParameter(valid_592140, JString, required = false,
                                 default = nil)
  if valid_592140 != nil:
    section.add "X-Amz-Date", valid_592140
  var valid_592141 = header.getOrDefault("X-Amz-Credential")
  valid_592141 = validateParameter(valid_592141, JString, required = false,
                                 default = nil)
  if valid_592141 != nil:
    section.add "X-Amz-Credential", valid_592141
  var valid_592142 = header.getOrDefault("X-Amz-Security-Token")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-Security-Token", valid_592142
  var valid_592143 = header.getOrDefault("X-Amz-Algorithm")
  valid_592143 = validateParameter(valid_592143, JString, required = false,
                                 default = nil)
  if valid_592143 != nil:
    section.add "X-Amz-Algorithm", valid_592143
  var valid_592144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592144 = validateParameter(valid_592144, JString, required = false,
                                 default = nil)
  if valid_592144 != nil:
    section.add "X-Amz-SignedHeaders", valid_592144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592145: Call_DeleteApp_592134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_592145.validator(path, query, header, formData, body)
  let scheme = call_592145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592145.url(scheme.get, call_592145.host, call_592145.base,
                         call_592145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592145, url, valid)

proc call*(call_592146: Call_DeleteApp_592134; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592147 = newJObject()
  add(path_592147, "appId", newJString(appId))
  result = call_592146.call(path_592147, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_592134(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_592135,
                                    base: "/", url: url_DeleteApp_592136,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_592163 = ref object of OpenApiRestCall_591364
proc url_UpdateBranch_592165(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBranch_592164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592166 = path.getOrDefault("branchName")
  valid_592166 = validateParameter(valid_592166, JString, required = true,
                                 default = nil)
  if valid_592166 != nil:
    section.add "branchName", valid_592166
  var valid_592167 = path.getOrDefault("appId")
  valid_592167 = validateParameter(valid_592167, JString, required = true,
                                 default = nil)
  if valid_592167 != nil:
    section.add "appId", valid_592167
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
  var valid_592168 = header.getOrDefault("X-Amz-Signature")
  valid_592168 = validateParameter(valid_592168, JString, required = false,
                                 default = nil)
  if valid_592168 != nil:
    section.add "X-Amz-Signature", valid_592168
  var valid_592169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592169 = validateParameter(valid_592169, JString, required = false,
                                 default = nil)
  if valid_592169 != nil:
    section.add "X-Amz-Content-Sha256", valid_592169
  var valid_592170 = header.getOrDefault("X-Amz-Date")
  valid_592170 = validateParameter(valid_592170, JString, required = false,
                                 default = nil)
  if valid_592170 != nil:
    section.add "X-Amz-Date", valid_592170
  var valid_592171 = header.getOrDefault("X-Amz-Credential")
  valid_592171 = validateParameter(valid_592171, JString, required = false,
                                 default = nil)
  if valid_592171 != nil:
    section.add "X-Amz-Credential", valid_592171
  var valid_592172 = header.getOrDefault("X-Amz-Security-Token")
  valid_592172 = validateParameter(valid_592172, JString, required = false,
                                 default = nil)
  if valid_592172 != nil:
    section.add "X-Amz-Security-Token", valid_592172
  var valid_592173 = header.getOrDefault("X-Amz-Algorithm")
  valid_592173 = validateParameter(valid_592173, JString, required = false,
                                 default = nil)
  if valid_592173 != nil:
    section.add "X-Amz-Algorithm", valid_592173
  var valid_592174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592174 = validateParameter(valid_592174, JString, required = false,
                                 default = nil)
  if valid_592174 != nil:
    section.add "X-Amz-SignedHeaders", valid_592174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592176: Call_UpdateBranch_592163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_592176.validator(path, query, header, formData, body)
  let scheme = call_592176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592176.url(scheme.get, call_592176.host, call_592176.base,
                         call_592176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592176, url, valid)

proc call*(call_592177: Call_UpdateBranch_592163; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592178 = newJObject()
  var body_592179 = newJObject()
  add(path_592178, "branchName", newJString(branchName))
  add(path_592178, "appId", newJString(appId))
  if body != nil:
    body_592179 = body
  result = call_592177.call(path_592178, nil, nil, nil, body_592179)

var updateBranch* = Call_UpdateBranch_592163(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_592164, base: "/", url: url_UpdateBranch_592165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_592148 = ref object of OpenApiRestCall_591364
proc url_GetBranch_592150(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBranch_592149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592151 = path.getOrDefault("branchName")
  valid_592151 = validateParameter(valid_592151, JString, required = true,
                                 default = nil)
  if valid_592151 != nil:
    section.add "branchName", valid_592151
  var valid_592152 = path.getOrDefault("appId")
  valid_592152 = validateParameter(valid_592152, JString, required = true,
                                 default = nil)
  if valid_592152 != nil:
    section.add "appId", valid_592152
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
  var valid_592153 = header.getOrDefault("X-Amz-Signature")
  valid_592153 = validateParameter(valid_592153, JString, required = false,
                                 default = nil)
  if valid_592153 != nil:
    section.add "X-Amz-Signature", valid_592153
  var valid_592154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592154 = validateParameter(valid_592154, JString, required = false,
                                 default = nil)
  if valid_592154 != nil:
    section.add "X-Amz-Content-Sha256", valid_592154
  var valid_592155 = header.getOrDefault("X-Amz-Date")
  valid_592155 = validateParameter(valid_592155, JString, required = false,
                                 default = nil)
  if valid_592155 != nil:
    section.add "X-Amz-Date", valid_592155
  var valid_592156 = header.getOrDefault("X-Amz-Credential")
  valid_592156 = validateParameter(valid_592156, JString, required = false,
                                 default = nil)
  if valid_592156 != nil:
    section.add "X-Amz-Credential", valid_592156
  var valid_592157 = header.getOrDefault("X-Amz-Security-Token")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "X-Amz-Security-Token", valid_592157
  var valid_592158 = header.getOrDefault("X-Amz-Algorithm")
  valid_592158 = validateParameter(valid_592158, JString, required = false,
                                 default = nil)
  if valid_592158 != nil:
    section.add "X-Amz-Algorithm", valid_592158
  var valid_592159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592159 = validateParameter(valid_592159, JString, required = false,
                                 default = nil)
  if valid_592159 != nil:
    section.add "X-Amz-SignedHeaders", valid_592159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592160: Call_GetBranch_592148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_592160.validator(path, query, header, formData, body)
  let scheme = call_592160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592160.url(scheme.get, call_592160.host, call_592160.base,
                         call_592160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592160, url, valid)

proc call*(call_592161: Call_GetBranch_592148; branchName: string; appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592162 = newJObject()
  add(path_592162, "branchName", newJString(branchName))
  add(path_592162, "appId", newJString(appId))
  result = call_592161.call(path_592162, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_592148(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_592149,
                                    base: "/", url: url_GetBranch_592150,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_592180 = ref object of OpenApiRestCall_591364
proc url_DeleteBranch_592182(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBranch_592181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592183 = path.getOrDefault("branchName")
  valid_592183 = validateParameter(valid_592183, JString, required = true,
                                 default = nil)
  if valid_592183 != nil:
    section.add "branchName", valid_592183
  var valid_592184 = path.getOrDefault("appId")
  valid_592184 = validateParameter(valid_592184, JString, required = true,
                                 default = nil)
  if valid_592184 != nil:
    section.add "appId", valid_592184
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
  var valid_592185 = header.getOrDefault("X-Amz-Signature")
  valid_592185 = validateParameter(valid_592185, JString, required = false,
                                 default = nil)
  if valid_592185 != nil:
    section.add "X-Amz-Signature", valid_592185
  var valid_592186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592186 = validateParameter(valid_592186, JString, required = false,
                                 default = nil)
  if valid_592186 != nil:
    section.add "X-Amz-Content-Sha256", valid_592186
  var valid_592187 = header.getOrDefault("X-Amz-Date")
  valid_592187 = validateParameter(valid_592187, JString, required = false,
                                 default = nil)
  if valid_592187 != nil:
    section.add "X-Amz-Date", valid_592187
  var valid_592188 = header.getOrDefault("X-Amz-Credential")
  valid_592188 = validateParameter(valid_592188, JString, required = false,
                                 default = nil)
  if valid_592188 != nil:
    section.add "X-Amz-Credential", valid_592188
  var valid_592189 = header.getOrDefault("X-Amz-Security-Token")
  valid_592189 = validateParameter(valid_592189, JString, required = false,
                                 default = nil)
  if valid_592189 != nil:
    section.add "X-Amz-Security-Token", valid_592189
  var valid_592190 = header.getOrDefault("X-Amz-Algorithm")
  valid_592190 = validateParameter(valid_592190, JString, required = false,
                                 default = nil)
  if valid_592190 != nil:
    section.add "X-Amz-Algorithm", valid_592190
  var valid_592191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592191 = validateParameter(valid_592191, JString, required = false,
                                 default = nil)
  if valid_592191 != nil:
    section.add "X-Amz-SignedHeaders", valid_592191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592192: Call_DeleteBranch_592180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_592192.validator(path, query, header, formData, body)
  let scheme = call_592192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592192.url(scheme.get, call_592192.host, call_592192.base,
                         call_592192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592192, url, valid)

proc call*(call_592193: Call_DeleteBranch_592180; branchName: string; appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592194 = newJObject()
  add(path_592194, "branchName", newJString(branchName))
  add(path_592194, "appId", newJString(appId))
  result = call_592193.call(path_592194, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_592180(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_592181, base: "/", url: url_DeleteBranch_592182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_592210 = ref object of OpenApiRestCall_591364
proc url_UpdateDomainAssociation_592212(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainAssociation_592211(path: JsonNode; query: JsonNode;
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
  var valid_592213 = path.getOrDefault("appId")
  valid_592213 = validateParameter(valid_592213, JString, required = true,
                                 default = nil)
  if valid_592213 != nil:
    section.add "appId", valid_592213
  var valid_592214 = path.getOrDefault("domainName")
  valid_592214 = validateParameter(valid_592214, JString, required = true,
                                 default = nil)
  if valid_592214 != nil:
    section.add "domainName", valid_592214
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
  var valid_592215 = header.getOrDefault("X-Amz-Signature")
  valid_592215 = validateParameter(valid_592215, JString, required = false,
                                 default = nil)
  if valid_592215 != nil:
    section.add "X-Amz-Signature", valid_592215
  var valid_592216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592216 = validateParameter(valid_592216, JString, required = false,
                                 default = nil)
  if valid_592216 != nil:
    section.add "X-Amz-Content-Sha256", valid_592216
  var valid_592217 = header.getOrDefault("X-Amz-Date")
  valid_592217 = validateParameter(valid_592217, JString, required = false,
                                 default = nil)
  if valid_592217 != nil:
    section.add "X-Amz-Date", valid_592217
  var valid_592218 = header.getOrDefault("X-Amz-Credential")
  valid_592218 = validateParameter(valid_592218, JString, required = false,
                                 default = nil)
  if valid_592218 != nil:
    section.add "X-Amz-Credential", valid_592218
  var valid_592219 = header.getOrDefault("X-Amz-Security-Token")
  valid_592219 = validateParameter(valid_592219, JString, required = false,
                                 default = nil)
  if valid_592219 != nil:
    section.add "X-Amz-Security-Token", valid_592219
  var valid_592220 = header.getOrDefault("X-Amz-Algorithm")
  valid_592220 = validateParameter(valid_592220, JString, required = false,
                                 default = nil)
  if valid_592220 != nil:
    section.add "X-Amz-Algorithm", valid_592220
  var valid_592221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592221 = validateParameter(valid_592221, JString, required = false,
                                 default = nil)
  if valid_592221 != nil:
    section.add "X-Amz-SignedHeaders", valid_592221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592223: Call_UpdateDomainAssociation_592210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_592223.validator(path, query, header, formData, body)
  let scheme = call_592223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592223.url(scheme.get, call_592223.host, call_592223.base,
                         call_592223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592223, url, valid)

proc call*(call_592224: Call_UpdateDomainAssociation_592210; appId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_592225 = newJObject()
  var body_592226 = newJObject()
  add(path_592225, "appId", newJString(appId))
  if body != nil:
    body_592226 = body
  add(path_592225, "domainName", newJString(domainName))
  result = call_592224.call(path_592225, nil, nil, nil, body_592226)

var updateDomainAssociation* = Call_UpdateDomainAssociation_592210(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_592211, base: "/",
    url: url_UpdateDomainAssociation_592212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_592195 = ref object of OpenApiRestCall_591364
proc url_GetDomainAssociation_592197(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainAssociation_592196(path: JsonNode; query: JsonNode;
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
  var valid_592198 = path.getOrDefault("appId")
  valid_592198 = validateParameter(valid_592198, JString, required = true,
                                 default = nil)
  if valid_592198 != nil:
    section.add "appId", valid_592198
  var valid_592199 = path.getOrDefault("domainName")
  valid_592199 = validateParameter(valid_592199, JString, required = true,
                                 default = nil)
  if valid_592199 != nil:
    section.add "domainName", valid_592199
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
  var valid_592200 = header.getOrDefault("X-Amz-Signature")
  valid_592200 = validateParameter(valid_592200, JString, required = false,
                                 default = nil)
  if valid_592200 != nil:
    section.add "X-Amz-Signature", valid_592200
  var valid_592201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592201 = validateParameter(valid_592201, JString, required = false,
                                 default = nil)
  if valid_592201 != nil:
    section.add "X-Amz-Content-Sha256", valid_592201
  var valid_592202 = header.getOrDefault("X-Amz-Date")
  valid_592202 = validateParameter(valid_592202, JString, required = false,
                                 default = nil)
  if valid_592202 != nil:
    section.add "X-Amz-Date", valid_592202
  var valid_592203 = header.getOrDefault("X-Amz-Credential")
  valid_592203 = validateParameter(valid_592203, JString, required = false,
                                 default = nil)
  if valid_592203 != nil:
    section.add "X-Amz-Credential", valid_592203
  var valid_592204 = header.getOrDefault("X-Amz-Security-Token")
  valid_592204 = validateParameter(valid_592204, JString, required = false,
                                 default = nil)
  if valid_592204 != nil:
    section.add "X-Amz-Security-Token", valid_592204
  var valid_592205 = header.getOrDefault("X-Amz-Algorithm")
  valid_592205 = validateParameter(valid_592205, JString, required = false,
                                 default = nil)
  if valid_592205 != nil:
    section.add "X-Amz-Algorithm", valid_592205
  var valid_592206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592206 = validateParameter(valid_592206, JString, required = false,
                                 default = nil)
  if valid_592206 != nil:
    section.add "X-Amz-SignedHeaders", valid_592206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592207: Call_GetDomainAssociation_592195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_592207.validator(path, query, header, formData, body)
  let scheme = call_592207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592207.url(scheme.get, call_592207.host, call_592207.base,
                         call_592207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592207, url, valid)

proc call*(call_592208: Call_GetDomainAssociation_592195; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_592209 = newJObject()
  add(path_592209, "appId", newJString(appId))
  add(path_592209, "domainName", newJString(domainName))
  result = call_592208.call(path_592209, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_592195(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_592196, base: "/",
    url: url_GetDomainAssociation_592197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_592227 = ref object of OpenApiRestCall_591364
proc url_DeleteDomainAssociation_592229(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainAssociation_592228(path: JsonNode; query: JsonNode;
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
  var valid_592230 = path.getOrDefault("appId")
  valid_592230 = validateParameter(valid_592230, JString, required = true,
                                 default = nil)
  if valid_592230 != nil:
    section.add "appId", valid_592230
  var valid_592231 = path.getOrDefault("domainName")
  valid_592231 = validateParameter(valid_592231, JString, required = true,
                                 default = nil)
  if valid_592231 != nil:
    section.add "domainName", valid_592231
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
  var valid_592232 = header.getOrDefault("X-Amz-Signature")
  valid_592232 = validateParameter(valid_592232, JString, required = false,
                                 default = nil)
  if valid_592232 != nil:
    section.add "X-Amz-Signature", valid_592232
  var valid_592233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592233 = validateParameter(valid_592233, JString, required = false,
                                 default = nil)
  if valid_592233 != nil:
    section.add "X-Amz-Content-Sha256", valid_592233
  var valid_592234 = header.getOrDefault("X-Amz-Date")
  valid_592234 = validateParameter(valid_592234, JString, required = false,
                                 default = nil)
  if valid_592234 != nil:
    section.add "X-Amz-Date", valid_592234
  var valid_592235 = header.getOrDefault("X-Amz-Credential")
  valid_592235 = validateParameter(valid_592235, JString, required = false,
                                 default = nil)
  if valid_592235 != nil:
    section.add "X-Amz-Credential", valid_592235
  var valid_592236 = header.getOrDefault("X-Amz-Security-Token")
  valid_592236 = validateParameter(valid_592236, JString, required = false,
                                 default = nil)
  if valid_592236 != nil:
    section.add "X-Amz-Security-Token", valid_592236
  var valid_592237 = header.getOrDefault("X-Amz-Algorithm")
  valid_592237 = validateParameter(valid_592237, JString, required = false,
                                 default = nil)
  if valid_592237 != nil:
    section.add "X-Amz-Algorithm", valid_592237
  var valid_592238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592238 = validateParameter(valid_592238, JString, required = false,
                                 default = nil)
  if valid_592238 != nil:
    section.add "X-Amz-SignedHeaders", valid_592238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592239: Call_DeleteDomainAssociation_592227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_592239.validator(path, query, header, formData, body)
  let scheme = call_592239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592239.url(scheme.get, call_592239.host, call_592239.base,
                         call_592239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592239, url, valid)

proc call*(call_592240: Call_DeleteDomainAssociation_592227; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_592241 = newJObject()
  add(path_592241, "appId", newJString(appId))
  add(path_592241, "domainName", newJString(domainName))
  result = call_592240.call(path_592241, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_592227(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_592228, base: "/",
    url: url_DeleteDomainAssociation_592229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_592242 = ref object of OpenApiRestCall_591364
proc url_GetJob_592244(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_592243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592245 = path.getOrDefault("jobId")
  valid_592245 = validateParameter(valid_592245, JString, required = true,
                                 default = nil)
  if valid_592245 != nil:
    section.add "jobId", valid_592245
  var valid_592246 = path.getOrDefault("branchName")
  valid_592246 = validateParameter(valid_592246, JString, required = true,
                                 default = nil)
  if valid_592246 != nil:
    section.add "branchName", valid_592246
  var valid_592247 = path.getOrDefault("appId")
  valid_592247 = validateParameter(valid_592247, JString, required = true,
                                 default = nil)
  if valid_592247 != nil:
    section.add "appId", valid_592247
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
  var valid_592248 = header.getOrDefault("X-Amz-Signature")
  valid_592248 = validateParameter(valid_592248, JString, required = false,
                                 default = nil)
  if valid_592248 != nil:
    section.add "X-Amz-Signature", valid_592248
  var valid_592249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592249 = validateParameter(valid_592249, JString, required = false,
                                 default = nil)
  if valid_592249 != nil:
    section.add "X-Amz-Content-Sha256", valid_592249
  var valid_592250 = header.getOrDefault("X-Amz-Date")
  valid_592250 = validateParameter(valid_592250, JString, required = false,
                                 default = nil)
  if valid_592250 != nil:
    section.add "X-Amz-Date", valid_592250
  var valid_592251 = header.getOrDefault("X-Amz-Credential")
  valid_592251 = validateParameter(valid_592251, JString, required = false,
                                 default = nil)
  if valid_592251 != nil:
    section.add "X-Amz-Credential", valid_592251
  var valid_592252 = header.getOrDefault("X-Amz-Security-Token")
  valid_592252 = validateParameter(valid_592252, JString, required = false,
                                 default = nil)
  if valid_592252 != nil:
    section.add "X-Amz-Security-Token", valid_592252
  var valid_592253 = header.getOrDefault("X-Amz-Algorithm")
  valid_592253 = validateParameter(valid_592253, JString, required = false,
                                 default = nil)
  if valid_592253 != nil:
    section.add "X-Amz-Algorithm", valid_592253
  var valid_592254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592254 = validateParameter(valid_592254, JString, required = false,
                                 default = nil)
  if valid_592254 != nil:
    section.add "X-Amz-SignedHeaders", valid_592254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592255: Call_GetJob_592242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_592255.validator(path, query, header, formData, body)
  let scheme = call_592255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592255.url(scheme.get, call_592255.host, call_592255.base,
                         call_592255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592255, url, valid)

proc call*(call_592256: Call_GetJob_592242; jobId: string; branchName: string;
          appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592257 = newJObject()
  add(path_592257, "jobId", newJString(jobId))
  add(path_592257, "branchName", newJString(branchName))
  add(path_592257, "appId", newJString(appId))
  result = call_592256.call(path_592257, nil, nil, nil, nil)

var getJob* = Call_GetJob_592242(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_592243, base: "/",
                              url: url_GetJob_592244,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_592258 = ref object of OpenApiRestCall_591364
proc url_DeleteJob_592260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_592259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592261 = path.getOrDefault("jobId")
  valid_592261 = validateParameter(valid_592261, JString, required = true,
                                 default = nil)
  if valid_592261 != nil:
    section.add "jobId", valid_592261
  var valid_592262 = path.getOrDefault("branchName")
  valid_592262 = validateParameter(valid_592262, JString, required = true,
                                 default = nil)
  if valid_592262 != nil:
    section.add "branchName", valid_592262
  var valid_592263 = path.getOrDefault("appId")
  valid_592263 = validateParameter(valid_592263, JString, required = true,
                                 default = nil)
  if valid_592263 != nil:
    section.add "appId", valid_592263
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
  var valid_592264 = header.getOrDefault("X-Amz-Signature")
  valid_592264 = validateParameter(valid_592264, JString, required = false,
                                 default = nil)
  if valid_592264 != nil:
    section.add "X-Amz-Signature", valid_592264
  var valid_592265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592265 = validateParameter(valid_592265, JString, required = false,
                                 default = nil)
  if valid_592265 != nil:
    section.add "X-Amz-Content-Sha256", valid_592265
  var valid_592266 = header.getOrDefault("X-Amz-Date")
  valid_592266 = validateParameter(valid_592266, JString, required = false,
                                 default = nil)
  if valid_592266 != nil:
    section.add "X-Amz-Date", valid_592266
  var valid_592267 = header.getOrDefault("X-Amz-Credential")
  valid_592267 = validateParameter(valid_592267, JString, required = false,
                                 default = nil)
  if valid_592267 != nil:
    section.add "X-Amz-Credential", valid_592267
  var valid_592268 = header.getOrDefault("X-Amz-Security-Token")
  valid_592268 = validateParameter(valid_592268, JString, required = false,
                                 default = nil)
  if valid_592268 != nil:
    section.add "X-Amz-Security-Token", valid_592268
  var valid_592269 = header.getOrDefault("X-Amz-Algorithm")
  valid_592269 = validateParameter(valid_592269, JString, required = false,
                                 default = nil)
  if valid_592269 != nil:
    section.add "X-Amz-Algorithm", valid_592269
  var valid_592270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592270 = validateParameter(valid_592270, JString, required = false,
                                 default = nil)
  if valid_592270 != nil:
    section.add "X-Amz-SignedHeaders", valid_592270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592271: Call_DeleteJob_592258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_592271.validator(path, query, header, formData, body)
  let scheme = call_592271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592271.url(scheme.get, call_592271.host, call_592271.base,
                         call_592271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592271, url, valid)

proc call*(call_592272: Call_DeleteJob_592258; jobId: string; branchName: string;
          appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592273 = newJObject()
  add(path_592273, "jobId", newJString(jobId))
  add(path_592273, "branchName", newJString(branchName))
  add(path_592273, "appId", newJString(appId))
  result = call_592272.call(path_592273, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_592258(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_592259,
                                    base: "/", url: url_DeleteJob_592260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_592288 = ref object of OpenApiRestCall_591364
proc url_UpdateWebhook_592290(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_592289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592291 = path.getOrDefault("webhookId")
  valid_592291 = validateParameter(valid_592291, JString, required = true,
                                 default = nil)
  if valid_592291 != nil:
    section.add "webhookId", valid_592291
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
  var valid_592292 = header.getOrDefault("X-Amz-Signature")
  valid_592292 = validateParameter(valid_592292, JString, required = false,
                                 default = nil)
  if valid_592292 != nil:
    section.add "X-Amz-Signature", valid_592292
  var valid_592293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592293 = validateParameter(valid_592293, JString, required = false,
                                 default = nil)
  if valid_592293 != nil:
    section.add "X-Amz-Content-Sha256", valid_592293
  var valid_592294 = header.getOrDefault("X-Amz-Date")
  valid_592294 = validateParameter(valid_592294, JString, required = false,
                                 default = nil)
  if valid_592294 != nil:
    section.add "X-Amz-Date", valid_592294
  var valid_592295 = header.getOrDefault("X-Amz-Credential")
  valid_592295 = validateParameter(valid_592295, JString, required = false,
                                 default = nil)
  if valid_592295 != nil:
    section.add "X-Amz-Credential", valid_592295
  var valid_592296 = header.getOrDefault("X-Amz-Security-Token")
  valid_592296 = validateParameter(valid_592296, JString, required = false,
                                 default = nil)
  if valid_592296 != nil:
    section.add "X-Amz-Security-Token", valid_592296
  var valid_592297 = header.getOrDefault("X-Amz-Algorithm")
  valid_592297 = validateParameter(valid_592297, JString, required = false,
                                 default = nil)
  if valid_592297 != nil:
    section.add "X-Amz-Algorithm", valid_592297
  var valid_592298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592298 = validateParameter(valid_592298, JString, required = false,
                                 default = nil)
  if valid_592298 != nil:
    section.add "X-Amz-SignedHeaders", valid_592298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592300: Call_UpdateWebhook_592288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_592300.validator(path, query, header, formData, body)
  let scheme = call_592300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592300.url(scheme.get, call_592300.host, call_592300.base,
                         call_592300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592300, url, valid)

proc call*(call_592301: Call_UpdateWebhook_592288; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_592302 = newJObject()
  var body_592303 = newJObject()
  add(path_592302, "webhookId", newJString(webhookId))
  if body != nil:
    body_592303 = body
  result = call_592301.call(path_592302, nil, nil, nil, body_592303)

var updateWebhook* = Call_UpdateWebhook_592288(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_592289,
    base: "/", url: url_UpdateWebhook_592290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_592274 = ref object of OpenApiRestCall_591364
proc url_GetWebhook_592276(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetWebhook_592275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592277 = path.getOrDefault("webhookId")
  valid_592277 = validateParameter(valid_592277, JString, required = true,
                                 default = nil)
  if valid_592277 != nil:
    section.add "webhookId", valid_592277
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
  var valid_592278 = header.getOrDefault("X-Amz-Signature")
  valid_592278 = validateParameter(valid_592278, JString, required = false,
                                 default = nil)
  if valid_592278 != nil:
    section.add "X-Amz-Signature", valid_592278
  var valid_592279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592279 = validateParameter(valid_592279, JString, required = false,
                                 default = nil)
  if valid_592279 != nil:
    section.add "X-Amz-Content-Sha256", valid_592279
  var valid_592280 = header.getOrDefault("X-Amz-Date")
  valid_592280 = validateParameter(valid_592280, JString, required = false,
                                 default = nil)
  if valid_592280 != nil:
    section.add "X-Amz-Date", valid_592280
  var valid_592281 = header.getOrDefault("X-Amz-Credential")
  valid_592281 = validateParameter(valid_592281, JString, required = false,
                                 default = nil)
  if valid_592281 != nil:
    section.add "X-Amz-Credential", valid_592281
  var valid_592282 = header.getOrDefault("X-Amz-Security-Token")
  valid_592282 = validateParameter(valid_592282, JString, required = false,
                                 default = nil)
  if valid_592282 != nil:
    section.add "X-Amz-Security-Token", valid_592282
  var valid_592283 = header.getOrDefault("X-Amz-Algorithm")
  valid_592283 = validateParameter(valid_592283, JString, required = false,
                                 default = nil)
  if valid_592283 != nil:
    section.add "X-Amz-Algorithm", valid_592283
  var valid_592284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592284 = validateParameter(valid_592284, JString, required = false,
                                 default = nil)
  if valid_592284 != nil:
    section.add "X-Amz-SignedHeaders", valid_592284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592285: Call_GetWebhook_592274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_592285.validator(path, query, header, formData, body)
  let scheme = call_592285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592285.url(scheme.get, call_592285.host, call_592285.base,
                         call_592285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592285, url, valid)

proc call*(call_592286: Call_GetWebhook_592274; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_592287 = newJObject()
  add(path_592287, "webhookId", newJString(webhookId))
  result = call_592286.call(path_592287, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_592274(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_592275,
                                      base: "/", url: url_GetWebhook_592276,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_592304 = ref object of OpenApiRestCall_591364
proc url_DeleteWebhook_592306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_592305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592307 = path.getOrDefault("webhookId")
  valid_592307 = validateParameter(valid_592307, JString, required = true,
                                 default = nil)
  if valid_592307 != nil:
    section.add "webhookId", valid_592307
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
  var valid_592308 = header.getOrDefault("X-Amz-Signature")
  valid_592308 = validateParameter(valid_592308, JString, required = false,
                                 default = nil)
  if valid_592308 != nil:
    section.add "X-Amz-Signature", valid_592308
  var valid_592309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592309 = validateParameter(valid_592309, JString, required = false,
                                 default = nil)
  if valid_592309 != nil:
    section.add "X-Amz-Content-Sha256", valid_592309
  var valid_592310 = header.getOrDefault("X-Amz-Date")
  valid_592310 = validateParameter(valid_592310, JString, required = false,
                                 default = nil)
  if valid_592310 != nil:
    section.add "X-Amz-Date", valid_592310
  var valid_592311 = header.getOrDefault("X-Amz-Credential")
  valid_592311 = validateParameter(valid_592311, JString, required = false,
                                 default = nil)
  if valid_592311 != nil:
    section.add "X-Amz-Credential", valid_592311
  var valid_592312 = header.getOrDefault("X-Amz-Security-Token")
  valid_592312 = validateParameter(valid_592312, JString, required = false,
                                 default = nil)
  if valid_592312 != nil:
    section.add "X-Amz-Security-Token", valid_592312
  var valid_592313 = header.getOrDefault("X-Amz-Algorithm")
  valid_592313 = validateParameter(valid_592313, JString, required = false,
                                 default = nil)
  if valid_592313 != nil:
    section.add "X-Amz-Algorithm", valid_592313
  var valid_592314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592314 = validateParameter(valid_592314, JString, required = false,
                                 default = nil)
  if valid_592314 != nil:
    section.add "X-Amz-SignedHeaders", valid_592314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592315: Call_DeleteWebhook_592304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_592315.validator(path, query, header, formData, body)
  let scheme = call_592315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592315.url(scheme.get, call_592315.host, call_592315.base,
                         call_592315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592315, url, valid)

proc call*(call_592316: Call_DeleteWebhook_592304; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_592317 = newJObject()
  add(path_592317, "webhookId", newJString(webhookId))
  result = call_592316.call(path_592317, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_592304(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_592305,
    base: "/", url: url_DeleteWebhook_592306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_592318 = ref object of OpenApiRestCall_591364
proc url_GenerateAccessLogs_592320(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateAccessLogs_592319(path: JsonNode; query: JsonNode;
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
  var valid_592321 = path.getOrDefault("appId")
  valid_592321 = validateParameter(valid_592321, JString, required = true,
                                 default = nil)
  if valid_592321 != nil:
    section.add "appId", valid_592321
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
  var valid_592322 = header.getOrDefault("X-Amz-Signature")
  valid_592322 = validateParameter(valid_592322, JString, required = false,
                                 default = nil)
  if valid_592322 != nil:
    section.add "X-Amz-Signature", valid_592322
  var valid_592323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592323 = validateParameter(valid_592323, JString, required = false,
                                 default = nil)
  if valid_592323 != nil:
    section.add "X-Amz-Content-Sha256", valid_592323
  var valid_592324 = header.getOrDefault("X-Amz-Date")
  valid_592324 = validateParameter(valid_592324, JString, required = false,
                                 default = nil)
  if valid_592324 != nil:
    section.add "X-Amz-Date", valid_592324
  var valid_592325 = header.getOrDefault("X-Amz-Credential")
  valid_592325 = validateParameter(valid_592325, JString, required = false,
                                 default = nil)
  if valid_592325 != nil:
    section.add "X-Amz-Credential", valid_592325
  var valid_592326 = header.getOrDefault("X-Amz-Security-Token")
  valid_592326 = validateParameter(valid_592326, JString, required = false,
                                 default = nil)
  if valid_592326 != nil:
    section.add "X-Amz-Security-Token", valid_592326
  var valid_592327 = header.getOrDefault("X-Amz-Algorithm")
  valid_592327 = validateParameter(valid_592327, JString, required = false,
                                 default = nil)
  if valid_592327 != nil:
    section.add "X-Amz-Algorithm", valid_592327
  var valid_592328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592328 = validateParameter(valid_592328, JString, required = false,
                                 default = nil)
  if valid_592328 != nil:
    section.add "X-Amz-SignedHeaders", valid_592328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592330: Call_GenerateAccessLogs_592318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  let valid = call_592330.validator(path, query, header, formData, body)
  let scheme = call_592330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592330.url(scheme.get, call_592330.host, call_592330.base,
                         call_592330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592330, url, valid)

proc call*(call_592331: Call_GenerateAccessLogs_592318; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592332 = newJObject()
  var body_592333 = newJObject()
  add(path_592332, "appId", newJString(appId))
  if body != nil:
    body_592333 = body
  result = call_592331.call(path_592332, nil, nil, nil, body_592333)

var generateAccessLogs* = Call_GenerateAccessLogs_592318(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_592319, base: "/",
    url: url_GenerateAccessLogs_592320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_592334 = ref object of OpenApiRestCall_591364
proc url_GetArtifactUrl_592336(protocol: Scheme; host: string; base: string;
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

proc validate_GetArtifactUrl_592335(path: JsonNode; query: JsonNode;
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
  var valid_592337 = path.getOrDefault("artifactId")
  valid_592337 = validateParameter(valid_592337, JString, required = true,
                                 default = nil)
  if valid_592337 != nil:
    section.add "artifactId", valid_592337
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
  var valid_592338 = header.getOrDefault("X-Amz-Signature")
  valid_592338 = validateParameter(valid_592338, JString, required = false,
                                 default = nil)
  if valid_592338 != nil:
    section.add "X-Amz-Signature", valid_592338
  var valid_592339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592339 = validateParameter(valid_592339, JString, required = false,
                                 default = nil)
  if valid_592339 != nil:
    section.add "X-Amz-Content-Sha256", valid_592339
  var valid_592340 = header.getOrDefault("X-Amz-Date")
  valid_592340 = validateParameter(valid_592340, JString, required = false,
                                 default = nil)
  if valid_592340 != nil:
    section.add "X-Amz-Date", valid_592340
  var valid_592341 = header.getOrDefault("X-Amz-Credential")
  valid_592341 = validateParameter(valid_592341, JString, required = false,
                                 default = nil)
  if valid_592341 != nil:
    section.add "X-Amz-Credential", valid_592341
  var valid_592342 = header.getOrDefault("X-Amz-Security-Token")
  valid_592342 = validateParameter(valid_592342, JString, required = false,
                                 default = nil)
  if valid_592342 != nil:
    section.add "X-Amz-Security-Token", valid_592342
  var valid_592343 = header.getOrDefault("X-Amz-Algorithm")
  valid_592343 = validateParameter(valid_592343, JString, required = false,
                                 default = nil)
  if valid_592343 != nil:
    section.add "X-Amz-Algorithm", valid_592343
  var valid_592344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592344 = validateParameter(valid_592344, JString, required = false,
                                 default = nil)
  if valid_592344 != nil:
    section.add "X-Amz-SignedHeaders", valid_592344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592345: Call_GetArtifactUrl_592334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_592345.validator(path, query, header, formData, body)
  let scheme = call_592345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592345.url(scheme.get, call_592345.host, call_592345.base,
                         call_592345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592345, url, valid)

proc call*(call_592346: Call_GetArtifactUrl_592334; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_592347 = newJObject()
  add(path_592347, "artifactId", newJString(artifactId))
  result = call_592346.call(path_592347, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_592334(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_592335,
    base: "/", url: url_GetArtifactUrl_592336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_592348 = ref object of OpenApiRestCall_591364
proc url_ListArtifacts_592350(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_592349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592351 = path.getOrDefault("jobId")
  valid_592351 = validateParameter(valid_592351, JString, required = true,
                                 default = nil)
  if valid_592351 != nil:
    section.add "jobId", valid_592351
  var valid_592352 = path.getOrDefault("branchName")
  valid_592352 = validateParameter(valid_592352, JString, required = true,
                                 default = nil)
  if valid_592352 != nil:
    section.add "branchName", valid_592352
  var valid_592353 = path.getOrDefault("appId")
  valid_592353 = validateParameter(valid_592353, JString, required = true,
                                 default = nil)
  if valid_592353 != nil:
    section.add "appId", valid_592353
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_592354 = query.getOrDefault("nextToken")
  valid_592354 = validateParameter(valid_592354, JString, required = false,
                                 default = nil)
  if valid_592354 != nil:
    section.add "nextToken", valid_592354
  var valid_592355 = query.getOrDefault("maxResults")
  valid_592355 = validateParameter(valid_592355, JInt, required = false, default = nil)
  if valid_592355 != nil:
    section.add "maxResults", valid_592355
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
  var valid_592356 = header.getOrDefault("X-Amz-Signature")
  valid_592356 = validateParameter(valid_592356, JString, required = false,
                                 default = nil)
  if valid_592356 != nil:
    section.add "X-Amz-Signature", valid_592356
  var valid_592357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592357 = validateParameter(valid_592357, JString, required = false,
                                 default = nil)
  if valid_592357 != nil:
    section.add "X-Amz-Content-Sha256", valid_592357
  var valid_592358 = header.getOrDefault("X-Amz-Date")
  valid_592358 = validateParameter(valid_592358, JString, required = false,
                                 default = nil)
  if valid_592358 != nil:
    section.add "X-Amz-Date", valid_592358
  var valid_592359 = header.getOrDefault("X-Amz-Credential")
  valid_592359 = validateParameter(valid_592359, JString, required = false,
                                 default = nil)
  if valid_592359 != nil:
    section.add "X-Amz-Credential", valid_592359
  var valid_592360 = header.getOrDefault("X-Amz-Security-Token")
  valid_592360 = validateParameter(valid_592360, JString, required = false,
                                 default = nil)
  if valid_592360 != nil:
    section.add "X-Amz-Security-Token", valid_592360
  var valid_592361 = header.getOrDefault("X-Amz-Algorithm")
  valid_592361 = validateParameter(valid_592361, JString, required = false,
                                 default = nil)
  if valid_592361 != nil:
    section.add "X-Amz-Algorithm", valid_592361
  var valid_592362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592362 = validateParameter(valid_592362, JString, required = false,
                                 default = nil)
  if valid_592362 != nil:
    section.add "X-Amz-SignedHeaders", valid_592362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592363: Call_ListArtifacts_592348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_592363.validator(path, query, header, formData, body)
  let scheme = call_592363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592363.url(scheme.get, call_592363.host, call_592363.base,
                         call_592363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592363, url, valid)

proc call*(call_592364: Call_ListArtifacts_592348; jobId: string; branchName: string;
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
  var path_592365 = newJObject()
  var query_592366 = newJObject()
  add(query_592366, "nextToken", newJString(nextToken))
  add(path_592365, "jobId", newJString(jobId))
  add(path_592365, "branchName", newJString(branchName))
  add(path_592365, "appId", newJString(appId))
  add(query_592366, "maxResults", newJInt(maxResults))
  result = call_592364.call(path_592365, query_592366, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_592348(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_592349, base: "/", url: url_ListArtifacts_592350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_592385 = ref object of OpenApiRestCall_591364
proc url_StartJob_592387(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartJob_592386(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592388 = path.getOrDefault("branchName")
  valid_592388 = validateParameter(valid_592388, JString, required = true,
                                 default = nil)
  if valid_592388 != nil:
    section.add "branchName", valid_592388
  var valid_592389 = path.getOrDefault("appId")
  valid_592389 = validateParameter(valid_592389, JString, required = true,
                                 default = nil)
  if valid_592389 != nil:
    section.add "appId", valid_592389
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
  var valid_592390 = header.getOrDefault("X-Amz-Signature")
  valid_592390 = validateParameter(valid_592390, JString, required = false,
                                 default = nil)
  if valid_592390 != nil:
    section.add "X-Amz-Signature", valid_592390
  var valid_592391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592391 = validateParameter(valid_592391, JString, required = false,
                                 default = nil)
  if valid_592391 != nil:
    section.add "X-Amz-Content-Sha256", valid_592391
  var valid_592392 = header.getOrDefault("X-Amz-Date")
  valid_592392 = validateParameter(valid_592392, JString, required = false,
                                 default = nil)
  if valid_592392 != nil:
    section.add "X-Amz-Date", valid_592392
  var valid_592393 = header.getOrDefault("X-Amz-Credential")
  valid_592393 = validateParameter(valid_592393, JString, required = false,
                                 default = nil)
  if valid_592393 != nil:
    section.add "X-Amz-Credential", valid_592393
  var valid_592394 = header.getOrDefault("X-Amz-Security-Token")
  valid_592394 = validateParameter(valid_592394, JString, required = false,
                                 default = nil)
  if valid_592394 != nil:
    section.add "X-Amz-Security-Token", valid_592394
  var valid_592395 = header.getOrDefault("X-Amz-Algorithm")
  valid_592395 = validateParameter(valid_592395, JString, required = false,
                                 default = nil)
  if valid_592395 != nil:
    section.add "X-Amz-Algorithm", valid_592395
  var valid_592396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592396 = validateParameter(valid_592396, JString, required = false,
                                 default = nil)
  if valid_592396 != nil:
    section.add "X-Amz-SignedHeaders", valid_592396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592398: Call_StartJob_592385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_592398.validator(path, query, header, formData, body)
  let scheme = call_592398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592398.url(scheme.get, call_592398.host, call_592398.base,
                         call_592398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592398, url, valid)

proc call*(call_592399: Call_StartJob_592385; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592400 = newJObject()
  var body_592401 = newJObject()
  add(path_592400, "branchName", newJString(branchName))
  add(path_592400, "appId", newJString(appId))
  if body != nil:
    body_592401 = body
  result = call_592399.call(path_592400, nil, nil, nil, body_592401)

var startJob* = Call_StartJob_592385(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_592386, base: "/",
                                  url: url_StartJob_592387,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_592367 = ref object of OpenApiRestCall_591364
proc url_ListJobs_592369(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_592368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592370 = path.getOrDefault("branchName")
  valid_592370 = validateParameter(valid_592370, JString, required = true,
                                 default = nil)
  if valid_592370 != nil:
    section.add "branchName", valid_592370
  var valid_592371 = path.getOrDefault("appId")
  valid_592371 = validateParameter(valid_592371, JString, required = true,
                                 default = nil)
  if valid_592371 != nil:
    section.add "appId", valid_592371
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_592372 = query.getOrDefault("nextToken")
  valid_592372 = validateParameter(valid_592372, JString, required = false,
                                 default = nil)
  if valid_592372 != nil:
    section.add "nextToken", valid_592372
  var valid_592373 = query.getOrDefault("maxResults")
  valid_592373 = validateParameter(valid_592373, JInt, required = false, default = nil)
  if valid_592373 != nil:
    section.add "maxResults", valid_592373
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
  var valid_592374 = header.getOrDefault("X-Amz-Signature")
  valid_592374 = validateParameter(valid_592374, JString, required = false,
                                 default = nil)
  if valid_592374 != nil:
    section.add "X-Amz-Signature", valid_592374
  var valid_592375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592375 = validateParameter(valid_592375, JString, required = false,
                                 default = nil)
  if valid_592375 != nil:
    section.add "X-Amz-Content-Sha256", valid_592375
  var valid_592376 = header.getOrDefault("X-Amz-Date")
  valid_592376 = validateParameter(valid_592376, JString, required = false,
                                 default = nil)
  if valid_592376 != nil:
    section.add "X-Amz-Date", valid_592376
  var valid_592377 = header.getOrDefault("X-Amz-Credential")
  valid_592377 = validateParameter(valid_592377, JString, required = false,
                                 default = nil)
  if valid_592377 != nil:
    section.add "X-Amz-Credential", valid_592377
  var valid_592378 = header.getOrDefault("X-Amz-Security-Token")
  valid_592378 = validateParameter(valid_592378, JString, required = false,
                                 default = nil)
  if valid_592378 != nil:
    section.add "X-Amz-Security-Token", valid_592378
  var valid_592379 = header.getOrDefault("X-Amz-Algorithm")
  valid_592379 = validateParameter(valid_592379, JString, required = false,
                                 default = nil)
  if valid_592379 != nil:
    section.add "X-Amz-Algorithm", valid_592379
  var valid_592380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592380 = validateParameter(valid_592380, JString, required = false,
                                 default = nil)
  if valid_592380 != nil:
    section.add "X-Amz-SignedHeaders", valid_592380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592381: Call_ListJobs_592367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_592381.validator(path, query, header, formData, body)
  let scheme = call_592381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592381.url(scheme.get, call_592381.host, call_592381.base,
                         call_592381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592381, url, valid)

proc call*(call_592382: Call_ListJobs_592367; branchName: string; appId: string;
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
  var path_592383 = newJObject()
  var query_592384 = newJObject()
  add(query_592384, "nextToken", newJString(nextToken))
  add(path_592383, "branchName", newJString(branchName))
  add(path_592383, "appId", newJString(appId))
  add(query_592384, "maxResults", newJInt(maxResults))
  result = call_592382.call(path_592383, query_592384, nil, nil, nil)

var listJobs* = Call_ListJobs_592367(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_592368, base: "/",
                                  url: url_ListJobs_592369,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592416 = ref object of OpenApiRestCall_591364
proc url_TagResource_592418(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_592417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592419 = path.getOrDefault("resourceArn")
  valid_592419 = validateParameter(valid_592419, JString, required = true,
                                 default = nil)
  if valid_592419 != nil:
    section.add "resourceArn", valid_592419
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
  var valid_592420 = header.getOrDefault("X-Amz-Signature")
  valid_592420 = validateParameter(valid_592420, JString, required = false,
                                 default = nil)
  if valid_592420 != nil:
    section.add "X-Amz-Signature", valid_592420
  var valid_592421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592421 = validateParameter(valid_592421, JString, required = false,
                                 default = nil)
  if valid_592421 != nil:
    section.add "X-Amz-Content-Sha256", valid_592421
  var valid_592422 = header.getOrDefault("X-Amz-Date")
  valid_592422 = validateParameter(valid_592422, JString, required = false,
                                 default = nil)
  if valid_592422 != nil:
    section.add "X-Amz-Date", valid_592422
  var valid_592423 = header.getOrDefault("X-Amz-Credential")
  valid_592423 = validateParameter(valid_592423, JString, required = false,
                                 default = nil)
  if valid_592423 != nil:
    section.add "X-Amz-Credential", valid_592423
  var valid_592424 = header.getOrDefault("X-Amz-Security-Token")
  valid_592424 = validateParameter(valid_592424, JString, required = false,
                                 default = nil)
  if valid_592424 != nil:
    section.add "X-Amz-Security-Token", valid_592424
  var valid_592425 = header.getOrDefault("X-Amz-Algorithm")
  valid_592425 = validateParameter(valid_592425, JString, required = false,
                                 default = nil)
  if valid_592425 != nil:
    section.add "X-Amz-Algorithm", valid_592425
  var valid_592426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592426 = validateParameter(valid_592426, JString, required = false,
                                 default = nil)
  if valid_592426 != nil:
    section.add "X-Amz-SignedHeaders", valid_592426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592428: Call_TagResource_592416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_592428.validator(path, query, header, formData, body)
  let scheme = call_592428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592428.url(scheme.get, call_592428.host, call_592428.base,
                         call_592428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592428, url, valid)

proc call*(call_592429: Call_TagResource_592416; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  ##   body: JObject (required)
  var path_592430 = newJObject()
  var body_592431 = newJObject()
  add(path_592430, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_592431 = body
  result = call_592429.call(path_592430, nil, nil, nil, body_592431)

var tagResource* = Call_TagResource_592416(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_592417,
                                        base: "/", url: url_TagResource_592418,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592402 = ref object of OpenApiRestCall_591364
proc url_ListTagsForResource_592404(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_592403(path: JsonNode; query: JsonNode;
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
  var valid_592405 = path.getOrDefault("resourceArn")
  valid_592405 = validateParameter(valid_592405, JString, required = true,
                                 default = nil)
  if valid_592405 != nil:
    section.add "resourceArn", valid_592405
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
  var valid_592406 = header.getOrDefault("X-Amz-Signature")
  valid_592406 = validateParameter(valid_592406, JString, required = false,
                                 default = nil)
  if valid_592406 != nil:
    section.add "X-Amz-Signature", valid_592406
  var valid_592407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592407 = validateParameter(valid_592407, JString, required = false,
                                 default = nil)
  if valid_592407 != nil:
    section.add "X-Amz-Content-Sha256", valid_592407
  var valid_592408 = header.getOrDefault("X-Amz-Date")
  valid_592408 = validateParameter(valid_592408, JString, required = false,
                                 default = nil)
  if valid_592408 != nil:
    section.add "X-Amz-Date", valid_592408
  var valid_592409 = header.getOrDefault("X-Amz-Credential")
  valid_592409 = validateParameter(valid_592409, JString, required = false,
                                 default = nil)
  if valid_592409 != nil:
    section.add "X-Amz-Credential", valid_592409
  var valid_592410 = header.getOrDefault("X-Amz-Security-Token")
  valid_592410 = validateParameter(valid_592410, JString, required = false,
                                 default = nil)
  if valid_592410 != nil:
    section.add "X-Amz-Security-Token", valid_592410
  var valid_592411 = header.getOrDefault("X-Amz-Algorithm")
  valid_592411 = validateParameter(valid_592411, JString, required = false,
                                 default = nil)
  if valid_592411 != nil:
    section.add "X-Amz-Algorithm", valid_592411
  var valid_592412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592412 = validateParameter(valid_592412, JString, required = false,
                                 default = nil)
  if valid_592412 != nil:
    section.add "X-Amz-SignedHeaders", valid_592412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592413: Call_ListTagsForResource_592402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_592413.validator(path, query, header, formData, body)
  let scheme = call_592413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592413.url(scheme.get, call_592413.host, call_592413.base,
                         call_592413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592413, url, valid)

proc call*(call_592414: Call_ListTagsForResource_592402; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_592415 = newJObject()
  add(path_592415, "resourceArn", newJString(resourceArn))
  result = call_592414.call(path_592415, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_592402(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_592403, base: "/",
    url: url_ListTagsForResource_592404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_592432 = ref object of OpenApiRestCall_591364
proc url_StartDeployment_592434(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_592433(path: JsonNode; query: JsonNode;
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
  var valid_592435 = path.getOrDefault("branchName")
  valid_592435 = validateParameter(valid_592435, JString, required = true,
                                 default = nil)
  if valid_592435 != nil:
    section.add "branchName", valid_592435
  var valid_592436 = path.getOrDefault("appId")
  valid_592436 = validateParameter(valid_592436, JString, required = true,
                                 default = nil)
  if valid_592436 != nil:
    section.add "appId", valid_592436
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
  var valid_592437 = header.getOrDefault("X-Amz-Signature")
  valid_592437 = validateParameter(valid_592437, JString, required = false,
                                 default = nil)
  if valid_592437 != nil:
    section.add "X-Amz-Signature", valid_592437
  var valid_592438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592438 = validateParameter(valid_592438, JString, required = false,
                                 default = nil)
  if valid_592438 != nil:
    section.add "X-Amz-Content-Sha256", valid_592438
  var valid_592439 = header.getOrDefault("X-Amz-Date")
  valid_592439 = validateParameter(valid_592439, JString, required = false,
                                 default = nil)
  if valid_592439 != nil:
    section.add "X-Amz-Date", valid_592439
  var valid_592440 = header.getOrDefault("X-Amz-Credential")
  valid_592440 = validateParameter(valid_592440, JString, required = false,
                                 default = nil)
  if valid_592440 != nil:
    section.add "X-Amz-Credential", valid_592440
  var valid_592441 = header.getOrDefault("X-Amz-Security-Token")
  valid_592441 = validateParameter(valid_592441, JString, required = false,
                                 default = nil)
  if valid_592441 != nil:
    section.add "X-Amz-Security-Token", valid_592441
  var valid_592442 = header.getOrDefault("X-Amz-Algorithm")
  valid_592442 = validateParameter(valid_592442, JString, required = false,
                                 default = nil)
  if valid_592442 != nil:
    section.add "X-Amz-Algorithm", valid_592442
  var valid_592443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592443 = validateParameter(valid_592443, JString, required = false,
                                 default = nil)
  if valid_592443 != nil:
    section.add "X-Amz-SignedHeaders", valid_592443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592445: Call_StartDeployment_592432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_592445.validator(path, query, header, formData, body)
  let scheme = call_592445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592445.url(scheme.get, call_592445.host, call_592445.base,
                         call_592445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592445, url, valid)

proc call*(call_592446: Call_StartDeployment_592432; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_592447 = newJObject()
  var body_592448 = newJObject()
  add(path_592447, "branchName", newJString(branchName))
  add(path_592447, "appId", newJString(appId))
  if body != nil:
    body_592448 = body
  result = call_592446.call(path_592447, nil, nil, nil, body_592448)

var startDeployment* = Call_StartDeployment_592432(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_592433, base: "/", url: url_StartDeployment_592434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_592449 = ref object of OpenApiRestCall_591364
proc url_StopJob_592451(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_592450(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592452 = path.getOrDefault("jobId")
  valid_592452 = validateParameter(valid_592452, JString, required = true,
                                 default = nil)
  if valid_592452 != nil:
    section.add "jobId", valid_592452
  var valid_592453 = path.getOrDefault("branchName")
  valid_592453 = validateParameter(valid_592453, JString, required = true,
                                 default = nil)
  if valid_592453 != nil:
    section.add "branchName", valid_592453
  var valid_592454 = path.getOrDefault("appId")
  valid_592454 = validateParameter(valid_592454, JString, required = true,
                                 default = nil)
  if valid_592454 != nil:
    section.add "appId", valid_592454
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
  var valid_592455 = header.getOrDefault("X-Amz-Signature")
  valid_592455 = validateParameter(valid_592455, JString, required = false,
                                 default = nil)
  if valid_592455 != nil:
    section.add "X-Amz-Signature", valid_592455
  var valid_592456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592456 = validateParameter(valid_592456, JString, required = false,
                                 default = nil)
  if valid_592456 != nil:
    section.add "X-Amz-Content-Sha256", valid_592456
  var valid_592457 = header.getOrDefault("X-Amz-Date")
  valid_592457 = validateParameter(valid_592457, JString, required = false,
                                 default = nil)
  if valid_592457 != nil:
    section.add "X-Amz-Date", valid_592457
  var valid_592458 = header.getOrDefault("X-Amz-Credential")
  valid_592458 = validateParameter(valid_592458, JString, required = false,
                                 default = nil)
  if valid_592458 != nil:
    section.add "X-Amz-Credential", valid_592458
  var valid_592459 = header.getOrDefault("X-Amz-Security-Token")
  valid_592459 = validateParameter(valid_592459, JString, required = false,
                                 default = nil)
  if valid_592459 != nil:
    section.add "X-Amz-Security-Token", valid_592459
  var valid_592460 = header.getOrDefault("X-Amz-Algorithm")
  valid_592460 = validateParameter(valid_592460, JString, required = false,
                                 default = nil)
  if valid_592460 != nil:
    section.add "X-Amz-Algorithm", valid_592460
  var valid_592461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592461 = validateParameter(valid_592461, JString, required = false,
                                 default = nil)
  if valid_592461 != nil:
    section.add "X-Amz-SignedHeaders", valid_592461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592462: Call_StopJob_592449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_592462.validator(path, query, header, formData, body)
  let scheme = call_592462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592462.url(scheme.get, call_592462.host, call_592462.base,
                         call_592462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592462, url, valid)

proc call*(call_592463: Call_StopJob_592449; jobId: string; branchName: string;
          appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_592464 = newJObject()
  add(path_592464, "jobId", newJString(jobId))
  add(path_592464, "branchName", newJString(branchName))
  add(path_592464, "appId", newJString(appId))
  result = call_592463.call(path_592464, nil, nil, nil, nil)

var stopJob* = Call_StopJob_592449(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_592450, base: "/",
                                url: url_StopJob_592451,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592465 = ref object of OpenApiRestCall_591364
proc url_UntagResource_592467(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_592466(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592468 = path.getOrDefault("resourceArn")
  valid_592468 = validateParameter(valid_592468, JString, required = true,
                                 default = nil)
  if valid_592468 != nil:
    section.add "resourceArn", valid_592468
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_592469 = query.getOrDefault("tagKeys")
  valid_592469 = validateParameter(valid_592469, JArray, required = true, default = nil)
  if valid_592469 != nil:
    section.add "tagKeys", valid_592469
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
  var valid_592470 = header.getOrDefault("X-Amz-Signature")
  valid_592470 = validateParameter(valid_592470, JString, required = false,
                                 default = nil)
  if valid_592470 != nil:
    section.add "X-Amz-Signature", valid_592470
  var valid_592471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592471 = validateParameter(valid_592471, JString, required = false,
                                 default = nil)
  if valid_592471 != nil:
    section.add "X-Amz-Content-Sha256", valid_592471
  var valid_592472 = header.getOrDefault("X-Amz-Date")
  valid_592472 = validateParameter(valid_592472, JString, required = false,
                                 default = nil)
  if valid_592472 != nil:
    section.add "X-Amz-Date", valid_592472
  var valid_592473 = header.getOrDefault("X-Amz-Credential")
  valid_592473 = validateParameter(valid_592473, JString, required = false,
                                 default = nil)
  if valid_592473 != nil:
    section.add "X-Amz-Credential", valid_592473
  var valid_592474 = header.getOrDefault("X-Amz-Security-Token")
  valid_592474 = validateParameter(valid_592474, JString, required = false,
                                 default = nil)
  if valid_592474 != nil:
    section.add "X-Amz-Security-Token", valid_592474
  var valid_592475 = header.getOrDefault("X-Amz-Algorithm")
  valid_592475 = validateParameter(valid_592475, JString, required = false,
                                 default = nil)
  if valid_592475 != nil:
    section.add "X-Amz-Algorithm", valid_592475
  var valid_592476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592476 = validateParameter(valid_592476, JString, required = false,
                                 default = nil)
  if valid_592476 != nil:
    section.add "X-Amz-SignedHeaders", valid_592476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592477: Call_UntagResource_592465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_592477.validator(path, query, header, formData, body)
  let scheme = call_592477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592477.url(scheme.get, call_592477.host, call_592477.base,
                         call_592477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592477, url, valid)

proc call*(call_592478: Call_UntagResource_592465; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  var path_592479 = newJObject()
  var query_592480 = newJObject()
  add(path_592479, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_592480.add "tagKeys", tagKeys
  result = call_592478.call(path_592479, query_592480, nil, nil, nil)

var untagResource* = Call_UntagResource_592465(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_592466,
    base: "/", url: url_UntagResource_592467, schemes: {Scheme.Https, Scheme.Http})
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
