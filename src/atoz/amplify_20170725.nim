
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
  Call_CreateApp_592960 = ref object of OpenApiRestCall_592364
proc url_CreateApp_592962(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_592961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592963 = header.getOrDefault("X-Amz-Signature")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Signature", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Content-Sha256", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Date")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Date", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Credential")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Credential", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Security-Token")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Security-Token", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Algorithm")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Algorithm", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-SignedHeaders", valid_592969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_CreateApp_592960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_CreateApp_592960; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var createApp* = Call_CreateApp_592960(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_592961,
                                    base: "/", url: url_CreateApp_592962,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_592703 = ref object of OpenApiRestCall_592364
proc url_ListApps_592705(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApps_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("maxResults")
  valid_592818 = validateParameter(valid_592818, JInt, required = false, default = nil)
  if valid_592818 != nil:
    section.add "maxResults", valid_592818
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
  var valid_592819 = header.getOrDefault("X-Amz-Signature")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Signature", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Content-Sha256", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Date")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Date", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Credential")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Credential", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Security-Token")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Security-Token", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Algorithm")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Algorithm", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-SignedHeaders", valid_592825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592848: Call_ListApps_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_592848.validator(path, query, header, formData, body)
  let scheme = call_592848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592848.url(scheme.get, call_592848.host, call_592848.base,
                         call_592848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592848, url, valid)

proc call*(call_592919: Call_ListApps_592703; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_592920 = newJObject()
  add(query_592920, "nextToken", newJString(nextToken))
  add(query_592920, "maxResults", newJInt(maxResults))
  result = call_592919.call(nil, query_592920, nil, nil, nil)

var listApps* = Call_ListApps_592703(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_592704, base: "/",
                                  url: url_ListApps_592705,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_593005 = ref object of OpenApiRestCall_592364
proc url_CreateBranch_593007(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBranch_593006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593008 = path.getOrDefault("appId")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = nil)
  if valid_593008 != nil:
    section.add "appId", valid_593008
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
  var valid_593009 = header.getOrDefault("X-Amz-Signature")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Signature", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Content-Sha256", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Date")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Date", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Credential")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Credential", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Security-Token")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Security-Token", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Algorithm")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Algorithm", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-SignedHeaders", valid_593015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_CreateBranch_593005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_CreateBranch_593005; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593019 = newJObject()
  var body_593020 = newJObject()
  add(path_593019, "appId", newJString(appId))
  if body != nil:
    body_593020 = body
  result = call_593018.call(path_593019, nil, nil, nil, body_593020)

var createBranch* = Call_CreateBranch_593005(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_593006,
    base: "/", url: url_CreateBranch_593007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_592974 = ref object of OpenApiRestCall_592364
proc url_ListBranches_592976(protocol: Scheme; host: string; base: string;
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

proc validate_ListBranches_592975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592991 = path.getOrDefault("appId")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "appId", valid_592991
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_592992 = query.getOrDefault("nextToken")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "nextToken", valid_592992
  var valid_592993 = query.getOrDefault("maxResults")
  valid_592993 = validateParameter(valid_592993, JInt, required = false, default = nil)
  if valid_592993 != nil:
    section.add "maxResults", valid_592993
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
  var valid_592994 = header.getOrDefault("X-Amz-Signature")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Signature", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Content-Sha256", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Date")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Date", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Credential")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Credential", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Security-Token")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Security-Token", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Algorithm")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Algorithm", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-SignedHeaders", valid_593000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593001: Call_ListBranches_592974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_593001.validator(path, query, header, formData, body)
  let scheme = call_593001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593001.url(scheme.get, call_593001.host, call_593001.base,
                         call_593001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593001, url, valid)

proc call*(call_593002: Call_ListBranches_592974; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_593003 = newJObject()
  var query_593004 = newJObject()
  add(query_593004, "nextToken", newJString(nextToken))
  add(path_593003, "appId", newJString(appId))
  add(query_593004, "maxResults", newJInt(maxResults))
  result = call_593002.call(path_593003, query_593004, nil, nil, nil)

var listBranches* = Call_ListBranches_592974(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_592975,
    base: "/", url: url_ListBranches_592976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_593021 = ref object of OpenApiRestCall_592364
proc url_CreateDeployment_593023(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_593022(path: JsonNode; query: JsonNode;
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
  var valid_593024 = path.getOrDefault("branchName")
  valid_593024 = validateParameter(valid_593024, JString, required = true,
                                 default = nil)
  if valid_593024 != nil:
    section.add "branchName", valid_593024
  var valid_593025 = path.getOrDefault("appId")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = nil)
  if valid_593025 != nil:
    section.add "appId", valid_593025
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
  var valid_593026 = header.getOrDefault("X-Amz-Signature")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Signature", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Content-Sha256", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Date")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Date", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Credential")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Credential", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Security-Token")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Security-Token", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Algorithm")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Algorithm", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-SignedHeaders", valid_593032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593034: Call_CreateDeployment_593021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_593034.validator(path, query, header, formData, body)
  let scheme = call_593034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593034.url(scheme.get, call_593034.host, call_593034.base,
                         call_593034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593034, url, valid)

proc call*(call_593035: Call_CreateDeployment_593021; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593036 = newJObject()
  var body_593037 = newJObject()
  add(path_593036, "branchName", newJString(branchName))
  add(path_593036, "appId", newJString(appId))
  if body != nil:
    body_593037 = body
  result = call_593035.call(path_593036, nil, nil, nil, body_593037)

var createDeployment* = Call_CreateDeployment_593021(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_593022, base: "/",
    url: url_CreateDeployment_593023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_593055 = ref object of OpenApiRestCall_592364
proc url_CreateDomainAssociation_593057(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainAssociation_593056(path: JsonNode; query: JsonNode;
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
  var valid_593058 = path.getOrDefault("appId")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "appId", valid_593058
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
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_CreateDomainAssociation_593055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_CreateDomainAssociation_593055; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593069 = newJObject()
  var body_593070 = newJObject()
  add(path_593069, "appId", newJString(appId))
  if body != nil:
    body_593070 = body
  result = call_593068.call(path_593069, nil, nil, nil, body_593070)

var createDomainAssociation* = Call_CreateDomainAssociation_593055(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_593056, base: "/",
    url: url_CreateDomainAssociation_593057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_593038 = ref object of OpenApiRestCall_592364
proc url_ListDomainAssociations_593040(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomainAssociations_593039(path: JsonNode; query: JsonNode;
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
  var valid_593041 = path.getOrDefault("appId")
  valid_593041 = validateParameter(valid_593041, JString, required = true,
                                 default = nil)
  if valid_593041 != nil:
    section.add "appId", valid_593041
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_593042 = query.getOrDefault("nextToken")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "nextToken", valid_593042
  var valid_593043 = query.getOrDefault("maxResults")
  valid_593043 = validateParameter(valid_593043, JInt, required = false, default = nil)
  if valid_593043 != nil:
    section.add "maxResults", valid_593043
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
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593051: Call_ListDomainAssociations_593038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_593051.validator(path, query, header, formData, body)
  let scheme = call_593051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593051.url(scheme.get, call_593051.host, call_593051.base,
                         call_593051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593051, url, valid)

proc call*(call_593052: Call_ListDomainAssociations_593038; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_593053 = newJObject()
  var query_593054 = newJObject()
  add(query_593054, "nextToken", newJString(nextToken))
  add(path_593053, "appId", newJString(appId))
  add(query_593054, "maxResults", newJInt(maxResults))
  result = call_593052.call(path_593053, query_593054, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_593038(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_593039, base: "/",
    url: url_ListDomainAssociations_593040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_593088 = ref object of OpenApiRestCall_592364
proc url_CreateWebhook_593090(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_593089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593091 = path.getOrDefault("appId")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = nil)
  if valid_593091 != nil:
    section.add "appId", valid_593091
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
  var valid_593092 = header.getOrDefault("X-Amz-Signature")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Signature", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Content-Sha256", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Date")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Date", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Credential")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Credential", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Security-Token")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Security-Token", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Algorithm")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Algorithm", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-SignedHeaders", valid_593098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593100: Call_CreateWebhook_593088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_593100.validator(path, query, header, formData, body)
  let scheme = call_593100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593100.url(scheme.get, call_593100.host, call_593100.base,
                         call_593100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593100, url, valid)

proc call*(call_593101: Call_CreateWebhook_593088; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593102 = newJObject()
  var body_593103 = newJObject()
  add(path_593102, "appId", newJString(appId))
  if body != nil:
    body_593103 = body
  result = call_593101.call(path_593102, nil, nil, nil, body_593103)

var createWebhook* = Call_CreateWebhook_593088(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_593089,
    base: "/", url: url_CreateWebhook_593090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_593071 = ref object of OpenApiRestCall_592364
proc url_ListWebhooks_593073(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_593072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593074 = path.getOrDefault("appId")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = nil)
  if valid_593074 != nil:
    section.add "appId", valid_593074
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_593075 = query.getOrDefault("nextToken")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "nextToken", valid_593075
  var valid_593076 = query.getOrDefault("maxResults")
  valid_593076 = validateParameter(valid_593076, JInt, required = false, default = nil)
  if valid_593076 != nil:
    section.add "maxResults", valid_593076
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
  var valid_593077 = header.getOrDefault("X-Amz-Signature")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Signature", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Content-Sha256", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Date")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Date", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Credential")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Credential", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593084: Call_ListWebhooks_593071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_593084.validator(path, query, header, formData, body)
  let scheme = call_593084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593084.url(scheme.get, call_593084.host, call_593084.base,
                         call_593084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593084, url, valid)

proc call*(call_593085: Call_ListWebhooks_593071; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_593086 = newJObject()
  var query_593087 = newJObject()
  add(query_593087, "nextToken", newJString(nextToken))
  add(path_593086, "appId", newJString(appId))
  add(query_593087, "maxResults", newJInt(maxResults))
  result = call_593085.call(path_593086, query_593087, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_593071(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_593072,
    base: "/", url: url_ListWebhooks_593073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_593118 = ref object of OpenApiRestCall_592364
proc url_UpdateApp_593120(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_593119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593121 = path.getOrDefault("appId")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "appId", valid_593121
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
  var valid_593122 = header.getOrDefault("X-Amz-Signature")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Signature", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Content-Sha256", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Date")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Date", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Credential")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Credential", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Security-Token")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Security-Token", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Algorithm")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Algorithm", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-SignedHeaders", valid_593128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593130: Call_UpdateApp_593118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_593130.validator(path, query, header, formData, body)
  let scheme = call_593130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593130.url(scheme.get, call_593130.host, call_593130.base,
                         call_593130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593130, url, valid)

proc call*(call_593131: Call_UpdateApp_593118; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593132 = newJObject()
  var body_593133 = newJObject()
  add(path_593132, "appId", newJString(appId))
  if body != nil:
    body_593133 = body
  result = call_593131.call(path_593132, nil, nil, nil, body_593133)

var updateApp* = Call_UpdateApp_593118(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_593119,
                                    base: "/", url: url_UpdateApp_593120,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_593104 = ref object of OpenApiRestCall_592364
proc url_GetApp_593106(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_593105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593107 = path.getOrDefault("appId")
  valid_593107 = validateParameter(valid_593107, JString, required = true,
                                 default = nil)
  if valid_593107 != nil:
    section.add "appId", valid_593107
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
  var valid_593108 = header.getOrDefault("X-Amz-Signature")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Signature", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Content-Sha256", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Date")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Date", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Credential")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Credential", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Security-Token")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Security-Token", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Algorithm")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Algorithm", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-SignedHeaders", valid_593114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593115: Call_GetApp_593104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_593115.validator(path, query, header, formData, body)
  let scheme = call_593115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593115.url(scheme.get, call_593115.host, call_593115.base,
                         call_593115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593115, url, valid)

proc call*(call_593116: Call_GetApp_593104; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593117 = newJObject()
  add(path_593117, "appId", newJString(appId))
  result = call_593116.call(path_593117, nil, nil, nil, nil)

var getApp* = Call_GetApp_593104(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_593105,
                              base: "/", url: url_GetApp_593106,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_593134 = ref object of OpenApiRestCall_592364
proc url_DeleteApp_593136(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_593135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593137 = path.getOrDefault("appId")
  valid_593137 = validateParameter(valid_593137, JString, required = true,
                                 default = nil)
  if valid_593137 != nil:
    section.add "appId", valid_593137
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
  var valid_593138 = header.getOrDefault("X-Amz-Signature")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Signature", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Content-Sha256", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Date")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Date", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Credential")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Credential", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Security-Token")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Security-Token", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Algorithm")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Algorithm", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-SignedHeaders", valid_593144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593145: Call_DeleteApp_593134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_593145.validator(path, query, header, formData, body)
  let scheme = call_593145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593145.url(scheme.get, call_593145.host, call_593145.base,
                         call_593145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593145, url, valid)

proc call*(call_593146: Call_DeleteApp_593134; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593147 = newJObject()
  add(path_593147, "appId", newJString(appId))
  result = call_593146.call(path_593147, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_593134(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_593135,
                                    base: "/", url: url_DeleteApp_593136,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_593163 = ref object of OpenApiRestCall_592364
proc url_UpdateBranch_593165(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBranch_593164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593166 = path.getOrDefault("branchName")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "branchName", valid_593166
  var valid_593167 = path.getOrDefault("appId")
  valid_593167 = validateParameter(valid_593167, JString, required = true,
                                 default = nil)
  if valid_593167 != nil:
    section.add "appId", valid_593167
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
  var valid_593168 = header.getOrDefault("X-Amz-Signature")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Signature", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Content-Sha256", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Date")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Date", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Credential")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Credential", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Security-Token")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Security-Token", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Algorithm")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Algorithm", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-SignedHeaders", valid_593174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593176: Call_UpdateBranch_593163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_593176.validator(path, query, header, formData, body)
  let scheme = call_593176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593176.url(scheme.get, call_593176.host, call_593176.base,
                         call_593176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593176, url, valid)

proc call*(call_593177: Call_UpdateBranch_593163; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593178 = newJObject()
  var body_593179 = newJObject()
  add(path_593178, "branchName", newJString(branchName))
  add(path_593178, "appId", newJString(appId))
  if body != nil:
    body_593179 = body
  result = call_593177.call(path_593178, nil, nil, nil, body_593179)

var updateBranch* = Call_UpdateBranch_593163(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_593164, base: "/", url: url_UpdateBranch_593165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_593148 = ref object of OpenApiRestCall_592364
proc url_GetBranch_593150(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBranch_593149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593151 = path.getOrDefault("branchName")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "branchName", valid_593151
  var valid_593152 = path.getOrDefault("appId")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = nil)
  if valid_593152 != nil:
    section.add "appId", valid_593152
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
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593160: Call_GetBranch_593148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_593160.validator(path, query, header, formData, body)
  let scheme = call_593160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593160.url(scheme.get, call_593160.host, call_593160.base,
                         call_593160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593160, url, valid)

proc call*(call_593161: Call_GetBranch_593148; branchName: string; appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593162 = newJObject()
  add(path_593162, "branchName", newJString(branchName))
  add(path_593162, "appId", newJString(appId))
  result = call_593161.call(path_593162, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_593148(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_593149,
                                    base: "/", url: url_GetBranch_593150,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_593180 = ref object of OpenApiRestCall_592364
proc url_DeleteBranch_593182(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBranch_593181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593183 = path.getOrDefault("branchName")
  valid_593183 = validateParameter(valid_593183, JString, required = true,
                                 default = nil)
  if valid_593183 != nil:
    section.add "branchName", valid_593183
  var valid_593184 = path.getOrDefault("appId")
  valid_593184 = validateParameter(valid_593184, JString, required = true,
                                 default = nil)
  if valid_593184 != nil:
    section.add "appId", valid_593184
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
  var valid_593185 = header.getOrDefault("X-Amz-Signature")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Signature", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Content-Sha256", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Date")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Date", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Credential")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Credential", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Security-Token")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Security-Token", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Algorithm")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Algorithm", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-SignedHeaders", valid_593191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_DeleteBranch_593180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_DeleteBranch_593180; branchName: string; appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593194 = newJObject()
  add(path_593194, "branchName", newJString(branchName))
  add(path_593194, "appId", newJString(appId))
  result = call_593193.call(path_593194, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_593180(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_593181, base: "/", url: url_DeleteBranch_593182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_593210 = ref object of OpenApiRestCall_592364
proc url_UpdateDomainAssociation_593212(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainAssociation_593211(path: JsonNode; query: JsonNode;
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
  var valid_593213 = path.getOrDefault("appId")
  valid_593213 = validateParameter(valid_593213, JString, required = true,
                                 default = nil)
  if valid_593213 != nil:
    section.add "appId", valid_593213
  var valid_593214 = path.getOrDefault("domainName")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = nil)
  if valid_593214 != nil:
    section.add "domainName", valid_593214
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
  var valid_593215 = header.getOrDefault("X-Amz-Signature")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Signature", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Content-Sha256", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Date")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Date", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Credential")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Credential", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Security-Token")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Security-Token", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Algorithm")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Algorithm", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-SignedHeaders", valid_593221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593223: Call_UpdateDomainAssociation_593210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_593223.validator(path, query, header, formData, body)
  let scheme = call_593223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593223.url(scheme.get, call_593223.host, call_593223.base,
                         call_593223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593223, url, valid)

proc call*(call_593224: Call_UpdateDomainAssociation_593210; appId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_593225 = newJObject()
  var body_593226 = newJObject()
  add(path_593225, "appId", newJString(appId))
  if body != nil:
    body_593226 = body
  add(path_593225, "domainName", newJString(domainName))
  result = call_593224.call(path_593225, nil, nil, nil, body_593226)

var updateDomainAssociation* = Call_UpdateDomainAssociation_593210(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_593211, base: "/",
    url: url_UpdateDomainAssociation_593212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_593195 = ref object of OpenApiRestCall_592364
proc url_GetDomainAssociation_593197(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainAssociation_593196(path: JsonNode; query: JsonNode;
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
  var valid_593198 = path.getOrDefault("appId")
  valid_593198 = validateParameter(valid_593198, JString, required = true,
                                 default = nil)
  if valid_593198 != nil:
    section.add "appId", valid_593198
  var valid_593199 = path.getOrDefault("domainName")
  valid_593199 = validateParameter(valid_593199, JString, required = true,
                                 default = nil)
  if valid_593199 != nil:
    section.add "domainName", valid_593199
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
  var valid_593200 = header.getOrDefault("X-Amz-Signature")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Signature", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Content-Sha256", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Date")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Date", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Credential")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Credential", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Security-Token")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Security-Token", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Algorithm")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Algorithm", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-SignedHeaders", valid_593206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_GetDomainAssociation_593195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_GetDomainAssociation_593195; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_593209 = newJObject()
  add(path_593209, "appId", newJString(appId))
  add(path_593209, "domainName", newJString(domainName))
  result = call_593208.call(path_593209, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_593195(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_593196, base: "/",
    url: url_GetDomainAssociation_593197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_593227 = ref object of OpenApiRestCall_592364
proc url_DeleteDomainAssociation_593229(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainAssociation_593228(path: JsonNode; query: JsonNode;
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
  var valid_593230 = path.getOrDefault("appId")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = nil)
  if valid_593230 != nil:
    section.add "appId", valid_593230
  var valid_593231 = path.getOrDefault("domainName")
  valid_593231 = validateParameter(valid_593231, JString, required = true,
                                 default = nil)
  if valid_593231 != nil:
    section.add "domainName", valid_593231
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
  var valid_593232 = header.getOrDefault("X-Amz-Signature")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Signature", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Content-Sha256", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Date")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Date", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Credential")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Credential", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Security-Token")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Security-Token", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Algorithm")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Algorithm", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-SignedHeaders", valid_593238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_DeleteDomainAssociation_593227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_DeleteDomainAssociation_593227; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_593241 = newJObject()
  add(path_593241, "appId", newJString(appId))
  add(path_593241, "domainName", newJString(domainName))
  result = call_593240.call(path_593241, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_593227(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_593228, base: "/",
    url: url_DeleteDomainAssociation_593229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_593242 = ref object of OpenApiRestCall_592364
proc url_GetJob_593244(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_593243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593245 = path.getOrDefault("jobId")
  valid_593245 = validateParameter(valid_593245, JString, required = true,
                                 default = nil)
  if valid_593245 != nil:
    section.add "jobId", valid_593245
  var valid_593246 = path.getOrDefault("branchName")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = nil)
  if valid_593246 != nil:
    section.add "branchName", valid_593246
  var valid_593247 = path.getOrDefault("appId")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = nil)
  if valid_593247 != nil:
    section.add "appId", valid_593247
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
  var valid_593248 = header.getOrDefault("X-Amz-Signature")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Signature", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Content-Sha256", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Date")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Date", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Credential")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Credential", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Security-Token")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Security-Token", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Algorithm")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Algorithm", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-SignedHeaders", valid_593254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593255: Call_GetJob_593242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_593255.validator(path, query, header, formData, body)
  let scheme = call_593255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593255.url(scheme.get, call_593255.host, call_593255.base,
                         call_593255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593255, url, valid)

proc call*(call_593256: Call_GetJob_593242; jobId: string; branchName: string;
          appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593257 = newJObject()
  add(path_593257, "jobId", newJString(jobId))
  add(path_593257, "branchName", newJString(branchName))
  add(path_593257, "appId", newJString(appId))
  result = call_593256.call(path_593257, nil, nil, nil, nil)

var getJob* = Call_GetJob_593242(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_593243, base: "/",
                              url: url_GetJob_593244,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_593258 = ref object of OpenApiRestCall_592364
proc url_DeleteJob_593260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_593259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593261 = path.getOrDefault("jobId")
  valid_593261 = validateParameter(valid_593261, JString, required = true,
                                 default = nil)
  if valid_593261 != nil:
    section.add "jobId", valid_593261
  var valid_593262 = path.getOrDefault("branchName")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = nil)
  if valid_593262 != nil:
    section.add "branchName", valid_593262
  var valid_593263 = path.getOrDefault("appId")
  valid_593263 = validateParameter(valid_593263, JString, required = true,
                                 default = nil)
  if valid_593263 != nil:
    section.add "appId", valid_593263
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
  var valid_593264 = header.getOrDefault("X-Amz-Signature")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Signature", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Content-Sha256", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Date")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Date", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Credential")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Credential", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Security-Token")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Security-Token", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Algorithm")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Algorithm", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-SignedHeaders", valid_593270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593271: Call_DeleteJob_593258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_593271.validator(path, query, header, formData, body)
  let scheme = call_593271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593271.url(scheme.get, call_593271.host, call_593271.base,
                         call_593271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593271, url, valid)

proc call*(call_593272: Call_DeleteJob_593258; jobId: string; branchName: string;
          appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593273 = newJObject()
  add(path_593273, "jobId", newJString(jobId))
  add(path_593273, "branchName", newJString(branchName))
  add(path_593273, "appId", newJString(appId))
  result = call_593272.call(path_593273, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_593258(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_593259,
                                    base: "/", url: url_DeleteJob_593260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_593288 = ref object of OpenApiRestCall_592364
proc url_UpdateWebhook_593290(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_593289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593291 = path.getOrDefault("webhookId")
  valid_593291 = validateParameter(valid_593291, JString, required = true,
                                 default = nil)
  if valid_593291 != nil:
    section.add "webhookId", valid_593291
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
  var valid_593292 = header.getOrDefault("X-Amz-Signature")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Signature", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Content-Sha256", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Date")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Date", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Credential")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Credential", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Security-Token")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Security-Token", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Algorithm")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Algorithm", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-SignedHeaders", valid_593298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593300: Call_UpdateWebhook_593288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_593300.validator(path, query, header, formData, body)
  let scheme = call_593300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593300.url(scheme.get, call_593300.host, call_593300.base,
                         call_593300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593300, url, valid)

proc call*(call_593301: Call_UpdateWebhook_593288; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_593302 = newJObject()
  var body_593303 = newJObject()
  add(path_593302, "webhookId", newJString(webhookId))
  if body != nil:
    body_593303 = body
  result = call_593301.call(path_593302, nil, nil, nil, body_593303)

var updateWebhook* = Call_UpdateWebhook_593288(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_593289,
    base: "/", url: url_UpdateWebhook_593290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_593274 = ref object of OpenApiRestCall_592364
proc url_GetWebhook_593276(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetWebhook_593275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593277 = path.getOrDefault("webhookId")
  valid_593277 = validateParameter(valid_593277, JString, required = true,
                                 default = nil)
  if valid_593277 != nil:
    section.add "webhookId", valid_593277
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
  var valid_593278 = header.getOrDefault("X-Amz-Signature")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Signature", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Content-Sha256", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Date")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Date", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Credential")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Credential", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-Security-Token")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Security-Token", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Algorithm")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Algorithm", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-SignedHeaders", valid_593284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593285: Call_GetWebhook_593274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_593285.validator(path, query, header, formData, body)
  let scheme = call_593285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593285.url(scheme.get, call_593285.host, call_593285.base,
                         call_593285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593285, url, valid)

proc call*(call_593286: Call_GetWebhook_593274; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_593287 = newJObject()
  add(path_593287, "webhookId", newJString(webhookId))
  result = call_593286.call(path_593287, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_593274(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_593275,
                                      base: "/", url: url_GetWebhook_593276,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_593304 = ref object of OpenApiRestCall_592364
proc url_DeleteWebhook_593306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_593305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593307 = path.getOrDefault("webhookId")
  valid_593307 = validateParameter(valid_593307, JString, required = true,
                                 default = nil)
  if valid_593307 != nil:
    section.add "webhookId", valid_593307
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
  var valid_593308 = header.getOrDefault("X-Amz-Signature")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Signature", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Content-Sha256", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Date")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Date", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Credential")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Credential", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Security-Token")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Security-Token", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Algorithm")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Algorithm", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-SignedHeaders", valid_593314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593315: Call_DeleteWebhook_593304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_593315.validator(path, query, header, formData, body)
  let scheme = call_593315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593315.url(scheme.get, call_593315.host, call_593315.base,
                         call_593315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593315, url, valid)

proc call*(call_593316: Call_DeleteWebhook_593304; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_593317 = newJObject()
  add(path_593317, "webhookId", newJString(webhookId))
  result = call_593316.call(path_593317, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_593304(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_593305,
    base: "/", url: url_DeleteWebhook_593306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_593318 = ref object of OpenApiRestCall_592364
proc url_GenerateAccessLogs_593320(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateAccessLogs_593319(path: JsonNode; query: JsonNode;
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
  var valid_593321 = path.getOrDefault("appId")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = nil)
  if valid_593321 != nil:
    section.add "appId", valid_593321
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
  var valid_593322 = header.getOrDefault("X-Amz-Signature")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Signature", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Content-Sha256", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Date")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Date", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Credential")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Credential", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Security-Token")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Security-Token", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Algorithm")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Algorithm", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-SignedHeaders", valid_593328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593330: Call_GenerateAccessLogs_593318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ## 
  let valid = call_593330.validator(path, query, header, formData, body)
  let scheme = call_593330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593330.url(scheme.get, call_593330.host, call_593330.base,
                         call_593330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593330, url, valid)

proc call*(call_593331: Call_GenerateAccessLogs_593318; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593332 = newJObject()
  var body_593333 = newJObject()
  add(path_593332, "appId", newJString(appId))
  if body != nil:
    body_593333 = body
  result = call_593331.call(path_593332, nil, nil, nil, body_593333)

var generateAccessLogs* = Call_GenerateAccessLogs_593318(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_593319, base: "/",
    url: url_GenerateAccessLogs_593320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_593334 = ref object of OpenApiRestCall_592364
proc url_GetArtifactUrl_593336(protocol: Scheme; host: string; base: string;
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

proc validate_GetArtifactUrl_593335(path: JsonNode; query: JsonNode;
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
  var valid_593337 = path.getOrDefault("artifactId")
  valid_593337 = validateParameter(valid_593337, JString, required = true,
                                 default = nil)
  if valid_593337 != nil:
    section.add "artifactId", valid_593337
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
  var valid_593338 = header.getOrDefault("X-Amz-Signature")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Signature", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Content-Sha256", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Date")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Date", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Credential")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Credential", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Security-Token")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Security-Token", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Algorithm")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Algorithm", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-SignedHeaders", valid_593344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593345: Call_GetArtifactUrl_593334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_593345.validator(path, query, header, formData, body)
  let scheme = call_593345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593345.url(scheme.get, call_593345.host, call_593345.base,
                         call_593345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593345, url, valid)

proc call*(call_593346: Call_GetArtifactUrl_593334; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_593347 = newJObject()
  add(path_593347, "artifactId", newJString(artifactId))
  result = call_593346.call(path_593347, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_593334(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_593335,
    base: "/", url: url_GetArtifactUrl_593336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_593348 = ref object of OpenApiRestCall_592364
proc url_ListArtifacts_593350(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_593349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593351 = path.getOrDefault("jobId")
  valid_593351 = validateParameter(valid_593351, JString, required = true,
                                 default = nil)
  if valid_593351 != nil:
    section.add "jobId", valid_593351
  var valid_593352 = path.getOrDefault("branchName")
  valid_593352 = validateParameter(valid_593352, JString, required = true,
                                 default = nil)
  if valid_593352 != nil:
    section.add "branchName", valid_593352
  var valid_593353 = path.getOrDefault("appId")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = nil)
  if valid_593353 != nil:
    section.add "appId", valid_593353
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_593354 = query.getOrDefault("nextToken")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "nextToken", valid_593354
  var valid_593355 = query.getOrDefault("maxResults")
  valid_593355 = validateParameter(valid_593355, JInt, required = false, default = nil)
  if valid_593355 != nil:
    section.add "maxResults", valid_593355
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
  var valid_593356 = header.getOrDefault("X-Amz-Signature")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Signature", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Content-Sha256", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Date")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Date", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Credential")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Credential", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Security-Token")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Security-Token", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Algorithm")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Algorithm", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-SignedHeaders", valid_593362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593364: Call_ListArtifacts_593348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_593364.validator(path, query, header, formData, body)
  let scheme = call_593364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593364.url(scheme.get, call_593364.host, call_593364.base,
                         call_593364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593364, url, valid)

proc call*(call_593365: Call_ListArtifacts_593348; jobId: string; branchName: string;
          appId: string; body: JsonNode; nextToken: string = ""; maxResults: int = 0): Recallable =
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
  ##   body: JObject (required)
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_593366 = newJObject()
  var query_593367 = newJObject()
  var body_593368 = newJObject()
  add(query_593367, "nextToken", newJString(nextToken))
  add(path_593366, "jobId", newJString(jobId))
  add(path_593366, "branchName", newJString(branchName))
  add(path_593366, "appId", newJString(appId))
  if body != nil:
    body_593368 = body
  add(query_593367, "maxResults", newJInt(maxResults))
  result = call_593365.call(path_593366, query_593367, nil, nil, body_593368)

var listArtifacts* = Call_ListArtifacts_593348(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_593349, base: "/", url: url_ListArtifacts_593350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_593387 = ref object of OpenApiRestCall_592364
proc url_StartJob_593389(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartJob_593388(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593390 = path.getOrDefault("branchName")
  valid_593390 = validateParameter(valid_593390, JString, required = true,
                                 default = nil)
  if valid_593390 != nil:
    section.add "branchName", valid_593390
  var valid_593391 = path.getOrDefault("appId")
  valid_593391 = validateParameter(valid_593391, JString, required = true,
                                 default = nil)
  if valid_593391 != nil:
    section.add "appId", valid_593391
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
  var valid_593392 = header.getOrDefault("X-Amz-Signature")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Signature", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Content-Sha256", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Date")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Date", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Credential")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Credential", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Security-Token")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Security-Token", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Algorithm")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Algorithm", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-SignedHeaders", valid_593398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593400: Call_StartJob_593387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_593400.validator(path, query, header, formData, body)
  let scheme = call_593400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593400.url(scheme.get, call_593400.host, call_593400.base,
                         call_593400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593400, url, valid)

proc call*(call_593401: Call_StartJob_593387; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593402 = newJObject()
  var body_593403 = newJObject()
  add(path_593402, "branchName", newJString(branchName))
  add(path_593402, "appId", newJString(appId))
  if body != nil:
    body_593403 = body
  result = call_593401.call(path_593402, nil, nil, nil, body_593403)

var startJob* = Call_StartJob_593387(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_593388, base: "/",
                                  url: url_StartJob_593389,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_593369 = ref object of OpenApiRestCall_592364
proc url_ListJobs_593371(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_593370(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593372 = path.getOrDefault("branchName")
  valid_593372 = validateParameter(valid_593372, JString, required = true,
                                 default = nil)
  if valid_593372 != nil:
    section.add "branchName", valid_593372
  var valid_593373 = path.getOrDefault("appId")
  valid_593373 = validateParameter(valid_593373, JString, required = true,
                                 default = nil)
  if valid_593373 != nil:
    section.add "appId", valid_593373
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_593374 = query.getOrDefault("nextToken")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "nextToken", valid_593374
  var valid_593375 = query.getOrDefault("maxResults")
  valid_593375 = validateParameter(valid_593375, JInt, required = false, default = nil)
  if valid_593375 != nil:
    section.add "maxResults", valid_593375
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
  var valid_593376 = header.getOrDefault("X-Amz-Signature")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Signature", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Content-Sha256", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Date")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Date", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Credential")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Credential", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Security-Token")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Security-Token", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Algorithm")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Algorithm", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-SignedHeaders", valid_593382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593383: Call_ListJobs_593369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_593383.validator(path, query, header, formData, body)
  let scheme = call_593383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593383.url(scheme.get, call_593383.host, call_593383.base,
                         call_593383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593383, url, valid)

proc call*(call_593384: Call_ListJobs_593369; branchName: string; appId: string;
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
  var path_593385 = newJObject()
  var query_593386 = newJObject()
  add(query_593386, "nextToken", newJString(nextToken))
  add(path_593385, "branchName", newJString(branchName))
  add(path_593385, "appId", newJString(appId))
  add(query_593386, "maxResults", newJInt(maxResults))
  result = call_593384.call(path_593385, query_593386, nil, nil, nil)

var listJobs* = Call_ListJobs_593369(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_593370, base: "/",
                                  url: url_ListJobs_593371,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593418 = ref object of OpenApiRestCall_592364
proc url_TagResource_593420(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_593419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593421 = path.getOrDefault("resourceArn")
  valid_593421 = validateParameter(valid_593421, JString, required = true,
                                 default = nil)
  if valid_593421 != nil:
    section.add "resourceArn", valid_593421
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
  var valid_593422 = header.getOrDefault("X-Amz-Signature")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Signature", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Content-Sha256", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Date")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Date", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Credential")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Credential", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Security-Token")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Security-Token", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Algorithm")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Algorithm", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-SignedHeaders", valid_593428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593430: Call_TagResource_593418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_593430.validator(path, query, header, formData, body)
  let scheme = call_593430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593430.url(scheme.get, call_593430.host, call_593430.base,
                         call_593430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593430, url, valid)

proc call*(call_593431: Call_TagResource_593418; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  ##   body: JObject (required)
  var path_593432 = newJObject()
  var body_593433 = newJObject()
  add(path_593432, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593433 = body
  result = call_593431.call(path_593432, nil, nil, nil, body_593433)

var tagResource* = Call_TagResource_593418(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_593419,
                                        base: "/", url: url_TagResource_593420,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593404 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593406(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_593405(path: JsonNode; query: JsonNode;
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
  var valid_593407 = path.getOrDefault("resourceArn")
  valid_593407 = validateParameter(valid_593407, JString, required = true,
                                 default = nil)
  if valid_593407 != nil:
    section.add "resourceArn", valid_593407
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
  var valid_593408 = header.getOrDefault("X-Amz-Signature")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Signature", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Content-Sha256", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Date")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Date", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Credential")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Credential", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Security-Token")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Security-Token", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Algorithm")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Algorithm", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-SignedHeaders", valid_593414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593415: Call_ListTagsForResource_593404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_593415.validator(path, query, header, formData, body)
  let scheme = call_593415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593415.url(scheme.get, call_593415.host, call_593415.base,
                         call_593415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593415, url, valid)

proc call*(call_593416: Call_ListTagsForResource_593404; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_593417 = newJObject()
  add(path_593417, "resourceArn", newJString(resourceArn))
  result = call_593416.call(path_593417, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593404(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_593405, base: "/",
    url: url_ListTagsForResource_593406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_593434 = ref object of OpenApiRestCall_592364
proc url_StartDeployment_593436(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_593435(path: JsonNode; query: JsonNode;
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
  var valid_593437 = path.getOrDefault("branchName")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "branchName", valid_593437
  var valid_593438 = path.getOrDefault("appId")
  valid_593438 = validateParameter(valid_593438, JString, required = true,
                                 default = nil)
  if valid_593438 != nil:
    section.add "appId", valid_593438
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
  var valid_593439 = header.getOrDefault("X-Amz-Signature")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Signature", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Content-Sha256", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Date")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Date", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Credential")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Credential", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Security-Token")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Security-Token", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Algorithm")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Algorithm", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-SignedHeaders", valid_593445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593447: Call_StartDeployment_593434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_593447.validator(path, query, header, formData, body)
  let scheme = call_593447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593447.url(scheme.get, call_593447.host, call_593447.base,
                         call_593447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593447, url, valid)

proc call*(call_593448: Call_StartDeployment_593434; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_593449 = newJObject()
  var body_593450 = newJObject()
  add(path_593449, "branchName", newJString(branchName))
  add(path_593449, "appId", newJString(appId))
  if body != nil:
    body_593450 = body
  result = call_593448.call(path_593449, nil, nil, nil, body_593450)

var startDeployment* = Call_StartDeployment_593434(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_593435, base: "/", url: url_StartDeployment_593436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_593451 = ref object of OpenApiRestCall_592364
proc url_StopJob_593453(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_593452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593454 = path.getOrDefault("jobId")
  valid_593454 = validateParameter(valid_593454, JString, required = true,
                                 default = nil)
  if valid_593454 != nil:
    section.add "jobId", valid_593454
  var valid_593455 = path.getOrDefault("branchName")
  valid_593455 = validateParameter(valid_593455, JString, required = true,
                                 default = nil)
  if valid_593455 != nil:
    section.add "branchName", valid_593455
  var valid_593456 = path.getOrDefault("appId")
  valid_593456 = validateParameter(valid_593456, JString, required = true,
                                 default = nil)
  if valid_593456 != nil:
    section.add "appId", valid_593456
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
  var valid_593457 = header.getOrDefault("X-Amz-Signature")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Signature", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Content-Sha256", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Date")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Date", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Credential")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Credential", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Security-Token")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Security-Token", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Algorithm")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Algorithm", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-SignedHeaders", valid_593463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593464: Call_StopJob_593451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_593464.validator(path, query, header, formData, body)
  let scheme = call_593464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593464.url(scheme.get, call_593464.host, call_593464.base,
                         call_593464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593464, url, valid)

proc call*(call_593465: Call_StopJob_593451; jobId: string; branchName: string;
          appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_593466 = newJObject()
  add(path_593466, "jobId", newJString(jobId))
  add(path_593466, "branchName", newJString(branchName))
  add(path_593466, "appId", newJString(appId))
  result = call_593465.call(path_593466, nil, nil, nil, nil)

var stopJob* = Call_StopJob_593451(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_593452, base: "/",
                                url: url_StopJob_593453,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593467 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593469(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593470 = path.getOrDefault("resourceArn")
  valid_593470 = validateParameter(valid_593470, JString, required = true,
                                 default = nil)
  if valid_593470 != nil:
    section.add "resourceArn", valid_593470
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593471 = query.getOrDefault("tagKeys")
  valid_593471 = validateParameter(valid_593471, JArray, required = true, default = nil)
  if valid_593471 != nil:
    section.add "tagKeys", valid_593471
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
  var valid_593472 = header.getOrDefault("X-Amz-Signature")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Signature", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Content-Sha256", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Date")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Date", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Credential")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Credential", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Security-Token")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Security-Token", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Algorithm")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Algorithm", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-SignedHeaders", valid_593478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593479: Call_UntagResource_593467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_593479.validator(path, query, header, formData, body)
  let scheme = call_593479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593479.url(scheme.get, call_593479.host, call_593479.base,
                         call_593479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593479, url, valid)

proc call*(call_593480: Call_UntagResource_593467; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  var path_593481 = newJObject()
  var query_593482 = newJObject()
  add(path_593481, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_593482.add "tagKeys", tagKeys
  result = call_593480.call(path_593481, query_593482, nil, nil, nil)

var untagResource* = Call_UntagResource_593467(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_593468,
    base: "/", url: url_UntagResource_593469, schemes: {Scheme.Https, Scheme.Http})
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
