
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint
## version: 2016-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Doc Engage API - Amazon Pinpoint API
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/pinpoint/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "pinpoint.ap-northeast-1.amazonaws.com", "ap-southeast-1": "pinpoint.ap-southeast-1.amazonaws.com",
                           "us-west-2": "pinpoint.us-west-2.amazonaws.com",
                           "eu-west-2": "pinpoint.eu-west-2.amazonaws.com", "ap-northeast-3": "pinpoint.ap-northeast-3.amazonaws.com", "eu-central-1": "pinpoint.eu-central-1.amazonaws.com",
                           "us-east-2": "pinpoint.us-east-2.amazonaws.com",
                           "us-east-1": "pinpoint.us-east-1.amazonaws.com", "cn-northwest-1": "pinpoint.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "pinpoint.ap-south-1.amazonaws.com",
                           "eu-north-1": "pinpoint.eu-north-1.amazonaws.com", "ap-northeast-2": "pinpoint.ap-northeast-2.amazonaws.com",
                           "us-west-1": "pinpoint.us-west-1.amazonaws.com", "us-gov-east-1": "pinpoint.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "pinpoint.eu-west-3.amazonaws.com", "cn-north-1": "pinpoint.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "pinpoint.sa-east-1.amazonaws.com",
                           "eu-west-1": "pinpoint.eu-west-1.amazonaws.com", "us-gov-west-1": "pinpoint.us-gov-west-1.amazonaws.com", "ap-southeast-2": "pinpoint.ap-southeast-2.amazonaws.com", "ca-central-1": "pinpoint.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "pinpoint.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "pinpoint.ap-southeast-1.amazonaws.com",
      "us-west-2": "pinpoint.us-west-2.amazonaws.com",
      "eu-west-2": "pinpoint.eu-west-2.amazonaws.com",
      "ap-northeast-3": "pinpoint.ap-northeast-3.amazonaws.com",
      "eu-central-1": "pinpoint.eu-central-1.amazonaws.com",
      "us-east-2": "pinpoint.us-east-2.amazonaws.com",
      "us-east-1": "pinpoint.us-east-1.amazonaws.com",
      "cn-northwest-1": "pinpoint.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "pinpoint.ap-south-1.amazonaws.com",
      "eu-north-1": "pinpoint.eu-north-1.amazonaws.com",
      "ap-northeast-2": "pinpoint.ap-northeast-2.amazonaws.com",
      "us-west-1": "pinpoint.us-west-1.amazonaws.com",
      "us-gov-east-1": "pinpoint.us-gov-east-1.amazonaws.com",
      "eu-west-3": "pinpoint.eu-west-3.amazonaws.com",
      "cn-north-1": "pinpoint.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "pinpoint.sa-east-1.amazonaws.com",
      "eu-west-1": "pinpoint.eu-west-1.amazonaws.com",
      "us-gov-west-1": "pinpoint.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "pinpoint.ap-southeast-2.amazonaws.com",
      "ca-central-1": "pinpoint.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pinpoint"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateApp_21626002 = ref object of OpenApiRestCall_21625418
proc url_CreateApp_21626004(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_21626003(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  <p>Creates an application.</p>
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
  var valid_21626005 = header.getOrDefault("X-Amz-Date")
  valid_21626005 = validateParameter(valid_21626005, JString, required = false,
                                   default = nil)
  if valid_21626005 != nil:
    section.add "X-Amz-Date", valid_21626005
  var valid_21626006 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626006 = validateParameter(valid_21626006, JString, required = false,
                                   default = nil)
  if valid_21626006 != nil:
    section.add "X-Amz-Security-Token", valid_21626006
  var valid_21626007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626007 = validateParameter(valid_21626007, JString, required = false,
                                   default = nil)
  if valid_21626007 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626007
  var valid_21626008 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626008 = validateParameter(valid_21626008, JString, required = false,
                                   default = nil)
  if valid_21626008 != nil:
    section.add "X-Amz-Algorithm", valid_21626008
  var valid_21626009 = header.getOrDefault("X-Amz-Signature")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Signature", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Credential")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Credential", valid_21626011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626013: Call_CreateApp_21626002; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_21626013.validator(path, query, header, formData, body, _)
  let scheme = call_21626013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626013.makeUrl(scheme.get, call_21626013.host, call_21626013.base,
                               call_21626013.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626013, uri, valid, _)

proc call*(call_21626014: Call_CreateApp_21626002; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_21626015 = newJObject()
  if body != nil:
    body_21626015 = body
  result = call_21626014.call(nil, nil, nil, nil, body_21626015)

var createApp* = Call_CreateApp_21626002(name: "createApp",
                                      meth: HttpMethod.HttpPost,
                                      host: "pinpoint.amazonaws.com",
                                      route: "/v1/apps",
                                      validator: validate_CreateApp_21626003,
                                      base: "/", makeUrl: url_CreateApp_21626004,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetApps_21625764(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApps_21625763(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21625865 = query.getOrDefault("token")
  valid_21625865 = validateParameter(valid_21625865, JString, required = false,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "token", valid_21625865
  var valid_21625866 = query.getOrDefault("page-size")
  valid_21625866 = validateParameter(valid_21625866, JString, required = false,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "page-size", valid_21625866
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
  var valid_21625867 = header.getOrDefault("X-Amz-Date")
  valid_21625867 = validateParameter(valid_21625867, JString, required = false,
                                   default = nil)
  if valid_21625867 != nil:
    section.add "X-Amz-Date", valid_21625867
  var valid_21625868 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625868 = validateParameter(valid_21625868, JString, required = false,
                                   default = nil)
  if valid_21625868 != nil:
    section.add "X-Amz-Security-Token", valid_21625868
  var valid_21625869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625869 = validateParameter(valid_21625869, JString, required = false,
                                   default = nil)
  if valid_21625869 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625869
  var valid_21625870 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625870 = validateParameter(valid_21625870, JString, required = false,
                                   default = nil)
  if valid_21625870 != nil:
    section.add "X-Amz-Algorithm", valid_21625870
  var valid_21625871 = header.getOrDefault("X-Amz-Signature")
  valid_21625871 = validateParameter(valid_21625871, JString, required = false,
                                   default = nil)
  if valid_21625871 != nil:
    section.add "X-Amz-Signature", valid_21625871
  var valid_21625872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625872 = validateParameter(valid_21625872, JString, required = false,
                                   default = nil)
  if valid_21625872 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625872
  var valid_21625873 = header.getOrDefault("X-Amz-Credential")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Credential", valid_21625873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625898: Call_GetApps_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_21625898.validator(path, query, header, formData, body, _)
  let scheme = call_21625898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625898.makeUrl(scheme.get, call_21625898.host, call_21625898.base,
                               call_21625898.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625898, uri, valid, _)

proc call*(call_21625961: Call_GetApps_21625762; token: string = "";
          pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_21625963 = newJObject()
  add(query_21625963, "token", newJString(token))
  add(query_21625963, "page-size", newJString(pageSize))
  result = call_21625961.call(nil, query_21625963, nil, nil, nil)

var getApps* = Call_GetApps_21625762(name: "getApps", meth: HttpMethod.HttpGet,
                                  host: "pinpoint.amazonaws.com",
                                  route: "/v1/apps", validator: validate_GetApps_21625763,
                                  base: "/", makeUrl: url_GetApps_21625764,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_21626046 = ref object of OpenApiRestCall_21625418
proc url_CreateCampaign_21626048(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCampaign_21626047(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626049 = path.getOrDefault("application-id")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "application-id", valid_21626049
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626058: Call_CreateCampaign_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_CreateCampaign_21626046; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626060 = newJObject()
  var body_21626061 = newJObject()
  add(path_21626060, "application-id", newJString(applicationId))
  if body != nil:
    body_21626061 = body
  result = call_21626059.call(path_21626060, nil, nil, nil, body_21626061)

var createCampaign* = Call_CreateCampaign_21626046(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_21626047, base: "/",
    makeUrl: url_CreateCampaign_21626048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_21626016 = ref object of OpenApiRestCall_21625418
proc url_GetCampaigns_21626018(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaigns_21626017(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626032 = path.getOrDefault("application-id")
  valid_21626032 = validateParameter(valid_21626032, JString, required = true,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "application-id", valid_21626032
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21626033 = query.getOrDefault("token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "token", valid_21626033
  var valid_21626034 = query.getOrDefault("page-size")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "page-size", valid_21626034
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
  var valid_21626035 = header.getOrDefault("X-Amz-Date")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Date", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Security-Token", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Algorithm", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Signature")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Signature", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Credential")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Credential", valid_21626041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626042: Call_GetCampaigns_21626016; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_21626042.validator(path, query, header, formData, body, _)
  let scheme = call_21626042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626042.makeUrl(scheme.get, call_21626042.host, call_21626042.base,
                               call_21626042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626042, uri, valid, _)

proc call*(call_21626043: Call_GetCampaigns_21626016; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21626044 = newJObject()
  var query_21626045 = newJObject()
  add(query_21626045, "token", newJString(token))
  add(path_21626044, "application-id", newJString(applicationId))
  add(query_21626045, "page-size", newJString(pageSize))
  result = call_21626043.call(path_21626044, query_21626045, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_21626016(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_21626017, base: "/", makeUrl: url_GetCampaigns_21626018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_21626078 = ref object of OpenApiRestCall_21625418
proc url_UpdateEmailTemplate_21626080(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEmailTemplate_21626079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626081 = path.getOrDefault("template-name")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "template-name", valid_21626081
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626082 = query.getOrDefault("create-new-version")
  valid_21626082 = validateParameter(valid_21626082, JBool, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "create-new-version", valid_21626082
  var valid_21626083 = query.getOrDefault("version")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "version", valid_21626083
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
  var valid_21626084 = header.getOrDefault("X-Amz-Date")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Date", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Security-Token", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626092: Call_UpdateEmailTemplate_21626078; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_UpdateEmailTemplate_21626078; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template for messages that are sent through the email channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   body: JObject (required)
  var path_21626094 = newJObject()
  var query_21626095 = newJObject()
  var body_21626096 = newJObject()
  add(query_21626095, "create-new-version", newJBool(createNewVersion))
  add(path_21626094, "template-name", newJString(templateName))
  add(query_21626095, "version", newJString(version))
  if body != nil:
    body_21626096 = body
  result = call_21626093.call(path_21626094, query_21626095, nil, nil, body_21626096)

var updateEmailTemplate* = Call_UpdateEmailTemplate_21626078(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_21626079, base: "/",
    makeUrl: url_UpdateEmailTemplate_21626080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_21626097 = ref object of OpenApiRestCall_21625418
proc url_CreateEmailTemplate_21626099(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateEmailTemplate_21626098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626100 = path.getOrDefault("template-name")
  valid_21626100 = validateParameter(valid_21626100, JString, required = true,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "template-name", valid_21626100
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
  var valid_21626101 = header.getOrDefault("X-Amz-Date")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Date", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Security-Token", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Algorithm", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Signature")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Signature", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Credential")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Credential", valid_21626107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626109: Call_CreateEmailTemplate_21626097; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_21626109.validator(path, query, header, formData, body, _)
  let scheme = call_21626109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626109.makeUrl(scheme.get, call_21626109.host, call_21626109.base,
                               call_21626109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626109, uri, valid, _)

proc call*(call_21626110: Call_CreateEmailTemplate_21626097; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_21626111 = newJObject()
  var body_21626112 = newJObject()
  add(path_21626111, "template-name", newJString(templateName))
  if body != nil:
    body_21626112 = body
  result = call_21626110.call(path_21626111, nil, nil, nil, body_21626112)

var createEmailTemplate* = Call_CreateEmailTemplate_21626097(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_21626098, base: "/",
    makeUrl: url_CreateEmailTemplate_21626099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_21626062 = ref object of OpenApiRestCall_21625418
proc url_GetEmailTemplate_21626064(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailTemplate_21626063(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626065 = path.getOrDefault("template-name")
  valid_21626065 = validateParameter(valid_21626065, JString, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "template-name", valid_21626065
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626066 = query.getOrDefault("version")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "version", valid_21626066
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
  var valid_21626067 = header.getOrDefault("X-Amz-Date")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Date", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Security-Token", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Algorithm", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Signature")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Signature", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Credential")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Credential", valid_21626073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626074: Call_GetEmailTemplate_21626062; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_GetEmailTemplate_21626062; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626076 = newJObject()
  var query_21626077 = newJObject()
  add(path_21626076, "template-name", newJString(templateName))
  add(query_21626077, "version", newJString(version))
  result = call_21626075.call(path_21626076, query_21626077, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_21626062(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_21626063, base: "/",
    makeUrl: url_GetEmailTemplate_21626064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_21626113 = ref object of OpenApiRestCall_21625418
proc url_DeleteEmailTemplate_21626115(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailTemplate_21626114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626116 = path.getOrDefault("template-name")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "template-name", valid_21626116
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626117 = query.getOrDefault("version")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "version", valid_21626117
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
  var valid_21626118 = header.getOrDefault("X-Amz-Date")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Date", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Security-Token", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626125: Call_DeleteEmailTemplate_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_DeleteEmailTemplate_21626113; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626127 = newJObject()
  var query_21626128 = newJObject()
  add(path_21626127, "template-name", newJString(templateName))
  add(query_21626128, "version", newJString(version))
  result = call_21626126.call(path_21626127, query_21626128, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_21626113(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_21626114, base: "/",
    makeUrl: url_DeleteEmailTemplate_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_21626146 = ref object of OpenApiRestCall_21625418
proc url_CreateExportJob_21626148(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/export")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateExportJob_21626147(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an export job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626149 = path.getOrDefault("application-id")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "application-id", valid_21626149
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
  var valid_21626150 = header.getOrDefault("X-Amz-Date")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Date", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Security-Token", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Algorithm", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Signature")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Signature", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Credential")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Credential", valid_21626156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626158: Call_CreateExportJob_21626146; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_CreateExportJob_21626146; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626160 = newJObject()
  var body_21626161 = newJObject()
  add(path_21626160, "application-id", newJString(applicationId))
  if body != nil:
    body_21626161 = body
  result = call_21626159.call(path_21626160, nil, nil, nil, body_21626161)

var createExportJob* = Call_CreateExportJob_21626146(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_21626147, base: "/",
    makeUrl: url_CreateExportJob_21626148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_21626129 = ref object of OpenApiRestCall_21625418
proc url_GetExportJobs_21626131(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/export")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExportJobs_21626130(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626132 = path.getOrDefault("application-id")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "application-id", valid_21626132
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21626133 = query.getOrDefault("token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "token", valid_21626133
  var valid_21626134 = query.getOrDefault("page-size")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "page-size", valid_21626134
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
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_GetExportJobs_21626129; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_GetExportJobs_21626129; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21626144 = newJObject()
  var query_21626145 = newJObject()
  add(query_21626145, "token", newJString(token))
  add(path_21626144, "application-id", newJString(applicationId))
  add(query_21626145, "page-size", newJString(pageSize))
  result = call_21626143.call(path_21626144, query_21626145, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_21626129(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_21626130, base: "/",
    makeUrl: url_GetExportJobs_21626131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_21626179 = ref object of OpenApiRestCall_21625418
proc url_CreateImportJob_21626181(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/import")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateImportJob_21626180(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an import job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626182 = path.getOrDefault("application-id")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "application-id", valid_21626182
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
  var valid_21626183 = header.getOrDefault("X-Amz-Date")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Date", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Security-Token", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_CreateImportJob_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreateImportJob_21626179; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626193 = newJObject()
  var body_21626194 = newJObject()
  add(path_21626193, "application-id", newJString(applicationId))
  if body != nil:
    body_21626194 = body
  result = call_21626192.call(path_21626193, nil, nil, nil, body_21626194)

var createImportJob* = Call_CreateImportJob_21626179(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_21626180, base: "/",
    makeUrl: url_CreateImportJob_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_21626162 = ref object of OpenApiRestCall_21625418
proc url_GetImportJobs_21626164(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/import")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImportJobs_21626163(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626165 = path.getOrDefault("application-id")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "application-id", valid_21626165
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21626166 = query.getOrDefault("token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "token", valid_21626166
  var valid_21626167 = query.getOrDefault("page-size")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "page-size", valid_21626167
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
  var valid_21626168 = header.getOrDefault("X-Amz-Date")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Date", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Security-Token", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626175: Call_GetImportJobs_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_21626175.validator(path, query, header, formData, body, _)
  let scheme = call_21626175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626175.makeUrl(scheme.get, call_21626175.host, call_21626175.base,
                               call_21626175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626175, uri, valid, _)

proc call*(call_21626176: Call_GetImportJobs_21626162; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21626177 = newJObject()
  var query_21626178 = newJObject()
  add(query_21626178, "token", newJString(token))
  add(path_21626177, "application-id", newJString(applicationId))
  add(query_21626178, "page-size", newJString(pageSize))
  result = call_21626176.call(path_21626177, query_21626178, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_21626162(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_21626163, base: "/",
    makeUrl: url_GetImportJobs_21626164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_21626212 = ref object of OpenApiRestCall_21625418
proc url_CreateJourney_21626214(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateJourney_21626213(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a journey for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626215 = path.getOrDefault("application-id")
  valid_21626215 = validateParameter(valid_21626215, JString, required = true,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "application-id", valid_21626215
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
  var valid_21626216 = header.getOrDefault("X-Amz-Date")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Date", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Security-Token", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Algorithm", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Signature")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Signature", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Credential")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Credential", valid_21626222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626224: Call_CreateJourney_21626212; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_21626224.validator(path, query, header, formData, body, _)
  let scheme = call_21626224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626224.makeUrl(scheme.get, call_21626224.host, call_21626224.base,
                               call_21626224.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626224, uri, valid, _)

proc call*(call_21626225: Call_CreateJourney_21626212; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626226 = newJObject()
  var body_21626227 = newJObject()
  add(path_21626226, "application-id", newJString(applicationId))
  if body != nil:
    body_21626227 = body
  result = call_21626225.call(path_21626226, nil, nil, nil, body_21626227)

var createJourney* = Call_CreateJourney_21626212(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_21626213, base: "/",
    makeUrl: url_CreateJourney_21626214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_21626195 = ref object of OpenApiRestCall_21625418
proc url_ListJourneys_21626197(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJourneys_21626196(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626198 = path.getOrDefault("application-id")
  valid_21626198 = validateParameter(valid_21626198, JString, required = true,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "application-id", valid_21626198
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21626199 = query.getOrDefault("token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "token", valid_21626199
  var valid_21626200 = query.getOrDefault("page-size")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "page-size", valid_21626200
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
  var valid_21626201 = header.getOrDefault("X-Amz-Date")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Date", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Security-Token", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Algorithm", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Signature")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Signature", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Credential")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Credential", valid_21626207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626208: Call_ListJourneys_21626195; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_ListJourneys_21626195; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21626210 = newJObject()
  var query_21626211 = newJObject()
  add(query_21626211, "token", newJString(token))
  add(path_21626210, "application-id", newJString(applicationId))
  add(query_21626211, "page-size", newJString(pageSize))
  result = call_21626209.call(path_21626210, query_21626211, nil, nil, nil)

var listJourneys* = Call_ListJourneys_21626195(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_21626196,
    base: "/", makeUrl: url_ListJourneys_21626197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_21626244 = ref object of OpenApiRestCall_21625418
proc url_UpdatePushTemplate_21626246(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/push")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePushTemplate_21626245(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626247 = path.getOrDefault("template-name")
  valid_21626247 = validateParameter(valid_21626247, JString, required = true,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "template-name", valid_21626247
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626248 = query.getOrDefault("create-new-version")
  valid_21626248 = validateParameter(valid_21626248, JBool, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "create-new-version", valid_21626248
  var valid_21626249 = query.getOrDefault("version")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "version", valid_21626249
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
  var valid_21626250 = header.getOrDefault("X-Amz-Date")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Date", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Security-Token", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Algorithm", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Signature")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Signature", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Credential")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Credential", valid_21626256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626258: Call_UpdatePushTemplate_21626244; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_21626258.validator(path, query, header, formData, body, _)
  let scheme = call_21626258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626258.makeUrl(scheme.get, call_21626258.host, call_21626258.base,
                               call_21626258.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626258, uri, valid, _)

proc call*(call_21626259: Call_UpdatePushTemplate_21626244; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   body: JObject (required)
  var path_21626260 = newJObject()
  var query_21626261 = newJObject()
  var body_21626262 = newJObject()
  add(query_21626261, "create-new-version", newJBool(createNewVersion))
  add(path_21626260, "template-name", newJString(templateName))
  add(query_21626261, "version", newJString(version))
  if body != nil:
    body_21626262 = body
  result = call_21626259.call(path_21626260, query_21626261, nil, nil, body_21626262)

var updatePushTemplate* = Call_UpdatePushTemplate_21626244(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_21626245, base: "/",
    makeUrl: url_UpdatePushTemplate_21626246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_21626263 = ref object of OpenApiRestCall_21625418
proc url_CreatePushTemplate_21626265(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/push")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePushTemplate_21626264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626266 = path.getOrDefault("template-name")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "template-name", valid_21626266
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
  var valid_21626267 = header.getOrDefault("X-Amz-Date")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Date", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Security-Token", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Algorithm", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Signature")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Signature", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Credential")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Credential", valid_21626273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626275: Call_CreatePushTemplate_21626263; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_21626275.validator(path, query, header, formData, body, _)
  let scheme = call_21626275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626275.makeUrl(scheme.get, call_21626275.host, call_21626275.base,
                               call_21626275.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626275, uri, valid, _)

proc call*(call_21626276: Call_CreatePushTemplate_21626263; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_21626277 = newJObject()
  var body_21626278 = newJObject()
  add(path_21626277, "template-name", newJString(templateName))
  if body != nil:
    body_21626278 = body
  result = call_21626276.call(path_21626277, nil, nil, nil, body_21626278)

var createPushTemplate* = Call_CreatePushTemplate_21626263(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_21626264, base: "/",
    makeUrl: url_CreatePushTemplate_21626265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_21626228 = ref object of OpenApiRestCall_21625418
proc url_GetPushTemplate_21626230(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/push")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPushTemplate_21626229(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626231 = path.getOrDefault("template-name")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "template-name", valid_21626231
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626232 = query.getOrDefault("version")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "version", valid_21626232
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
  var valid_21626233 = header.getOrDefault("X-Amz-Date")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Date", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Security-Token", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Algorithm", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Signature")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Signature", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Credential")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Credential", valid_21626239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626240: Call_GetPushTemplate_21626228; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_21626240.validator(path, query, header, formData, body, _)
  let scheme = call_21626240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626240.makeUrl(scheme.get, call_21626240.host, call_21626240.base,
                               call_21626240.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626240, uri, valid, _)

proc call*(call_21626241: Call_GetPushTemplate_21626228; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626242 = newJObject()
  var query_21626243 = newJObject()
  add(path_21626242, "template-name", newJString(templateName))
  add(query_21626243, "version", newJString(version))
  result = call_21626241.call(path_21626242, query_21626243, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_21626228(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_21626229, base: "/",
    makeUrl: url_GetPushTemplate_21626230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_21626279 = ref object of OpenApiRestCall_21625418
proc url_DeletePushTemplate_21626281(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/push")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePushTemplate_21626280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626282 = path.getOrDefault("template-name")
  valid_21626282 = validateParameter(valid_21626282, JString, required = true,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "template-name", valid_21626282
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626283 = query.getOrDefault("version")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "version", valid_21626283
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
  var valid_21626284 = header.getOrDefault("X-Amz-Date")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Date", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Security-Token", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626291: Call_DeletePushTemplate_21626279; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_DeletePushTemplate_21626279; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626293 = newJObject()
  var query_21626294 = newJObject()
  add(path_21626293, "template-name", newJString(templateName))
  add(query_21626294, "version", newJString(version))
  result = call_21626292.call(path_21626293, query_21626294, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_21626279(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_21626280, base: "/",
    makeUrl: url_DeletePushTemplate_21626281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_21626312 = ref object of OpenApiRestCall_21625418
proc url_CreateSegment_21626314(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSegment_21626313(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626315 = path.getOrDefault("application-id")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "application-id", valid_21626315
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
  var valid_21626316 = header.getOrDefault("X-Amz-Date")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Date", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Security-Token", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Algorithm", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Signature")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Signature", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Credential")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Credential", valid_21626322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626324: Call_CreateSegment_21626312; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_21626324.validator(path, query, header, formData, body, _)
  let scheme = call_21626324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626324.makeUrl(scheme.get, call_21626324.host, call_21626324.base,
                               call_21626324.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626324, uri, valid, _)

proc call*(call_21626325: Call_CreateSegment_21626312; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626326 = newJObject()
  var body_21626327 = newJObject()
  add(path_21626326, "application-id", newJString(applicationId))
  if body != nil:
    body_21626327 = body
  result = call_21626325.call(path_21626326, nil, nil, nil, body_21626327)

var createSegment* = Call_CreateSegment_21626312(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_21626313, base: "/",
    makeUrl: url_CreateSegment_21626314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_21626295 = ref object of OpenApiRestCall_21625418
proc url_GetSegments_21626297(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegments_21626296(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626298 = path.getOrDefault("application-id")
  valid_21626298 = validateParameter(valid_21626298, JString, required = true,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "application-id", valid_21626298
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21626299 = query.getOrDefault("token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "token", valid_21626299
  var valid_21626300 = query.getOrDefault("page-size")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "page-size", valid_21626300
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
  var valid_21626301 = header.getOrDefault("X-Amz-Date")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Date", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Security-Token", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Algorithm", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Signature")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Signature", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Credential")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Credential", valid_21626307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626308: Call_GetSegments_21626295; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_21626308.validator(path, query, header, formData, body, _)
  let scheme = call_21626308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626308.makeUrl(scheme.get, call_21626308.host, call_21626308.base,
                               call_21626308.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626308, uri, valid, _)

proc call*(call_21626309: Call_GetSegments_21626295; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21626310 = newJObject()
  var query_21626311 = newJObject()
  add(query_21626311, "token", newJString(token))
  add(path_21626310, "application-id", newJString(applicationId))
  add(query_21626311, "page-size", newJString(pageSize))
  result = call_21626309.call(path_21626310, query_21626311, nil, nil, nil)

var getSegments* = Call_GetSegments_21626295(name: "getSegments",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments", validator: validate_GetSegments_21626296,
    base: "/", makeUrl: url_GetSegments_21626297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_21626344 = ref object of OpenApiRestCall_21625418
proc url_UpdateSmsTemplate_21626346(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSmsTemplate_21626345(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626347 = path.getOrDefault("template-name")
  valid_21626347 = validateParameter(valid_21626347, JString, required = true,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "template-name", valid_21626347
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626348 = query.getOrDefault("create-new-version")
  valid_21626348 = validateParameter(valid_21626348, JBool, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "create-new-version", valid_21626348
  var valid_21626349 = query.getOrDefault("version")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "version", valid_21626349
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
  var valid_21626350 = header.getOrDefault("X-Amz-Date")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Date", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Security-Token", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Algorithm", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Signature")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Signature", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Credential")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Credential", valid_21626356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626358: Call_UpdateSmsTemplate_21626344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_21626358.validator(path, query, header, formData, body, _)
  let scheme = call_21626358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626358.makeUrl(scheme.get, call_21626358.host, call_21626358.base,
                               call_21626358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626358, uri, valid, _)

proc call*(call_21626359: Call_UpdateSmsTemplate_21626344; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   body: JObject (required)
  var path_21626360 = newJObject()
  var query_21626361 = newJObject()
  var body_21626362 = newJObject()
  add(query_21626361, "create-new-version", newJBool(createNewVersion))
  add(path_21626360, "template-name", newJString(templateName))
  add(query_21626361, "version", newJString(version))
  if body != nil:
    body_21626362 = body
  result = call_21626359.call(path_21626360, query_21626361, nil, nil, body_21626362)

var updateSmsTemplate* = Call_UpdateSmsTemplate_21626344(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_21626345, base: "/",
    makeUrl: url_UpdateSmsTemplate_21626346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_21626363 = ref object of OpenApiRestCall_21625418
proc url_CreateSmsTemplate_21626365(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSmsTemplate_21626364(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626366 = path.getOrDefault("template-name")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "template-name", valid_21626366
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
  var valid_21626367 = header.getOrDefault("X-Amz-Date")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Date", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Security-Token", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Algorithm", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Signature")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Signature", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Credential")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Credential", valid_21626373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626375: Call_CreateSmsTemplate_21626363; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_21626375.validator(path, query, header, formData, body, _)
  let scheme = call_21626375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626375.makeUrl(scheme.get, call_21626375.host, call_21626375.base,
                               call_21626375.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626375, uri, valid, _)

proc call*(call_21626376: Call_CreateSmsTemplate_21626363; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_21626377 = newJObject()
  var body_21626378 = newJObject()
  add(path_21626377, "template-name", newJString(templateName))
  if body != nil:
    body_21626378 = body
  result = call_21626376.call(path_21626377, nil, nil, nil, body_21626378)

var createSmsTemplate* = Call_CreateSmsTemplate_21626363(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_21626364, base: "/",
    makeUrl: url_CreateSmsTemplate_21626365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_21626328 = ref object of OpenApiRestCall_21625418
proc url_GetSmsTemplate_21626330(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSmsTemplate_21626329(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626331 = path.getOrDefault("template-name")
  valid_21626331 = validateParameter(valid_21626331, JString, required = true,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "template-name", valid_21626331
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626332 = query.getOrDefault("version")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "version", valid_21626332
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
  var valid_21626333 = header.getOrDefault("X-Amz-Date")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Date", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Security-Token", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626340: Call_GetSmsTemplate_21626328; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_21626340.validator(path, query, header, formData, body, _)
  let scheme = call_21626340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626340.makeUrl(scheme.get, call_21626340.host, call_21626340.base,
                               call_21626340.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626340, uri, valid, _)

proc call*(call_21626341: Call_GetSmsTemplate_21626328; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626342 = newJObject()
  var query_21626343 = newJObject()
  add(path_21626342, "template-name", newJString(templateName))
  add(query_21626343, "version", newJString(version))
  result = call_21626341.call(path_21626342, query_21626343, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_21626328(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_21626329, base: "/",
    makeUrl: url_GetSmsTemplate_21626330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_21626379 = ref object of OpenApiRestCall_21625418
proc url_DeleteSmsTemplate_21626381(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSmsTemplate_21626380(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626382 = path.getOrDefault("template-name")
  valid_21626382 = validateParameter(valid_21626382, JString, required = true,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "template-name", valid_21626382
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626383 = query.getOrDefault("version")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "version", valid_21626383
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
  var valid_21626384 = header.getOrDefault("X-Amz-Date")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Date", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Security-Token", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Algorithm", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Signature")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Signature", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Credential")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Credential", valid_21626390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626391: Call_DeleteSmsTemplate_21626379; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_21626391.validator(path, query, header, formData, body, _)
  let scheme = call_21626391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626391.makeUrl(scheme.get, call_21626391.host, call_21626391.base,
                               call_21626391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626391, uri, valid, _)

proc call*(call_21626392: Call_DeleteSmsTemplate_21626379; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626393 = newJObject()
  var query_21626394 = newJObject()
  add(path_21626393, "template-name", newJString(templateName))
  add(query_21626394, "version", newJString(version))
  result = call_21626392.call(path_21626393, query_21626394, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_21626379(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_21626380, base: "/",
    makeUrl: url_DeleteSmsTemplate_21626381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_21626411 = ref object of OpenApiRestCall_21625418
proc url_UpdateVoiceTemplate_21626413(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceTemplate_21626412(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626414 = path.getOrDefault("template-name")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "template-name", valid_21626414
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626415 = query.getOrDefault("create-new-version")
  valid_21626415 = validateParameter(valid_21626415, JBool, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "create-new-version", valid_21626415
  var valid_21626416 = query.getOrDefault("version")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "version", valid_21626416
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
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Algorithm", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Signature")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Signature", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Credential")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Credential", valid_21626423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626425: Call_UpdateVoiceTemplate_21626411; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_21626425.validator(path, query, header, formData, body, _)
  let scheme = call_21626425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626425.makeUrl(scheme.get, call_21626425.host, call_21626425.base,
                               call_21626425.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626425, uri, valid, _)

proc call*(call_21626426: Call_UpdateVoiceTemplate_21626411; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateVoiceTemplate
  ## Updates an existing message template for messages that are sent through the voice channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   body: JObject (required)
  var path_21626427 = newJObject()
  var query_21626428 = newJObject()
  var body_21626429 = newJObject()
  add(query_21626428, "create-new-version", newJBool(createNewVersion))
  add(path_21626427, "template-name", newJString(templateName))
  add(query_21626428, "version", newJString(version))
  if body != nil:
    body_21626429 = body
  result = call_21626426.call(path_21626427, query_21626428, nil, nil, body_21626429)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_21626411(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_21626412, base: "/",
    makeUrl: url_UpdateVoiceTemplate_21626413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_21626430 = ref object of OpenApiRestCall_21625418
proc url_CreateVoiceTemplate_21626432(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVoiceTemplate_21626431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626433 = path.getOrDefault("template-name")
  valid_21626433 = validateParameter(valid_21626433, JString, required = true,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "template-name", valid_21626433
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
  var valid_21626434 = header.getOrDefault("X-Amz-Date")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Date", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Security-Token", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Algorithm", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Signature")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Signature", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Credential")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Credential", valid_21626440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626442: Call_CreateVoiceTemplate_21626430; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_21626442.validator(path, query, header, formData, body, _)
  let scheme = call_21626442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626442.makeUrl(scheme.get, call_21626442.host, call_21626442.base,
                               call_21626442.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626442, uri, valid, _)

proc call*(call_21626443: Call_CreateVoiceTemplate_21626430; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_21626444 = newJObject()
  var body_21626445 = newJObject()
  add(path_21626444, "template-name", newJString(templateName))
  if body != nil:
    body_21626445 = body
  result = call_21626443.call(path_21626444, nil, nil, nil, body_21626445)

var createVoiceTemplate* = Call_CreateVoiceTemplate_21626430(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_21626431, base: "/",
    makeUrl: url_CreateVoiceTemplate_21626432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_21626395 = ref object of OpenApiRestCall_21625418
proc url_GetVoiceTemplate_21626397(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceTemplate_21626396(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626398 = path.getOrDefault("template-name")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "template-name", valid_21626398
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626399 = query.getOrDefault("version")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "version", valid_21626399
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
  var valid_21626400 = header.getOrDefault("X-Amz-Date")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Date", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Security-Token", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Algorithm", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Signature")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Signature", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Credential")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Credential", valid_21626406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626407: Call_GetVoiceTemplate_21626395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_21626407.validator(path, query, header, formData, body, _)
  let scheme = call_21626407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626407.makeUrl(scheme.get, call_21626407.host, call_21626407.base,
                               call_21626407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626407, uri, valid, _)

proc call*(call_21626408: Call_GetVoiceTemplate_21626395; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626409 = newJObject()
  var query_21626410 = newJObject()
  add(path_21626409, "template-name", newJString(templateName))
  add(query_21626410, "version", newJString(version))
  result = call_21626408.call(path_21626409, query_21626410, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_21626395(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_21626396, base: "/",
    makeUrl: url_GetVoiceTemplate_21626397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_21626446 = ref object of OpenApiRestCall_21625418
proc url_DeleteVoiceTemplate_21626448(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceTemplate_21626447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_21626449 = path.getOrDefault("template-name")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "template-name", valid_21626449
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_21626450 = query.getOrDefault("version")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "version", valid_21626450
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
  var valid_21626451 = header.getOrDefault("X-Amz-Date")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Date", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Security-Token", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Algorithm", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Signature")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Signature", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Credential")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Credential", valid_21626457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626458: Call_DeleteVoiceTemplate_21626446; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_21626458.validator(path, query, header, formData, body, _)
  let scheme = call_21626458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626458.makeUrl(scheme.get, call_21626458.host, call_21626458.base,
                               call_21626458.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626458, uri, valid, _)

proc call*(call_21626459: Call_DeleteVoiceTemplate_21626446; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_21626460 = newJObject()
  var query_21626461 = newJObject()
  add(path_21626460, "template-name", newJString(templateName))
  add(query_21626461, "version", newJString(version))
  result = call_21626459.call(path_21626460, query_21626461, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_21626446(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_21626447, base: "/",
    makeUrl: url_DeleteVoiceTemplate_21626448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_21626476 = ref object of OpenApiRestCall_21625418
proc url_UpdateAdmChannel_21626478(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAdmChannel_21626477(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626479 = path.getOrDefault("application-id")
  valid_21626479 = validateParameter(valid_21626479, JString, required = true,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "application-id", valid_21626479
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
  var valid_21626480 = header.getOrDefault("X-Amz-Date")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Date", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Security-Token", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Algorithm", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Signature")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Signature", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Credential")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Credential", valid_21626486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626488: Call_UpdateAdmChannel_21626476; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_21626488.validator(path, query, header, formData, body, _)
  let scheme = call_21626488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626488.makeUrl(scheme.get, call_21626488.host, call_21626488.base,
                               call_21626488.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626488, uri, valid, _)

proc call*(call_21626489: Call_UpdateAdmChannel_21626476; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626490 = newJObject()
  var body_21626491 = newJObject()
  add(path_21626490, "application-id", newJString(applicationId))
  if body != nil:
    body_21626491 = body
  result = call_21626489.call(path_21626490, nil, nil, nil, body_21626491)

var updateAdmChannel* = Call_UpdateAdmChannel_21626476(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_21626477, base: "/",
    makeUrl: url_UpdateAdmChannel_21626478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_21626462 = ref object of OpenApiRestCall_21625418
proc url_GetAdmChannel_21626464(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAdmChannel_21626463(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626465 = path.getOrDefault("application-id")
  valid_21626465 = validateParameter(valid_21626465, JString, required = true,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "application-id", valid_21626465
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
  var valid_21626466 = header.getOrDefault("X-Amz-Date")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Date", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Security-Token", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Algorithm", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Signature")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Signature", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Credential")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Credential", valid_21626472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626473: Call_GetAdmChannel_21626462; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_21626473.validator(path, query, header, formData, body, _)
  let scheme = call_21626473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626473.makeUrl(scheme.get, call_21626473.host, call_21626473.base,
                               call_21626473.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626473, uri, valid, _)

proc call*(call_21626474: Call_GetAdmChannel_21626462; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626475 = newJObject()
  add(path_21626475, "application-id", newJString(applicationId))
  result = call_21626474.call(path_21626475, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_21626462(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_21626463, base: "/",
    makeUrl: url_GetAdmChannel_21626464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_21626492 = ref object of OpenApiRestCall_21625418
proc url_DeleteAdmChannel_21626494(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAdmChannel_21626493(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626495 = path.getOrDefault("application-id")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "application-id", valid_21626495
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
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626503: Call_DeleteAdmChannel_21626492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_DeleteAdmChannel_21626492; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626505 = newJObject()
  add(path_21626505, "application-id", newJString(applicationId))
  result = call_21626504.call(path_21626505, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_21626492(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_21626493, base: "/",
    makeUrl: url_DeleteAdmChannel_21626494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_21626520 = ref object of OpenApiRestCall_21625418
proc url_UpdateApnsChannel_21626522(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsChannel_21626521(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626523 = path.getOrDefault("application-id")
  valid_21626523 = validateParameter(valid_21626523, JString, required = true,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "application-id", valid_21626523
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
  var valid_21626524 = header.getOrDefault("X-Amz-Date")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Date", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Security-Token", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Algorithm", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Signature")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Signature", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Credential")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Credential", valid_21626530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626532: Call_UpdateApnsChannel_21626520; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_21626532.validator(path, query, header, formData, body, _)
  let scheme = call_21626532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626532.makeUrl(scheme.get, call_21626532.host, call_21626532.base,
                               call_21626532.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626532, uri, valid, _)

proc call*(call_21626533: Call_UpdateApnsChannel_21626520; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626534 = newJObject()
  var body_21626535 = newJObject()
  add(path_21626534, "application-id", newJString(applicationId))
  if body != nil:
    body_21626535 = body
  result = call_21626533.call(path_21626534, nil, nil, nil, body_21626535)

var updateApnsChannel* = Call_UpdateApnsChannel_21626520(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_21626521, base: "/",
    makeUrl: url_UpdateApnsChannel_21626522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_21626506 = ref object of OpenApiRestCall_21625418
proc url_GetApnsChannel_21626508(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsChannel_21626507(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626509 = path.getOrDefault("application-id")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "application-id", valid_21626509
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
  var valid_21626510 = header.getOrDefault("X-Amz-Date")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Date", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Security-Token", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Algorithm", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Signature")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Signature", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Credential")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Credential", valid_21626516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626517: Call_GetApnsChannel_21626506; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_21626517.validator(path, query, header, formData, body, _)
  let scheme = call_21626517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626517.makeUrl(scheme.get, call_21626517.host, call_21626517.base,
                               call_21626517.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626517, uri, valid, _)

proc call*(call_21626518: Call_GetApnsChannel_21626506; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626519 = newJObject()
  add(path_21626519, "application-id", newJString(applicationId))
  result = call_21626518.call(path_21626519, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_21626506(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_21626507, base: "/",
    makeUrl: url_GetApnsChannel_21626508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_21626536 = ref object of OpenApiRestCall_21625418
proc url_DeleteApnsChannel_21626538(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsChannel_21626537(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626539 = path.getOrDefault("application-id")
  valid_21626539 = validateParameter(valid_21626539, JString, required = true,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "application-id", valid_21626539
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
  var valid_21626540 = header.getOrDefault("X-Amz-Date")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Date", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Security-Token", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Algorithm", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Signature")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Signature", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Credential")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Credential", valid_21626546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626547: Call_DeleteApnsChannel_21626536; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626547.validator(path, query, header, formData, body, _)
  let scheme = call_21626547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626547.makeUrl(scheme.get, call_21626547.host, call_21626547.base,
                               call_21626547.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626547, uri, valid, _)

proc call*(call_21626548: Call_DeleteApnsChannel_21626536; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626549 = newJObject()
  add(path_21626549, "application-id", newJString(applicationId))
  result = call_21626548.call(path_21626549, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_21626536(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_21626537, base: "/",
    makeUrl: url_DeleteApnsChannel_21626538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_21626564 = ref object of OpenApiRestCall_21625418
proc url_UpdateApnsSandboxChannel_21626566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsSandboxChannel_21626565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626567 = path.getOrDefault("application-id")
  valid_21626567 = validateParameter(valid_21626567, JString, required = true,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "application-id", valid_21626567
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
  var valid_21626568 = header.getOrDefault("X-Amz-Date")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Date", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Security-Token", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Algorithm", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Signature")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Signature", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Credential")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Credential", valid_21626574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626576: Call_UpdateApnsSandboxChannel_21626564;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_21626576.validator(path, query, header, formData, body, _)
  let scheme = call_21626576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626576.makeUrl(scheme.get, call_21626576.host, call_21626576.base,
                               call_21626576.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626576, uri, valid, _)

proc call*(call_21626577: Call_UpdateApnsSandboxChannel_21626564;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626578 = newJObject()
  var body_21626579 = newJObject()
  add(path_21626578, "application-id", newJString(applicationId))
  if body != nil:
    body_21626579 = body
  result = call_21626577.call(path_21626578, nil, nil, nil, body_21626579)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_21626564(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_21626565, base: "/",
    makeUrl: url_UpdateApnsSandboxChannel_21626566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_21626550 = ref object of OpenApiRestCall_21625418
proc url_GetApnsSandboxChannel_21626552(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsSandboxChannel_21626551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626553 = path.getOrDefault("application-id")
  valid_21626553 = validateParameter(valid_21626553, JString, required = true,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "application-id", valid_21626553
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
  var valid_21626554 = header.getOrDefault("X-Amz-Date")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Date", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Security-Token", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Algorithm", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Signature")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Signature", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Credential")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Credential", valid_21626560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626561: Call_GetApnsSandboxChannel_21626550;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_21626561.validator(path, query, header, formData, body, _)
  let scheme = call_21626561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626561.makeUrl(scheme.get, call_21626561.host, call_21626561.base,
                               call_21626561.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626561, uri, valid, _)

proc call*(call_21626562: Call_GetApnsSandboxChannel_21626550;
          applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626563 = newJObject()
  add(path_21626563, "application-id", newJString(applicationId))
  result = call_21626562.call(path_21626563, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_21626550(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_21626551, base: "/",
    makeUrl: url_GetApnsSandboxChannel_21626552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_21626580 = ref object of OpenApiRestCall_21625418
proc url_DeleteApnsSandboxChannel_21626582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsSandboxChannel_21626581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626583 = path.getOrDefault("application-id")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "application-id", valid_21626583
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
  var valid_21626584 = header.getOrDefault("X-Amz-Date")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Date", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Security-Token", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Algorithm", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Signature")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Signature", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Credential")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Credential", valid_21626590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626591: Call_DeleteApnsSandboxChannel_21626580;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_DeleteApnsSandboxChannel_21626580;
          applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626593 = newJObject()
  add(path_21626593, "application-id", newJString(applicationId))
  result = call_21626592.call(path_21626593, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_21626580(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_21626581, base: "/",
    makeUrl: url_DeleteApnsSandboxChannel_21626582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_21626608 = ref object of OpenApiRestCall_21625418
proc url_UpdateApnsVoipChannel_21626610(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsVoipChannel_21626609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626611 = path.getOrDefault("application-id")
  valid_21626611 = validateParameter(valid_21626611, JString, required = true,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "application-id", valid_21626611
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
  var valid_21626612 = header.getOrDefault("X-Amz-Date")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Date", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Security-Token", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Algorithm", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Signature")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Signature", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Credential")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Credential", valid_21626618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626620: Call_UpdateApnsVoipChannel_21626608;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_21626620.validator(path, query, header, formData, body, _)
  let scheme = call_21626620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626620.makeUrl(scheme.get, call_21626620.host, call_21626620.base,
                               call_21626620.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626620, uri, valid, _)

proc call*(call_21626621: Call_UpdateApnsVoipChannel_21626608;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626622 = newJObject()
  var body_21626623 = newJObject()
  add(path_21626622, "application-id", newJString(applicationId))
  if body != nil:
    body_21626623 = body
  result = call_21626621.call(path_21626622, nil, nil, nil, body_21626623)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_21626608(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_21626609, base: "/",
    makeUrl: url_UpdateApnsVoipChannel_21626610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_21626594 = ref object of OpenApiRestCall_21625418
proc url_GetApnsVoipChannel_21626596(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsVoipChannel_21626595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626597 = path.getOrDefault("application-id")
  valid_21626597 = validateParameter(valid_21626597, JString, required = true,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "application-id", valid_21626597
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
  var valid_21626598 = header.getOrDefault("X-Amz-Date")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Date", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Security-Token", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Algorithm", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Signature")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Signature", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Credential")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Credential", valid_21626604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626605: Call_GetApnsVoipChannel_21626594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_21626605.validator(path, query, header, formData, body, _)
  let scheme = call_21626605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626605.makeUrl(scheme.get, call_21626605.host, call_21626605.base,
                               call_21626605.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626605, uri, valid, _)

proc call*(call_21626606: Call_GetApnsVoipChannel_21626594; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626607 = newJObject()
  add(path_21626607, "application-id", newJString(applicationId))
  result = call_21626606.call(path_21626607, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_21626594(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_21626595, base: "/",
    makeUrl: url_GetApnsVoipChannel_21626596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_21626624 = ref object of OpenApiRestCall_21625418
proc url_DeleteApnsVoipChannel_21626626(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsVoipChannel_21626625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626627 = path.getOrDefault("application-id")
  valid_21626627 = validateParameter(valid_21626627, JString, required = true,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "application-id", valid_21626627
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
  var valid_21626628 = header.getOrDefault("X-Amz-Date")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Date", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Security-Token", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Algorithm", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Signature")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Signature", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Credential")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Credential", valid_21626634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626635: Call_DeleteApnsVoipChannel_21626624;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626635.validator(path, query, header, formData, body, _)
  let scheme = call_21626635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626635.makeUrl(scheme.get, call_21626635.host, call_21626635.base,
                               call_21626635.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626635, uri, valid, _)

proc call*(call_21626636: Call_DeleteApnsVoipChannel_21626624;
          applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626637 = newJObject()
  add(path_21626637, "application-id", newJString(applicationId))
  result = call_21626636.call(path_21626637, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_21626624(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_21626625, base: "/",
    makeUrl: url_DeleteApnsVoipChannel_21626626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_21626652 = ref object of OpenApiRestCall_21625418
proc url_UpdateApnsVoipSandboxChannel_21626654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsVoipSandboxChannel_21626653(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626655 = path.getOrDefault("application-id")
  valid_21626655 = validateParameter(valid_21626655, JString, required = true,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "application-id", valid_21626655
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
  var valid_21626656 = header.getOrDefault("X-Amz-Date")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Date", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Security-Token", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Algorithm", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Signature")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Signature", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Credential")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Credential", valid_21626662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626664: Call_UpdateApnsVoipSandboxChannel_21626652;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_21626664.validator(path, query, header, formData, body, _)
  let scheme = call_21626664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626664.makeUrl(scheme.get, call_21626664.host, call_21626664.base,
                               call_21626664.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626664, uri, valid, _)

proc call*(call_21626665: Call_UpdateApnsVoipSandboxChannel_21626652;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626666 = newJObject()
  var body_21626667 = newJObject()
  add(path_21626666, "application-id", newJString(applicationId))
  if body != nil:
    body_21626667 = body
  result = call_21626665.call(path_21626666, nil, nil, nil, body_21626667)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_21626652(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_21626653, base: "/",
    makeUrl: url_UpdateApnsVoipSandboxChannel_21626654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_21626638 = ref object of OpenApiRestCall_21625418
proc url_GetApnsVoipSandboxChannel_21626640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsVoipSandboxChannel_21626639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626641 = path.getOrDefault("application-id")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "application-id", valid_21626641
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
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Algorithm", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Signature")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Signature", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Credential")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Credential", valid_21626648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626649: Call_GetApnsVoipSandboxChannel_21626638;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_21626649.validator(path, query, header, formData, body, _)
  let scheme = call_21626649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626649.makeUrl(scheme.get, call_21626649.host, call_21626649.base,
                               call_21626649.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626649, uri, valid, _)

proc call*(call_21626650: Call_GetApnsVoipSandboxChannel_21626638;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626651 = newJObject()
  add(path_21626651, "application-id", newJString(applicationId))
  result = call_21626650.call(path_21626651, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_21626638(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_21626639, base: "/",
    makeUrl: url_GetApnsVoipSandboxChannel_21626640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_21626668 = ref object of OpenApiRestCall_21625418
proc url_DeleteApnsVoipSandboxChannel_21626670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsVoipSandboxChannel_21626669(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626671 = path.getOrDefault("application-id")
  valid_21626671 = validateParameter(valid_21626671, JString, required = true,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "application-id", valid_21626671
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
  var valid_21626672 = header.getOrDefault("X-Amz-Date")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Date", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Security-Token", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Algorithm", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Signature")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Signature", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Credential")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Credential", valid_21626678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626679: Call_DeleteApnsVoipSandboxChannel_21626668;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626679.validator(path, query, header, formData, body, _)
  let scheme = call_21626679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626679.makeUrl(scheme.get, call_21626679.host, call_21626679.base,
                               call_21626679.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626679, uri, valid, _)

proc call*(call_21626680: Call_DeleteApnsVoipSandboxChannel_21626668;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626681 = newJObject()
  add(path_21626681, "application-id", newJString(applicationId))
  result = call_21626680.call(path_21626681, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_21626668(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_21626669, base: "/",
    makeUrl: url_DeleteApnsVoipSandboxChannel_21626670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_21626682 = ref object of OpenApiRestCall_21625418
proc url_GetApp_21626684(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApp_21626683(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626685 = path.getOrDefault("application-id")
  valid_21626685 = validateParameter(valid_21626685, JString, required = true,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "application-id", valid_21626685
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
  var valid_21626686 = header.getOrDefault("X-Amz-Date")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Date", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Security-Token", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-Algorithm", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Signature")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Signature", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Credential")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Credential", valid_21626692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626693: Call_GetApp_21626682; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_21626693.validator(path, query, header, formData, body, _)
  let scheme = call_21626693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626693.makeUrl(scheme.get, call_21626693.host, call_21626693.base,
                               call_21626693.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626693, uri, valid, _)

proc call*(call_21626694: Call_GetApp_21626682; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626695 = newJObject()
  add(path_21626695, "application-id", newJString(applicationId))
  result = call_21626694.call(path_21626695, nil, nil, nil, nil)

var getApp* = Call_GetApp_21626682(name: "getApp", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com",
                                route: "/v1/apps/{application-id}",
                                validator: validate_GetApp_21626683, base: "/",
                                makeUrl: url_GetApp_21626684,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_21626696 = ref object of OpenApiRestCall_21625418
proc url_DeleteApp_21626698(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApp_21626697(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626699 = path.getOrDefault("application-id")
  valid_21626699 = validateParameter(valid_21626699, JString, required = true,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "application-id", valid_21626699
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
  var valid_21626700 = header.getOrDefault("X-Amz-Date")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Date", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Security-Token", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Algorithm", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Signature")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Signature", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Credential")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Credential", valid_21626706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626707: Call_DeleteApp_21626696; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_21626707.validator(path, query, header, formData, body, _)
  let scheme = call_21626707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626707.makeUrl(scheme.get, call_21626707.host, call_21626707.base,
                               call_21626707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626707, uri, valid, _)

proc call*(call_21626708: Call_DeleteApp_21626696; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626709 = newJObject()
  add(path_21626709, "application-id", newJString(applicationId))
  result = call_21626708.call(path_21626709, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_21626696(name: "deleteApp",
                                      meth: HttpMethod.HttpDelete,
                                      host: "pinpoint.amazonaws.com",
                                      route: "/v1/apps/{application-id}",
                                      validator: validate_DeleteApp_21626697,
                                      base: "/", makeUrl: url_DeleteApp_21626698,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_21626724 = ref object of OpenApiRestCall_21625418
proc url_UpdateBaiduChannel_21626726(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBaiduChannel_21626725(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626727 = path.getOrDefault("application-id")
  valid_21626727 = validateParameter(valid_21626727, JString, required = true,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "application-id", valid_21626727
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
  var valid_21626728 = header.getOrDefault("X-Amz-Date")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Date", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Security-Token", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Algorithm", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-Signature")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Signature", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Credential")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Credential", valid_21626734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626736: Call_UpdateBaiduChannel_21626724; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_21626736.validator(path, query, header, formData, body, _)
  let scheme = call_21626736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626736.makeUrl(scheme.get, call_21626736.host, call_21626736.base,
                               call_21626736.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626736, uri, valid, _)

proc call*(call_21626737: Call_UpdateBaiduChannel_21626724; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626738 = newJObject()
  var body_21626739 = newJObject()
  add(path_21626738, "application-id", newJString(applicationId))
  if body != nil:
    body_21626739 = body
  result = call_21626737.call(path_21626738, nil, nil, nil, body_21626739)

var updateBaiduChannel* = Call_UpdateBaiduChannel_21626724(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_21626725, base: "/",
    makeUrl: url_UpdateBaiduChannel_21626726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_21626710 = ref object of OpenApiRestCall_21625418
proc url_GetBaiduChannel_21626712(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBaiduChannel_21626711(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626713 = path.getOrDefault("application-id")
  valid_21626713 = validateParameter(valid_21626713, JString, required = true,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "application-id", valid_21626713
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
  var valid_21626714 = header.getOrDefault("X-Amz-Date")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Date", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Security-Token", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Algorithm", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Signature")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Signature", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Credential")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Credential", valid_21626720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626721: Call_GetBaiduChannel_21626710; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_21626721.validator(path, query, header, formData, body, _)
  let scheme = call_21626721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626721.makeUrl(scheme.get, call_21626721.host, call_21626721.base,
                               call_21626721.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626721, uri, valid, _)

proc call*(call_21626722: Call_GetBaiduChannel_21626710; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626723 = newJObject()
  add(path_21626723, "application-id", newJString(applicationId))
  result = call_21626722.call(path_21626723, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_21626710(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_21626711, base: "/",
    makeUrl: url_GetBaiduChannel_21626712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_21626740 = ref object of OpenApiRestCall_21625418
proc url_DeleteBaiduChannel_21626742(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBaiduChannel_21626741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626743 = path.getOrDefault("application-id")
  valid_21626743 = validateParameter(valid_21626743, JString, required = true,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "application-id", valid_21626743
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
  var valid_21626744 = header.getOrDefault("X-Amz-Date")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Date", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Security-Token", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Algorithm", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Signature")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Signature", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Credential")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Credential", valid_21626750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626751: Call_DeleteBaiduChannel_21626740; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626751.validator(path, query, header, formData, body, _)
  let scheme = call_21626751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626751.makeUrl(scheme.get, call_21626751.host, call_21626751.base,
                               call_21626751.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626751, uri, valid, _)

proc call*(call_21626752: Call_DeleteBaiduChannel_21626740; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626753 = newJObject()
  add(path_21626753, "application-id", newJString(applicationId))
  result = call_21626752.call(path_21626753, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_21626740(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_21626741, base: "/",
    makeUrl: url_DeleteBaiduChannel_21626742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_21626769 = ref object of OpenApiRestCall_21625418
proc url_UpdateCampaign_21626771(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCampaign_21626770(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the configuration and other settings for a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626772 = path.getOrDefault("application-id")
  valid_21626772 = validateParameter(valid_21626772, JString, required = true,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "application-id", valid_21626772
  var valid_21626773 = path.getOrDefault("campaign-id")
  valid_21626773 = validateParameter(valid_21626773, JString, required = true,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "campaign-id", valid_21626773
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
  var valid_21626774 = header.getOrDefault("X-Amz-Date")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Date", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Security-Token", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-Algorithm", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Signature")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Signature", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Credential")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Credential", valid_21626780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626782: Call_UpdateCampaign_21626769; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_21626782.validator(path, query, header, formData, body, _)
  let scheme = call_21626782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626782.makeUrl(scheme.get, call_21626782.host, call_21626782.base,
                               call_21626782.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626782, uri, valid, _)

proc call*(call_21626783: Call_UpdateCampaign_21626769; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_21626784 = newJObject()
  var body_21626785 = newJObject()
  add(path_21626784, "application-id", newJString(applicationId))
  if body != nil:
    body_21626785 = body
  add(path_21626784, "campaign-id", newJString(campaignId))
  result = call_21626783.call(path_21626784, nil, nil, nil, body_21626785)

var updateCampaign* = Call_UpdateCampaign_21626769(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_21626770, base: "/",
    makeUrl: url_UpdateCampaign_21626771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_21626754 = ref object of OpenApiRestCall_21625418
proc url_GetCampaign_21626756(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaign_21626755(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626757 = path.getOrDefault("application-id")
  valid_21626757 = validateParameter(valid_21626757, JString, required = true,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "application-id", valid_21626757
  var valid_21626758 = path.getOrDefault("campaign-id")
  valid_21626758 = validateParameter(valid_21626758, JString, required = true,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "campaign-id", valid_21626758
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
  var valid_21626759 = header.getOrDefault("X-Amz-Date")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Date", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Security-Token", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Algorithm", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Signature")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Signature", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Credential")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Credential", valid_21626765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626766: Call_GetCampaign_21626754; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_21626766.validator(path, query, header, formData, body, _)
  let scheme = call_21626766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626766.makeUrl(scheme.get, call_21626766.host, call_21626766.base,
                               call_21626766.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626766, uri, valid, _)

proc call*(call_21626767: Call_GetCampaign_21626754; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_21626768 = newJObject()
  add(path_21626768, "application-id", newJString(applicationId))
  add(path_21626768, "campaign-id", newJString(campaignId))
  result = call_21626767.call(path_21626768, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_21626754(name: "getCampaign",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_GetCampaign_21626755, base: "/", makeUrl: url_GetCampaign_21626756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_21626786 = ref object of OpenApiRestCall_21625418
proc url_DeleteCampaign_21626788(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCampaign_21626787(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a campaign from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626789 = path.getOrDefault("application-id")
  valid_21626789 = validateParameter(valid_21626789, JString, required = true,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "application-id", valid_21626789
  var valid_21626790 = path.getOrDefault("campaign-id")
  valid_21626790 = validateParameter(valid_21626790, JString, required = true,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "campaign-id", valid_21626790
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
  var valid_21626791 = header.getOrDefault("X-Amz-Date")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Date", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Security-Token", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Algorithm", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Signature")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Signature", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Credential")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Credential", valid_21626797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626798: Call_DeleteCampaign_21626786; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_21626798.validator(path, query, header, formData, body, _)
  let scheme = call_21626798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626798.makeUrl(scheme.get, call_21626798.host, call_21626798.base,
                               call_21626798.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626798, uri, valid, _)

proc call*(call_21626799: Call_DeleteCampaign_21626786; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_21626800 = newJObject()
  add(path_21626800, "application-id", newJString(applicationId))
  add(path_21626800, "campaign-id", newJString(campaignId))
  result = call_21626799.call(path_21626800, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_21626786(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_21626787, base: "/",
    makeUrl: url_DeleteCampaign_21626788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_21626815 = ref object of OpenApiRestCall_21625418
proc url_UpdateEmailChannel_21626817(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEmailChannel_21626816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626818 = path.getOrDefault("application-id")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "application-id", valid_21626818
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
  var valid_21626819 = header.getOrDefault("X-Amz-Date")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Date", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Security-Token", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Algorithm", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Signature")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Signature", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Credential")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Credential", valid_21626825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626827: Call_UpdateEmailChannel_21626815; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_21626827.validator(path, query, header, formData, body, _)
  let scheme = call_21626827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626827.makeUrl(scheme.get, call_21626827.host, call_21626827.base,
                               call_21626827.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626827, uri, valid, _)

proc call*(call_21626828: Call_UpdateEmailChannel_21626815; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626829 = newJObject()
  var body_21626830 = newJObject()
  add(path_21626829, "application-id", newJString(applicationId))
  if body != nil:
    body_21626830 = body
  result = call_21626828.call(path_21626829, nil, nil, nil, body_21626830)

var updateEmailChannel* = Call_UpdateEmailChannel_21626815(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_21626816, base: "/",
    makeUrl: url_UpdateEmailChannel_21626817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_21626801 = ref object of OpenApiRestCall_21625418
proc url_GetEmailChannel_21626803(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailChannel_21626802(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626804 = path.getOrDefault("application-id")
  valid_21626804 = validateParameter(valid_21626804, JString, required = true,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "application-id", valid_21626804
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
  var valid_21626805 = header.getOrDefault("X-Amz-Date")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Date", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Security-Token", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Algorithm", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Signature")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Signature", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Credential")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Credential", valid_21626811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626812: Call_GetEmailChannel_21626801; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_21626812.validator(path, query, header, formData, body, _)
  let scheme = call_21626812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626812.makeUrl(scheme.get, call_21626812.host, call_21626812.base,
                               call_21626812.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626812, uri, valid, _)

proc call*(call_21626813: Call_GetEmailChannel_21626801; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626814 = newJObject()
  add(path_21626814, "application-id", newJString(applicationId))
  result = call_21626813.call(path_21626814, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_21626801(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_21626802, base: "/",
    makeUrl: url_GetEmailChannel_21626803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_21626831 = ref object of OpenApiRestCall_21625418
proc url_DeleteEmailChannel_21626833(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailChannel_21626832(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626834 = path.getOrDefault("application-id")
  valid_21626834 = validateParameter(valid_21626834, JString, required = true,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "application-id", valid_21626834
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
  var valid_21626835 = header.getOrDefault("X-Amz-Date")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Date", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Security-Token", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Algorithm", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Signature")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Signature", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Credential")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Credential", valid_21626841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626842: Call_DeleteEmailChannel_21626831; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626842.validator(path, query, header, formData, body, _)
  let scheme = call_21626842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626842.makeUrl(scheme.get, call_21626842.host, call_21626842.base,
                               call_21626842.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626842, uri, valid, _)

proc call*(call_21626843: Call_DeleteEmailChannel_21626831; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626844 = newJObject()
  add(path_21626844, "application-id", newJString(applicationId))
  result = call_21626843.call(path_21626844, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_21626831(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_21626832, base: "/",
    makeUrl: url_DeleteEmailChannel_21626833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_21626860 = ref object of OpenApiRestCall_21625418
proc url_UpdateEndpoint_21626862(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "endpoint-id" in path, "`endpoint-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/endpoints/"),
               (kind: VariableSegment, value: "endpoint-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEndpoint_21626861(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpoint-id: JString (required)
  ##              : The unique identifier for the endpoint.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626863 = path.getOrDefault("application-id")
  valid_21626863 = validateParameter(valid_21626863, JString, required = true,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "application-id", valid_21626863
  var valid_21626864 = path.getOrDefault("endpoint-id")
  valid_21626864 = validateParameter(valid_21626864, JString, required = true,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "endpoint-id", valid_21626864
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
  var valid_21626865 = header.getOrDefault("X-Amz-Date")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Date", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Security-Token", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Algorithm", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Signature")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Signature", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Credential")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Credential", valid_21626871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626873: Call_UpdateEndpoint_21626860; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_21626873.validator(path, query, header, formData, body, _)
  let scheme = call_21626873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626873.makeUrl(scheme.get, call_21626873.host, call_21626873.base,
                               call_21626873.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626873, uri, valid, _)

proc call*(call_21626874: Call_UpdateEndpoint_21626860; applicationId: string;
          endpointId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   body: JObject (required)
  var path_21626875 = newJObject()
  var body_21626876 = newJObject()
  add(path_21626875, "application-id", newJString(applicationId))
  add(path_21626875, "endpoint-id", newJString(endpointId))
  if body != nil:
    body_21626876 = body
  result = call_21626874.call(path_21626875, nil, nil, nil, body_21626876)

var updateEndpoint* = Call_UpdateEndpoint_21626860(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_21626861, base: "/",
    makeUrl: url_UpdateEndpoint_21626862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_21626845 = ref object of OpenApiRestCall_21625418
proc url_GetEndpoint_21626847(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "endpoint-id" in path, "`endpoint-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/endpoints/"),
               (kind: VariableSegment, value: "endpoint-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEndpoint_21626846(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpoint-id: JString (required)
  ##              : The unique identifier for the endpoint.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626848 = path.getOrDefault("application-id")
  valid_21626848 = validateParameter(valid_21626848, JString, required = true,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "application-id", valid_21626848
  var valid_21626849 = path.getOrDefault("endpoint-id")
  valid_21626849 = validateParameter(valid_21626849, JString, required = true,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "endpoint-id", valid_21626849
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
  var valid_21626850 = header.getOrDefault("X-Amz-Date")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Date", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-Security-Token", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Algorithm", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Signature")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Signature", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Credential")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Credential", valid_21626856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626857: Call_GetEndpoint_21626845; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_21626857.validator(path, query, header, formData, body, _)
  let scheme = call_21626857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626857.makeUrl(scheme.get, call_21626857.host, call_21626857.base,
                               call_21626857.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626857, uri, valid, _)

proc call*(call_21626858: Call_GetEndpoint_21626845; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_21626859 = newJObject()
  add(path_21626859, "application-id", newJString(applicationId))
  add(path_21626859, "endpoint-id", newJString(endpointId))
  result = call_21626858.call(path_21626859, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_21626845(name: "getEndpoint",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_GetEndpoint_21626846, base: "/", makeUrl: url_GetEndpoint_21626847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_21626877 = ref object of OpenApiRestCall_21625418
proc url_DeleteEndpoint_21626879(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "endpoint-id" in path, "`endpoint-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/endpoints/"),
               (kind: VariableSegment, value: "endpoint-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEndpoint_21626878(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an endpoint from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpoint-id: JString (required)
  ##              : The unique identifier for the endpoint.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626880 = path.getOrDefault("application-id")
  valid_21626880 = validateParameter(valid_21626880, JString, required = true,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "application-id", valid_21626880
  var valid_21626881 = path.getOrDefault("endpoint-id")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "endpoint-id", valid_21626881
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
  var valid_21626882 = header.getOrDefault("X-Amz-Date")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Date", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Security-Token", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Algorithm", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Signature")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Signature", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Credential")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Credential", valid_21626888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626889: Call_DeleteEndpoint_21626877; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_21626889.validator(path, query, header, formData, body, _)
  let scheme = call_21626889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626889.makeUrl(scheme.get, call_21626889.host, call_21626889.base,
                               call_21626889.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626889, uri, valid, _)

proc call*(call_21626890: Call_DeleteEndpoint_21626877; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_21626891 = newJObject()
  add(path_21626891, "application-id", newJString(applicationId))
  add(path_21626891, "endpoint-id", newJString(endpointId))
  result = call_21626890.call(path_21626891, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_21626877(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_21626878, base: "/",
    makeUrl: url_DeleteEndpoint_21626879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_21626906 = ref object of OpenApiRestCall_21625418
proc url_PutEventStream_21626908(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEventStream_21626907(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626909 = path.getOrDefault("application-id")
  valid_21626909 = validateParameter(valid_21626909, JString, required = true,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "application-id", valid_21626909
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
  var valid_21626910 = header.getOrDefault("X-Amz-Date")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Date", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Security-Token", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Algorithm", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Signature")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Signature", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Credential")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Credential", valid_21626916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626918: Call_PutEventStream_21626906; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_21626918.validator(path, query, header, formData, body, _)
  let scheme = call_21626918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626918.makeUrl(scheme.get, call_21626918.host, call_21626918.base,
                               call_21626918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626918, uri, valid, _)

proc call*(call_21626919: Call_PutEventStream_21626906; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626920 = newJObject()
  var body_21626921 = newJObject()
  add(path_21626920, "application-id", newJString(applicationId))
  if body != nil:
    body_21626921 = body
  result = call_21626919.call(path_21626920, nil, nil, nil, body_21626921)

var putEventStream* = Call_PutEventStream_21626906(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_21626907, base: "/",
    makeUrl: url_PutEventStream_21626908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_21626892 = ref object of OpenApiRestCall_21625418
proc url_GetEventStream_21626894(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventStream_21626893(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the event stream settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626895 = path.getOrDefault("application-id")
  valid_21626895 = validateParameter(valid_21626895, JString, required = true,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "application-id", valid_21626895
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
  var valid_21626896 = header.getOrDefault("X-Amz-Date")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Date", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Security-Token", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Algorithm", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Signature")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Signature", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Credential")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Credential", valid_21626902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626903: Call_GetEventStream_21626892; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_21626903.validator(path, query, header, formData, body, _)
  let scheme = call_21626903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626903.makeUrl(scheme.get, call_21626903.host, call_21626903.base,
                               call_21626903.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626903, uri, valid, _)

proc call*(call_21626904: Call_GetEventStream_21626892; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626905 = newJObject()
  add(path_21626905, "application-id", newJString(applicationId))
  result = call_21626904.call(path_21626905, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_21626892(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_21626893, base: "/",
    makeUrl: url_GetEventStream_21626894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_21626922 = ref object of OpenApiRestCall_21625418
proc url_DeleteEventStream_21626924(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventStream_21626923(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the event stream for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626925 = path.getOrDefault("application-id")
  valid_21626925 = validateParameter(valid_21626925, JString, required = true,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "application-id", valid_21626925
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
  var valid_21626926 = header.getOrDefault("X-Amz-Date")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Date", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Security-Token", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Algorithm", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Signature")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Signature", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Credential")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Credential", valid_21626932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626933: Call_DeleteEventStream_21626922; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_21626933.validator(path, query, header, formData, body, _)
  let scheme = call_21626933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626933.makeUrl(scheme.get, call_21626933.host, call_21626933.base,
                               call_21626933.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626933, uri, valid, _)

proc call*(call_21626934: Call_DeleteEventStream_21626922; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626935 = newJObject()
  add(path_21626935, "application-id", newJString(applicationId))
  result = call_21626934.call(path_21626935, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_21626922(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_21626923, base: "/",
    makeUrl: url_DeleteEventStream_21626924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_21626950 = ref object of OpenApiRestCall_21625418
proc url_UpdateGcmChannel_21626952(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGcmChannel_21626951(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626953 = path.getOrDefault("application-id")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "application-id", valid_21626953
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
  var valid_21626954 = header.getOrDefault("X-Amz-Date")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Date", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Security-Token", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Algorithm", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Signature")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Signature", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Credential")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Credential", valid_21626960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626962: Call_UpdateGcmChannel_21626950; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_21626962.validator(path, query, header, formData, body, _)
  let scheme = call_21626962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626962.makeUrl(scheme.get, call_21626962.host, call_21626962.base,
                               call_21626962.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626962, uri, valid, _)

proc call*(call_21626963: Call_UpdateGcmChannel_21626950; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21626964 = newJObject()
  var body_21626965 = newJObject()
  add(path_21626964, "application-id", newJString(applicationId))
  if body != nil:
    body_21626965 = body
  result = call_21626963.call(path_21626964, nil, nil, nil, body_21626965)

var updateGcmChannel* = Call_UpdateGcmChannel_21626950(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_21626951, base: "/",
    makeUrl: url_UpdateGcmChannel_21626952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_21626936 = ref object of OpenApiRestCall_21625418
proc url_GetGcmChannel_21626938(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGcmChannel_21626937(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626939 = path.getOrDefault("application-id")
  valid_21626939 = validateParameter(valid_21626939, JString, required = true,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "application-id", valid_21626939
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
  var valid_21626940 = header.getOrDefault("X-Amz-Date")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Date", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Security-Token", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Algorithm", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Signature")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Signature", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Credential")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Credential", valid_21626946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626947: Call_GetGcmChannel_21626936; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_21626947.validator(path, query, header, formData, body, _)
  let scheme = call_21626947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626947.makeUrl(scheme.get, call_21626947.host, call_21626947.base,
                               call_21626947.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626947, uri, valid, _)

proc call*(call_21626948: Call_GetGcmChannel_21626936; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626949 = newJObject()
  add(path_21626949, "application-id", newJString(applicationId))
  result = call_21626948.call(path_21626949, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_21626936(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_21626937, base: "/",
    makeUrl: url_GetGcmChannel_21626938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_21626966 = ref object of OpenApiRestCall_21625418
proc url_DeleteGcmChannel_21626968(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGcmChannel_21626967(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21626969 = path.getOrDefault("application-id")
  valid_21626969 = validateParameter(valid_21626969, JString, required = true,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "application-id", valid_21626969
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
  var valid_21626970 = header.getOrDefault("X-Amz-Date")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Date", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Security-Token", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Algorithm", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Signature")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Signature", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Credential")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Credential", valid_21626976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626977: Call_DeleteGcmChannel_21626966; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21626977.validator(path, query, header, formData, body, _)
  let scheme = call_21626977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626977.makeUrl(scheme.get, call_21626977.host, call_21626977.base,
                               call_21626977.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626977, uri, valid, _)

proc call*(call_21626978: Call_DeleteGcmChannel_21626966; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626979 = newJObject()
  add(path_21626979, "application-id", newJString(applicationId))
  result = call_21626978.call(path_21626979, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_21626966(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_21626967, base: "/",
    makeUrl: url_DeleteGcmChannel_21626968, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_21626995 = ref object of OpenApiRestCall_21625418
proc url_UpdateJourney_21626997(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJourney_21626996(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates the configuration and other settings for a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21626998 = path.getOrDefault("journey-id")
  valid_21626998 = validateParameter(valid_21626998, JString, required = true,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "journey-id", valid_21626998
  var valid_21626999 = path.getOrDefault("application-id")
  valid_21626999 = validateParameter(valid_21626999, JString, required = true,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "application-id", valid_21626999
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
  var valid_21627000 = header.getOrDefault("X-Amz-Date")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Date", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Security-Token", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Algorithm", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Signature")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Signature", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Credential")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Credential", valid_21627006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627008: Call_UpdateJourney_21626995; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_21627008.validator(path, query, header, formData, body, _)
  let scheme = call_21627008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627008.makeUrl(scheme.get, call_21627008.host, call_21627008.base,
                               call_21627008.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627008, uri, valid, _)

proc call*(call_21627009: Call_UpdateJourney_21626995; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627010 = newJObject()
  var body_21627011 = newJObject()
  add(path_21627010, "journey-id", newJString(journeyId))
  add(path_21627010, "application-id", newJString(applicationId))
  if body != nil:
    body_21627011 = body
  result = call_21627009.call(path_21627010, nil, nil, nil, body_21627011)

var updateJourney* = Call_UpdateJourney_21626995(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_21626996, base: "/",
    makeUrl: url_UpdateJourney_21626997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_21626980 = ref object of OpenApiRestCall_21625418
proc url_GetJourney_21626982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourney_21626981(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21626983 = path.getOrDefault("journey-id")
  valid_21626983 = validateParameter(valid_21626983, JString, required = true,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "journey-id", valid_21626983
  var valid_21626984 = path.getOrDefault("application-id")
  valid_21626984 = validateParameter(valid_21626984, JString, required = true,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "application-id", valid_21626984
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
  var valid_21626985 = header.getOrDefault("X-Amz-Date")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Date", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Security-Token", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Algorithm", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Signature")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Signature", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Credential")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Credential", valid_21626991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626992: Call_GetJourney_21626980; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_21626992.validator(path, query, header, formData, body, _)
  let scheme = call_21626992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626992.makeUrl(scheme.get, call_21626992.host, call_21626992.base,
                               call_21626992.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626992, uri, valid, _)

proc call*(call_21626993: Call_GetJourney_21626980; journeyId: string;
          applicationId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21626994 = newJObject()
  add(path_21626994, "journey-id", newJString(journeyId))
  add(path_21626994, "application-id", newJString(applicationId))
  result = call_21626993.call(path_21626994, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_21626980(name: "getJourney",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                        validator: validate_GetJourney_21626981,
                                        base: "/", makeUrl: url_GetJourney_21626982,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_21627012 = ref object of OpenApiRestCall_21625418
proc url_DeleteJourney_21627014(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJourney_21627013(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a journey from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21627015 = path.getOrDefault("journey-id")
  valid_21627015 = validateParameter(valid_21627015, JString, required = true,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "journey-id", valid_21627015
  var valid_21627016 = path.getOrDefault("application-id")
  valid_21627016 = validateParameter(valid_21627016, JString, required = true,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "application-id", valid_21627016
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
  var valid_21627017 = header.getOrDefault("X-Amz-Date")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Date", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Security-Token", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Algorithm", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Signature")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Signature", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Credential")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Credential", valid_21627023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627024: Call_DeleteJourney_21627012; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_21627024.validator(path, query, header, formData, body, _)
  let scheme = call_21627024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627024.makeUrl(scheme.get, call_21627024.host, call_21627024.base,
                               call_21627024.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627024, uri, valid, _)

proc call*(call_21627025: Call_DeleteJourney_21627012; journeyId: string;
          applicationId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627026 = newJObject()
  add(path_21627026, "journey-id", newJString(journeyId))
  add(path_21627026, "application-id", newJString(applicationId))
  result = call_21627025.call(path_21627026, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_21627012(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_21627013, base: "/",
    makeUrl: url_DeleteJourney_21627014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_21627042 = ref object of OpenApiRestCall_21625418
proc url_UpdateSegment_21627044(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSegment_21627043(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627045 = path.getOrDefault("segment-id")
  valid_21627045 = validateParameter(valid_21627045, JString, required = true,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "segment-id", valid_21627045
  var valid_21627046 = path.getOrDefault("application-id")
  valid_21627046 = validateParameter(valid_21627046, JString, required = true,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "application-id", valid_21627046
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
  var valid_21627047 = header.getOrDefault("X-Amz-Date")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-Date", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Security-Token", valid_21627048
  var valid_21627049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Algorithm", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Signature")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Signature", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Credential")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Credential", valid_21627053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627055: Call_UpdateSegment_21627042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_21627055.validator(path, query, header, formData, body, _)
  let scheme = call_21627055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627055.makeUrl(scheme.get, call_21627055.host, call_21627055.base,
                               call_21627055.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627055, uri, valid, _)

proc call*(call_21627056: Call_UpdateSegment_21627042; segmentId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627057 = newJObject()
  var body_21627058 = newJObject()
  add(path_21627057, "segment-id", newJString(segmentId))
  add(path_21627057, "application-id", newJString(applicationId))
  if body != nil:
    body_21627058 = body
  result = call_21627056.call(path_21627057, nil, nil, nil, body_21627058)

var updateSegment* = Call_UpdateSegment_21627042(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_21627043, base: "/",
    makeUrl: url_UpdateSegment_21627044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_21627027 = ref object of OpenApiRestCall_21625418
proc url_GetSegment_21627029(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegment_21627028(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627030 = path.getOrDefault("segment-id")
  valid_21627030 = validateParameter(valid_21627030, JString, required = true,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "segment-id", valid_21627030
  var valid_21627031 = path.getOrDefault("application-id")
  valid_21627031 = validateParameter(valid_21627031, JString, required = true,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "application-id", valid_21627031
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
  var valid_21627032 = header.getOrDefault("X-Amz-Date")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Date", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Security-Token", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Algorithm", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Signature")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Signature", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Credential")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Credential", valid_21627038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627039: Call_GetSegment_21627027; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_21627039.validator(path, query, header, formData, body, _)
  let scheme = call_21627039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627039.makeUrl(scheme.get, call_21627039.host, call_21627039.base,
                               call_21627039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627039, uri, valid, _)

proc call*(call_21627040: Call_GetSegment_21627027; segmentId: string;
          applicationId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627041 = newJObject()
  add(path_21627041, "segment-id", newJString(segmentId))
  add(path_21627041, "application-id", newJString(applicationId))
  result = call_21627040.call(path_21627041, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_21627027(name: "getSegment",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                        validator: validate_GetSegment_21627028,
                                        base: "/", makeUrl: url_GetSegment_21627029,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_21627059 = ref object of OpenApiRestCall_21625418
proc url_DeleteSegment_21627061(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSegment_21627060(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a segment from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627062 = path.getOrDefault("segment-id")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "segment-id", valid_21627062
  var valid_21627063 = path.getOrDefault("application-id")
  valid_21627063 = validateParameter(valid_21627063, JString, required = true,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "application-id", valid_21627063
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
  var valid_21627064 = header.getOrDefault("X-Amz-Date")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Date", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Security-Token", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Algorithm", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Signature")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Signature", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Credential")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Credential", valid_21627070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627071: Call_DeleteSegment_21627059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_21627071.validator(path, query, header, formData, body, _)
  let scheme = call_21627071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627071.makeUrl(scheme.get, call_21627071.host, call_21627071.base,
                               call_21627071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627071, uri, valid, _)

proc call*(call_21627072: Call_DeleteSegment_21627059; segmentId: string;
          applicationId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627073 = newJObject()
  add(path_21627073, "segment-id", newJString(segmentId))
  add(path_21627073, "application-id", newJString(applicationId))
  result = call_21627072.call(path_21627073, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_21627059(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_21627060, base: "/",
    makeUrl: url_DeleteSegment_21627061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_21627088 = ref object of OpenApiRestCall_21625418
proc url_UpdateSmsChannel_21627090(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSmsChannel_21627089(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627091 = path.getOrDefault("application-id")
  valid_21627091 = validateParameter(valid_21627091, JString, required = true,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "application-id", valid_21627091
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
  var valid_21627092 = header.getOrDefault("X-Amz-Date")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Date", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-Security-Token", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-Algorithm", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Signature")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Signature", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Credential")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Credential", valid_21627098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627100: Call_UpdateSmsChannel_21627088; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_21627100.validator(path, query, header, formData, body, _)
  let scheme = call_21627100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627100.makeUrl(scheme.get, call_21627100.host, call_21627100.base,
                               call_21627100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627100, uri, valid, _)

proc call*(call_21627101: Call_UpdateSmsChannel_21627088; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627102 = newJObject()
  var body_21627103 = newJObject()
  add(path_21627102, "application-id", newJString(applicationId))
  if body != nil:
    body_21627103 = body
  result = call_21627101.call(path_21627102, nil, nil, nil, body_21627103)

var updateSmsChannel* = Call_UpdateSmsChannel_21627088(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_21627089, base: "/",
    makeUrl: url_UpdateSmsChannel_21627090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_21627074 = ref object of OpenApiRestCall_21625418
proc url_GetSmsChannel_21627076(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSmsChannel_21627075(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627077 = path.getOrDefault("application-id")
  valid_21627077 = validateParameter(valid_21627077, JString, required = true,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "application-id", valid_21627077
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
  var valid_21627078 = header.getOrDefault("X-Amz-Date")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Date", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Security-Token", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Algorithm", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Signature")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Signature", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Credential")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Credential", valid_21627084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627085: Call_GetSmsChannel_21627074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_21627085.validator(path, query, header, formData, body, _)
  let scheme = call_21627085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627085.makeUrl(scheme.get, call_21627085.host, call_21627085.base,
                               call_21627085.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627085, uri, valid, _)

proc call*(call_21627086: Call_GetSmsChannel_21627074; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627087 = newJObject()
  add(path_21627087, "application-id", newJString(applicationId))
  result = call_21627086.call(path_21627087, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_21627074(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_21627075, base: "/",
    makeUrl: url_GetSmsChannel_21627076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_21627104 = ref object of OpenApiRestCall_21625418
proc url_DeleteSmsChannel_21627106(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSmsChannel_21627105(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627107 = path.getOrDefault("application-id")
  valid_21627107 = validateParameter(valid_21627107, JString, required = true,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "application-id", valid_21627107
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
  var valid_21627108 = header.getOrDefault("X-Amz-Date")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Date", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Security-Token", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-Algorithm", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Signature")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Signature", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Credential")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Credential", valid_21627114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627115: Call_DeleteSmsChannel_21627104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21627115.validator(path, query, header, formData, body, _)
  let scheme = call_21627115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627115.makeUrl(scheme.get, call_21627115.host, call_21627115.base,
                               call_21627115.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627115, uri, valid, _)

proc call*(call_21627116: Call_DeleteSmsChannel_21627104; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627117 = newJObject()
  add(path_21627117, "application-id", newJString(applicationId))
  result = call_21627116.call(path_21627117, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_21627104(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_21627105, base: "/",
    makeUrl: url_DeleteSmsChannel_21627106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_21627118 = ref object of OpenApiRestCall_21625418
proc url_GetUserEndpoints_21627120(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "user-id" in path, "`user-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "user-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUserEndpoints_21627119(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   user-id: JString (required)
  ##          : The unique identifier for the user.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `user-id` field"
  var valid_21627121 = path.getOrDefault("user-id")
  valid_21627121 = validateParameter(valid_21627121, JString, required = true,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "user-id", valid_21627121
  var valid_21627122 = path.getOrDefault("application-id")
  valid_21627122 = validateParameter(valid_21627122, JString, required = true,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "application-id", valid_21627122
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
  var valid_21627123 = header.getOrDefault("X-Amz-Date")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Date", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Security-Token", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-Algorithm", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Signature")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Signature", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Credential")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "X-Amz-Credential", valid_21627129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627130: Call_GetUserEndpoints_21627118; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_21627130.validator(path, query, header, formData, body, _)
  let scheme = call_21627130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627130.makeUrl(scheme.get, call_21627130.host, call_21627130.base,
                               call_21627130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627130, uri, valid, _)

proc call*(call_21627131: Call_GetUserEndpoints_21627118; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627132 = newJObject()
  add(path_21627132, "user-id", newJString(userId))
  add(path_21627132, "application-id", newJString(applicationId))
  result = call_21627131.call(path_21627132, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_21627118(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_21627119, base: "/",
    makeUrl: url_GetUserEndpoints_21627120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_21627133 = ref object of OpenApiRestCall_21625418
proc url_DeleteUserEndpoints_21627135(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "user-id" in path, "`user-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "user-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserEndpoints_21627134(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   user-id: JString (required)
  ##          : The unique identifier for the user.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `user-id` field"
  var valid_21627136 = path.getOrDefault("user-id")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "user-id", valid_21627136
  var valid_21627137 = path.getOrDefault("application-id")
  valid_21627137 = validateParameter(valid_21627137, JString, required = true,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "application-id", valid_21627137
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
  var valid_21627138 = header.getOrDefault("X-Amz-Date")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Date", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Security-Token", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Algorithm", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Signature")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Signature", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Credential")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Credential", valid_21627144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627145: Call_DeleteUserEndpoints_21627133; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_21627145.validator(path, query, header, formData, body, _)
  let scheme = call_21627145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627145.makeUrl(scheme.get, call_21627145.host, call_21627145.base,
                               call_21627145.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627145, uri, valid, _)

proc call*(call_21627146: Call_DeleteUserEndpoints_21627133; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627147 = newJObject()
  add(path_21627147, "user-id", newJString(userId))
  add(path_21627147, "application-id", newJString(applicationId))
  result = call_21627146.call(path_21627147, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_21627133(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_21627134, base: "/",
    makeUrl: url_DeleteUserEndpoints_21627135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_21627162 = ref object of OpenApiRestCall_21625418
proc url_UpdateVoiceChannel_21627164(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceChannel_21627163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627165 = path.getOrDefault("application-id")
  valid_21627165 = validateParameter(valid_21627165, JString, required = true,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "application-id", valid_21627165
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
  var valid_21627166 = header.getOrDefault("X-Amz-Date")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Date", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Security-Token", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Algorithm", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Signature")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Signature", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Credential")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Credential", valid_21627172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627174: Call_UpdateVoiceChannel_21627162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_21627174.validator(path, query, header, formData, body, _)
  let scheme = call_21627174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627174.makeUrl(scheme.get, call_21627174.host, call_21627174.base,
                               call_21627174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627174, uri, valid, _)

proc call*(call_21627175: Call_UpdateVoiceChannel_21627162; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627176 = newJObject()
  var body_21627177 = newJObject()
  add(path_21627176, "application-id", newJString(applicationId))
  if body != nil:
    body_21627177 = body
  result = call_21627175.call(path_21627176, nil, nil, nil, body_21627177)

var updateVoiceChannel* = Call_UpdateVoiceChannel_21627162(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_21627163, base: "/",
    makeUrl: url_UpdateVoiceChannel_21627164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_21627148 = ref object of OpenApiRestCall_21625418
proc url_GetVoiceChannel_21627150(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceChannel_21627149(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627151 = path.getOrDefault("application-id")
  valid_21627151 = validateParameter(valid_21627151, JString, required = true,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "application-id", valid_21627151
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
  var valid_21627152 = header.getOrDefault("X-Amz-Date")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Date", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Security-Token", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Algorithm", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Signature")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Signature", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Credential")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Credential", valid_21627158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627159: Call_GetVoiceChannel_21627148; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_21627159.validator(path, query, header, formData, body, _)
  let scheme = call_21627159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627159.makeUrl(scheme.get, call_21627159.host, call_21627159.base,
                               call_21627159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627159, uri, valid, _)

proc call*(call_21627160: Call_GetVoiceChannel_21627148; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627161 = newJObject()
  add(path_21627161, "application-id", newJString(applicationId))
  result = call_21627160.call(path_21627161, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_21627148(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_21627149, base: "/",
    makeUrl: url_GetVoiceChannel_21627150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_21627178 = ref object of OpenApiRestCall_21625418
proc url_DeleteVoiceChannel_21627180(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceChannel_21627179(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627181 = path.getOrDefault("application-id")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "application-id", valid_21627181
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
  var valid_21627182 = header.getOrDefault("X-Amz-Date")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-Date", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Security-Token", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Algorithm", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Signature")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Signature", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Credential")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Credential", valid_21627188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627189: Call_DeleteVoiceChannel_21627178; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_21627189.validator(path, query, header, formData, body, _)
  let scheme = call_21627189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627189.makeUrl(scheme.get, call_21627189.host, call_21627189.base,
                               call_21627189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627189, uri, valid, _)

proc call*(call_21627190: Call_DeleteVoiceChannel_21627178; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627191 = newJObject()
  add(path_21627191, "application-id", newJString(applicationId))
  result = call_21627190.call(path_21627191, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_21627178(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_21627179, base: "/",
    makeUrl: url_DeleteVoiceChannel_21627180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_21627192 = ref object of OpenApiRestCall_21625418
proc url_GetApplicationDateRangeKpi_21627194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "kpi-name" in path, "`kpi-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/kpis/daterange/"),
               (kind: VariableSegment, value: "kpi-name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplicationDateRangeKpi_21627193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627195 = path.getOrDefault("application-id")
  valid_21627195 = validateParameter(valid_21627195, JString, required = true,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "application-id", valid_21627195
  var valid_21627196 = path.getOrDefault("kpi-name")
  valid_21627196 = validateParameter(valid_21627196, JString, required = true,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "kpi-name", valid_21627196
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627197 = query.getOrDefault("end-time")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "end-time", valid_21627197
  var valid_21627198 = query.getOrDefault("start-time")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "start-time", valid_21627198
  var valid_21627199 = query.getOrDefault("next-token")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "next-token", valid_21627199
  var valid_21627200 = query.getOrDefault("page-size")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "page-size", valid_21627200
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
  var valid_21627201 = header.getOrDefault("X-Amz-Date")
  valid_21627201 = validateParameter(valid_21627201, JString, required = false,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "X-Amz-Date", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Security-Token", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Algorithm", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Signature")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-Signature", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Credential")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Credential", valid_21627207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627208: Call_GetApplicationDateRangeKpi_21627192;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_21627208.validator(path, query, header, formData, body, _)
  let scheme = call_21627208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627208.makeUrl(scheme.get, call_21627208.host, call_21627208.base,
                               call_21627208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627208, uri, valid, _)

proc call*(call_21627209: Call_GetApplicationDateRangeKpi_21627192;
          applicationId: string; kpiName: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getApplicationDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627210 = newJObject()
  var query_21627211 = newJObject()
  add(query_21627211, "end-time", newJString(endTime))
  add(path_21627210, "application-id", newJString(applicationId))
  add(path_21627210, "kpi-name", newJString(kpiName))
  add(query_21627211, "start-time", newJString(startTime))
  add(query_21627211, "next-token", newJString(nextToken))
  add(query_21627211, "page-size", newJString(pageSize))
  result = call_21627209.call(path_21627210, query_21627211, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_21627192(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_21627193, base: "/",
    makeUrl: url_GetApplicationDateRangeKpi_21627194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_21627226 = ref object of OpenApiRestCall_21625418
proc url_UpdateApplicationSettings_21627228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApplicationSettings_21627227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627229 = path.getOrDefault("application-id")
  valid_21627229 = validateParameter(valid_21627229, JString, required = true,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "application-id", valid_21627229
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
  var valid_21627230 = header.getOrDefault("X-Amz-Date")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Date", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Security-Token", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Algorithm", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Signature")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Signature", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Credential")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Credential", valid_21627236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627238: Call_UpdateApplicationSettings_21627226;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_21627238.validator(path, query, header, formData, body, _)
  let scheme = call_21627238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627238.makeUrl(scheme.get, call_21627238.host, call_21627238.base,
                               call_21627238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627238, uri, valid, _)

proc call*(call_21627239: Call_UpdateApplicationSettings_21627226;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627240 = newJObject()
  var body_21627241 = newJObject()
  add(path_21627240, "application-id", newJString(applicationId))
  if body != nil:
    body_21627241 = body
  result = call_21627239.call(path_21627240, nil, nil, nil, body_21627241)

var updateApplicationSettings* = Call_UpdateApplicationSettings_21627226(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_21627227, base: "/",
    makeUrl: url_UpdateApplicationSettings_21627228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_21627212 = ref object of OpenApiRestCall_21625418
proc url_GetApplicationSettings_21627214(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplicationSettings_21627213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627215 = path.getOrDefault("application-id")
  valid_21627215 = validateParameter(valid_21627215, JString, required = true,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "application-id", valid_21627215
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
  var valid_21627216 = header.getOrDefault("X-Amz-Date")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Date", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Security-Token", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Algorithm", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Signature")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Signature", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Credential")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Credential", valid_21627222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627223: Call_GetApplicationSettings_21627212;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_21627223.validator(path, query, header, formData, body, _)
  let scheme = call_21627223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627223.makeUrl(scheme.get, call_21627223.host, call_21627223.base,
                               call_21627223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627223, uri, valid, _)

proc call*(call_21627224: Call_GetApplicationSettings_21627212;
          applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627225 = newJObject()
  add(path_21627225, "application-id", newJString(applicationId))
  result = call_21627224.call(path_21627225, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_21627212(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_21627213, base: "/",
    makeUrl: url_GetApplicationSettings_21627214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_21627242 = ref object of OpenApiRestCall_21625418
proc url_GetCampaignActivities_21627244(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id"),
               (kind: ConstantSegment, value: "/activities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignActivities_21627243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about all the activities for a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627245 = path.getOrDefault("application-id")
  valid_21627245 = validateParameter(valid_21627245, JString, required = true,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "application-id", valid_21627245
  var valid_21627246 = path.getOrDefault("campaign-id")
  valid_21627246 = validateParameter(valid_21627246, JString, required = true,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "campaign-id", valid_21627246
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627247 = query.getOrDefault("token")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "token", valid_21627247
  var valid_21627248 = query.getOrDefault("page-size")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "page-size", valid_21627248
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
  var valid_21627249 = header.getOrDefault("X-Amz-Date")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "X-Amz-Date", valid_21627249
  var valid_21627250 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627250 = validateParameter(valid_21627250, JString, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "X-Amz-Security-Token", valid_21627250
  var valid_21627251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-Algorithm", valid_21627252
  var valid_21627253 = header.getOrDefault("X-Amz-Signature")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Signature", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Credential")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "X-Amz-Credential", valid_21627255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627256: Call_GetCampaignActivities_21627242;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_21627256.validator(path, query, header, formData, body, _)
  let scheme = call_21627256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627256.makeUrl(scheme.get, call_21627256.host, call_21627256.base,
                               call_21627256.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627256, uri, valid, _)

proc call*(call_21627257: Call_GetCampaignActivities_21627242;
          applicationId: string; campaignId: string; token: string = "";
          pageSize: string = ""): Recallable =
  ## getCampaignActivities
  ## Retrieves information about all the activities for a campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627258 = newJObject()
  var query_21627259 = newJObject()
  add(query_21627259, "token", newJString(token))
  add(path_21627258, "application-id", newJString(applicationId))
  add(path_21627258, "campaign-id", newJString(campaignId))
  add(query_21627259, "page-size", newJString(pageSize))
  result = call_21627257.call(path_21627258, query_21627259, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_21627242(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_21627243, base: "/",
    makeUrl: url_GetCampaignActivities_21627244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_21627260 = ref object of OpenApiRestCall_21625418
proc url_GetCampaignDateRangeKpi_21627262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  assert "kpi-name" in path, "`kpi-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id"),
               (kind: ConstantSegment, value: "/kpis/daterange/"),
               (kind: VariableSegment, value: "kpi-name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignDateRangeKpi_21627261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627263 = path.getOrDefault("application-id")
  valid_21627263 = validateParameter(valid_21627263, JString, required = true,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "application-id", valid_21627263
  var valid_21627264 = path.getOrDefault("kpi-name")
  valid_21627264 = validateParameter(valid_21627264, JString, required = true,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "kpi-name", valid_21627264
  var valid_21627265 = path.getOrDefault("campaign-id")
  valid_21627265 = validateParameter(valid_21627265, JString, required = true,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "campaign-id", valid_21627265
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627266 = query.getOrDefault("end-time")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "end-time", valid_21627266
  var valid_21627267 = query.getOrDefault("start-time")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "start-time", valid_21627267
  var valid_21627268 = query.getOrDefault("next-token")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "next-token", valid_21627268
  var valid_21627269 = query.getOrDefault("page-size")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "page-size", valid_21627269
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
  var valid_21627270 = header.getOrDefault("X-Amz-Date")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "X-Amz-Date", valid_21627270
  var valid_21627271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Security-Token", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Algorithm", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Signature")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Signature", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Credential")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Credential", valid_21627276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627277: Call_GetCampaignDateRangeKpi_21627260;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_21627277.validator(path, query, header, formData, body, _)
  let scheme = call_21627277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627277.makeUrl(scheme.get, call_21627277.host, call_21627277.base,
                               call_21627277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627277, uri, valid, _)

proc call*(call_21627278: Call_GetCampaignDateRangeKpi_21627260;
          applicationId: string; kpiName: string; campaignId: string;
          endTime: string = ""; startTime: string = ""; nextToken: string = "";
          pageSize: string = ""): Recallable =
  ## getCampaignDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627279 = newJObject()
  var query_21627280 = newJObject()
  add(query_21627280, "end-time", newJString(endTime))
  add(path_21627279, "application-id", newJString(applicationId))
  add(path_21627279, "kpi-name", newJString(kpiName))
  add(query_21627280, "start-time", newJString(startTime))
  add(query_21627280, "next-token", newJString(nextToken))
  add(path_21627279, "campaign-id", newJString(campaignId))
  add(query_21627280, "page-size", newJString(pageSize))
  result = call_21627278.call(path_21627279, query_21627280, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_21627260(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_21627261, base: "/",
    makeUrl: url_GetCampaignDateRangeKpi_21627262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_21627281 = ref object of OpenApiRestCall_21625418
proc url_GetCampaignVersion_21627283(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignVersion_21627282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_21627284 = path.getOrDefault("version")
  valid_21627284 = validateParameter(valid_21627284, JString, required = true,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "version", valid_21627284
  var valid_21627285 = path.getOrDefault("application-id")
  valid_21627285 = validateParameter(valid_21627285, JString, required = true,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "application-id", valid_21627285
  var valid_21627286 = path.getOrDefault("campaign-id")
  valid_21627286 = validateParameter(valid_21627286, JString, required = true,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "campaign-id", valid_21627286
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
  var valid_21627287 = header.getOrDefault("X-Amz-Date")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "X-Amz-Date", valid_21627287
  var valid_21627288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "X-Amz-Security-Token", valid_21627288
  var valid_21627289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627289 = validateParameter(valid_21627289, JString, required = false,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Algorithm", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Signature")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Signature", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Credential")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Credential", valid_21627293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627294: Call_GetCampaignVersion_21627281; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_21627294.validator(path, query, header, formData, body, _)
  let scheme = call_21627294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627294.makeUrl(scheme.get, call_21627294.host, call_21627294.base,
                               call_21627294.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627294, uri, valid, _)

proc call*(call_21627295: Call_GetCampaignVersion_21627281; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_21627296 = newJObject()
  add(path_21627296, "version", newJString(version))
  add(path_21627296, "application-id", newJString(applicationId))
  add(path_21627296, "campaign-id", newJString(campaignId))
  result = call_21627295.call(path_21627296, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_21627281(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_21627282, base: "/",
    makeUrl: url_GetCampaignVersion_21627283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_21627297 = ref object of OpenApiRestCall_21625418
proc url_GetCampaignVersions_21627299(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "campaign-id" in path, "`campaign-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns/"),
               (kind: VariableSegment, value: "campaign-id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignVersions_21627298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627300 = path.getOrDefault("application-id")
  valid_21627300 = validateParameter(valid_21627300, JString, required = true,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "application-id", valid_21627300
  var valid_21627301 = path.getOrDefault("campaign-id")
  valid_21627301 = validateParameter(valid_21627301, JString, required = true,
                                   default = nil)
  if valid_21627301 != nil:
    section.add "campaign-id", valid_21627301
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627302 = query.getOrDefault("token")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "token", valid_21627302
  var valid_21627303 = query.getOrDefault("page-size")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "page-size", valid_21627303
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
  var valid_21627304 = header.getOrDefault("X-Amz-Date")
  valid_21627304 = validateParameter(valid_21627304, JString, required = false,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "X-Amz-Date", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Security-Token", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Algorithm", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Signature")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Signature", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Credential")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Credential", valid_21627310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627311: Call_GetCampaignVersions_21627297; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_21627311.validator(path, query, header, formData, body, _)
  let scheme = call_21627311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627311.makeUrl(scheme.get, call_21627311.host, call_21627311.base,
                               call_21627311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627311, uri, valid, _)

proc call*(call_21627312: Call_GetCampaignVersions_21627297; applicationId: string;
          campaignId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaignVersions
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627313 = newJObject()
  var query_21627314 = newJObject()
  add(query_21627314, "token", newJString(token))
  add(path_21627313, "application-id", newJString(applicationId))
  add(path_21627313, "campaign-id", newJString(campaignId))
  add(query_21627314, "page-size", newJString(pageSize))
  result = call_21627312.call(path_21627313, query_21627314, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_21627297(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_21627298, base: "/",
    makeUrl: url_GetCampaignVersions_21627299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_21627315 = ref object of OpenApiRestCall_21625418
proc url_GetChannels_21627317(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChannels_21627316(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627318 = path.getOrDefault("application-id")
  valid_21627318 = validateParameter(valid_21627318, JString, required = true,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "application-id", valid_21627318
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
  var valid_21627319 = header.getOrDefault("X-Amz-Date")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Date", valid_21627319
  var valid_21627320 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Security-Token", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-Algorithm", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Signature")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Signature", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Credential")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Credential", valid_21627325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627326: Call_GetChannels_21627315; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_21627326.validator(path, query, header, formData, body, _)
  let scheme = call_21627326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627326.makeUrl(scheme.get, call_21627326.host, call_21627326.base,
                               call_21627326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627326, uri, valid, _)

proc call*(call_21627327: Call_GetChannels_21627315; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627328 = newJObject()
  add(path_21627328, "application-id", newJString(applicationId))
  result = call_21627327.call(path_21627328, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_21627315(name: "getChannels",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels", validator: validate_GetChannels_21627316,
    base: "/", makeUrl: url_GetChannels_21627317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_21627329 = ref object of OpenApiRestCall_21625418
proc url_GetExportJob_21627331(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "job-id" in path, "`job-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/export/"),
               (kind: VariableSegment, value: "job-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExportJob_21627330(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   job-id: JString (required)
  ##         : The unique identifier for the job.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627332 = path.getOrDefault("application-id")
  valid_21627332 = validateParameter(valid_21627332, JString, required = true,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "application-id", valid_21627332
  var valid_21627333 = path.getOrDefault("job-id")
  valid_21627333 = validateParameter(valid_21627333, JString, required = true,
                                   default = nil)
  if valid_21627333 != nil:
    section.add "job-id", valid_21627333
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
  var valid_21627334 = header.getOrDefault("X-Amz-Date")
  valid_21627334 = validateParameter(valid_21627334, JString, required = false,
                                   default = nil)
  if valid_21627334 != nil:
    section.add "X-Amz-Date", valid_21627334
  var valid_21627335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "X-Amz-Security-Token", valid_21627335
  var valid_21627336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627336
  var valid_21627337 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627337 = validateParameter(valid_21627337, JString, required = false,
                                   default = nil)
  if valid_21627337 != nil:
    section.add "X-Amz-Algorithm", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Signature")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Signature", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Credential")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-Credential", valid_21627340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627341: Call_GetExportJob_21627329; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_21627341.validator(path, query, header, formData, body, _)
  let scheme = call_21627341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627341.makeUrl(scheme.get, call_21627341.host, call_21627341.base,
                               call_21627341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627341, uri, valid, _)

proc call*(call_21627342: Call_GetExportJob_21627329; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_21627343 = newJObject()
  add(path_21627343, "application-id", newJString(applicationId))
  add(path_21627343, "job-id", newJString(jobId))
  result = call_21627342.call(path_21627343, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_21627329(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_21627330, base: "/", makeUrl: url_GetExportJob_21627331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_21627344 = ref object of OpenApiRestCall_21625418
proc url_GetImportJob_21627346(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "job-id" in path, "`job-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/import/"),
               (kind: VariableSegment, value: "job-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImportJob_21627345(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   job-id: JString (required)
  ##         : The unique identifier for the job.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627347 = path.getOrDefault("application-id")
  valid_21627347 = validateParameter(valid_21627347, JString, required = true,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "application-id", valid_21627347
  var valid_21627348 = path.getOrDefault("job-id")
  valid_21627348 = validateParameter(valid_21627348, JString, required = true,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "job-id", valid_21627348
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
  var valid_21627349 = header.getOrDefault("X-Amz-Date")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-Date", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Security-Token", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Algorithm", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Signature")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Signature", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Credential")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Credential", valid_21627355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627356: Call_GetImportJob_21627344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_21627356.validator(path, query, header, formData, body, _)
  let scheme = call_21627356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627356.makeUrl(scheme.get, call_21627356.host, call_21627356.base,
                               call_21627356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627356, uri, valid, _)

proc call*(call_21627357: Call_GetImportJob_21627344; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_21627358 = newJObject()
  add(path_21627358, "application-id", newJString(applicationId))
  add(path_21627358, "job-id", newJString(jobId))
  result = call_21627357.call(path_21627358, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_21627344(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_21627345, base: "/", makeUrl: url_GetImportJob_21627346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_21627359 = ref object of OpenApiRestCall_21625418
proc url_GetJourneyDateRangeKpi_21627361(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  assert "kpi-name" in path, "`kpi-name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id"),
               (kind: ConstantSegment, value: "/kpis/daterange/"),
               (kind: VariableSegment, value: "kpi-name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyDateRangeKpi_21627360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21627362 = path.getOrDefault("journey-id")
  valid_21627362 = validateParameter(valid_21627362, JString, required = true,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "journey-id", valid_21627362
  var valid_21627363 = path.getOrDefault("application-id")
  valid_21627363 = validateParameter(valid_21627363, JString, required = true,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "application-id", valid_21627363
  var valid_21627364 = path.getOrDefault("kpi-name")
  valid_21627364 = validateParameter(valid_21627364, JString, required = true,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "kpi-name", valid_21627364
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627365 = query.getOrDefault("end-time")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "end-time", valid_21627365
  var valid_21627366 = query.getOrDefault("start-time")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "start-time", valid_21627366
  var valid_21627367 = query.getOrDefault("next-token")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "next-token", valid_21627367
  var valid_21627368 = query.getOrDefault("page-size")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "page-size", valid_21627368
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
  var valid_21627369 = header.getOrDefault("X-Amz-Date")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Date", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-Security-Token", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Algorithm", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-Signature")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-Signature", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Credential")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Credential", valid_21627375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627376: Call_GetJourneyDateRangeKpi_21627359;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_21627376.validator(path, query, header, formData, body, _)
  let scheme = call_21627376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627376.makeUrl(scheme.get, call_21627376.host, call_21627376.base,
                               call_21627376.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627376, uri, valid, _)

proc call*(call_21627377: Call_GetJourneyDateRangeKpi_21627359; journeyId: string;
          applicationId: string; kpiName: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getJourneyDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627378 = newJObject()
  var query_21627379 = newJObject()
  add(path_21627378, "journey-id", newJString(journeyId))
  add(query_21627379, "end-time", newJString(endTime))
  add(path_21627378, "application-id", newJString(applicationId))
  add(path_21627378, "kpi-name", newJString(kpiName))
  add(query_21627379, "start-time", newJString(startTime))
  add(query_21627379, "next-token", newJString(nextToken))
  add(query_21627379, "page-size", newJString(pageSize))
  result = call_21627377.call(path_21627378, query_21627379, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_21627359(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_21627360, base: "/",
    makeUrl: url_GetJourneyDateRangeKpi_21627361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_21627380 = ref object of OpenApiRestCall_21625418
proc url_GetJourneyExecutionActivityMetrics_21627382(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  assert "journey-activity-id" in path,
        "`journey-activity-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id"),
               (kind: ConstantSegment, value: "/activities/"),
               (kind: VariableSegment, value: "journey-activity-id"),
               (kind: ConstantSegment, value: "/execution-metrics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyExecutionActivityMetrics_21627381(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-activity-id: JString (required)
  ##                      : The unique identifier for the journey activity.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21627383 = path.getOrDefault("journey-id")
  valid_21627383 = validateParameter(valid_21627383, JString, required = true,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "journey-id", valid_21627383
  var valid_21627384 = path.getOrDefault("application-id")
  valid_21627384 = validateParameter(valid_21627384, JString, required = true,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "application-id", valid_21627384
  var valid_21627385 = path.getOrDefault("journey-activity-id")
  valid_21627385 = validateParameter(valid_21627385, JString, required = true,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "journey-activity-id", valid_21627385
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627386 = query.getOrDefault("next-token")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "next-token", valid_21627386
  var valid_21627387 = query.getOrDefault("page-size")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "page-size", valid_21627387
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
  var valid_21627388 = header.getOrDefault("X-Amz-Date")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Date", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Security-Token", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627390
  var valid_21627391 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-Algorithm", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Signature")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Signature", valid_21627392
  var valid_21627393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627393 = validateParameter(valid_21627393, JString, required = false,
                                   default = nil)
  if valid_21627393 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627393
  var valid_21627394 = header.getOrDefault("X-Amz-Credential")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "X-Amz-Credential", valid_21627394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627395: Call_GetJourneyExecutionActivityMetrics_21627380;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_21627395.validator(path, query, header, formData, body, _)
  let scheme = call_21627395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627395.makeUrl(scheme.get, call_21627395.host, call_21627395.base,
                               call_21627395.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627395, uri, valid, _)

proc call*(call_21627396: Call_GetJourneyExecutionActivityMetrics_21627380;
          journeyId: string; applicationId: string; journeyActivityId: string;
          nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getJourneyExecutionActivityMetrics
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyActivityId: string (required)
  ##                    : The unique identifier for the journey activity.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627397 = newJObject()
  var query_21627398 = newJObject()
  add(path_21627397, "journey-id", newJString(journeyId))
  add(path_21627397, "application-id", newJString(applicationId))
  add(path_21627397, "journey-activity-id", newJString(journeyActivityId))
  add(query_21627398, "next-token", newJString(nextToken))
  add(query_21627398, "page-size", newJString(pageSize))
  result = call_21627396.call(path_21627397, query_21627398, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_21627380(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_21627381, base: "/",
    makeUrl: url_GetJourneyExecutionActivityMetrics_21627382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_21627399 = ref object of OpenApiRestCall_21625418
proc url_GetJourneyExecutionMetrics_21627401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id"),
               (kind: ConstantSegment, value: "/execution-metrics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyExecutionMetrics_21627400(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21627402 = path.getOrDefault("journey-id")
  valid_21627402 = validateParameter(valid_21627402, JString, required = true,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "journey-id", valid_21627402
  var valid_21627403 = path.getOrDefault("application-id")
  valid_21627403 = validateParameter(valid_21627403, JString, required = true,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "application-id", valid_21627403
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627404 = query.getOrDefault("next-token")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "next-token", valid_21627404
  var valid_21627405 = query.getOrDefault("page-size")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "page-size", valid_21627405
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
  var valid_21627406 = header.getOrDefault("X-Amz-Date")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-Date", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Security-Token", valid_21627407
  var valid_21627408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627408
  var valid_21627409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = nil)
  if valid_21627409 != nil:
    section.add "X-Amz-Algorithm", valid_21627409
  var valid_21627410 = header.getOrDefault("X-Amz-Signature")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "X-Amz-Signature", valid_21627410
  var valid_21627411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627411
  var valid_21627412 = header.getOrDefault("X-Amz-Credential")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "X-Amz-Credential", valid_21627412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627413: Call_GetJourneyExecutionMetrics_21627399;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_21627413.validator(path, query, header, formData, body, _)
  let scheme = call_21627413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627413.makeUrl(scheme.get, call_21627413.host, call_21627413.base,
                               call_21627413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627413, uri, valid, _)

proc call*(call_21627414: Call_GetJourneyExecutionMetrics_21627399;
          journeyId: string; applicationId: string; nextToken: string = "";
          pageSize: string = ""): Recallable =
  ## getJourneyExecutionMetrics
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627415 = newJObject()
  var query_21627416 = newJObject()
  add(path_21627415, "journey-id", newJString(journeyId))
  add(path_21627415, "application-id", newJString(applicationId))
  add(query_21627416, "next-token", newJString(nextToken))
  add(query_21627416, "page-size", newJString(pageSize))
  result = call_21627414.call(path_21627415, query_21627416, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_21627399(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_21627400, base: "/",
    makeUrl: url_GetJourneyExecutionMetrics_21627401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_21627417 = ref object of OpenApiRestCall_21625418
proc url_GetSegmentExportJobs_21627419(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id"),
               (kind: ConstantSegment, value: "/jobs/export")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentExportJobs_21627418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627420 = path.getOrDefault("segment-id")
  valid_21627420 = validateParameter(valid_21627420, JString, required = true,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "segment-id", valid_21627420
  var valid_21627421 = path.getOrDefault("application-id")
  valid_21627421 = validateParameter(valid_21627421, JString, required = true,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "application-id", valid_21627421
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627422 = query.getOrDefault("token")
  valid_21627422 = validateParameter(valid_21627422, JString, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "token", valid_21627422
  var valid_21627423 = query.getOrDefault("page-size")
  valid_21627423 = validateParameter(valid_21627423, JString, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "page-size", valid_21627423
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
  var valid_21627424 = header.getOrDefault("X-Amz-Date")
  valid_21627424 = validateParameter(valid_21627424, JString, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "X-Amz-Date", valid_21627424
  var valid_21627425 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Security-Token", valid_21627425
  var valid_21627426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627426
  var valid_21627427 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-Algorithm", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Signature")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Signature", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Credential")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-Credential", valid_21627430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627431: Call_GetSegmentExportJobs_21627417; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_21627431.validator(path, query, header, formData, body, _)
  let scheme = call_21627431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627431.makeUrl(scheme.get, call_21627431.host, call_21627431.base,
                               call_21627431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627431, uri, valid, _)

proc call*(call_21627432: Call_GetSegmentExportJobs_21627417; segmentId: string;
          applicationId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentExportJobs
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627433 = newJObject()
  var query_21627434 = newJObject()
  add(query_21627434, "token", newJString(token))
  add(path_21627433, "segment-id", newJString(segmentId))
  add(path_21627433, "application-id", newJString(applicationId))
  add(query_21627434, "page-size", newJString(pageSize))
  result = call_21627432.call(path_21627433, query_21627434, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_21627417(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_21627418, base: "/",
    makeUrl: url_GetSegmentExportJobs_21627419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_21627435 = ref object of OpenApiRestCall_21625418
proc url_GetSegmentImportJobs_21627437(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id"),
               (kind: ConstantSegment, value: "/jobs/import")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentImportJobs_21627436(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627438 = path.getOrDefault("segment-id")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true,
                                   default = nil)
  if valid_21627438 != nil:
    section.add "segment-id", valid_21627438
  var valid_21627439 = path.getOrDefault("application-id")
  valid_21627439 = validateParameter(valid_21627439, JString, required = true,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "application-id", valid_21627439
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627440 = query.getOrDefault("token")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "token", valid_21627440
  var valid_21627441 = query.getOrDefault("page-size")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "page-size", valid_21627441
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
  var valid_21627442 = header.getOrDefault("X-Amz-Date")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Date", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Security-Token", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Algorithm", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Signature")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Signature", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-Credential")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-Credential", valid_21627448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627449: Call_GetSegmentImportJobs_21627435; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_21627449.validator(path, query, header, formData, body, _)
  let scheme = call_21627449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627449.makeUrl(scheme.get, call_21627449.host, call_21627449.base,
                               call_21627449.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627449, uri, valid, _)

proc call*(call_21627450: Call_GetSegmentImportJobs_21627435; segmentId: string;
          applicationId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentImportJobs
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627451 = newJObject()
  var query_21627452 = newJObject()
  add(query_21627452, "token", newJString(token))
  add(path_21627451, "segment-id", newJString(segmentId))
  add(path_21627451, "application-id", newJString(applicationId))
  add(query_21627452, "page-size", newJString(pageSize))
  result = call_21627450.call(path_21627451, query_21627452, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_21627435(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_21627436, base: "/",
    makeUrl: url_GetSegmentImportJobs_21627437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_21627453 = ref object of OpenApiRestCall_21625418
proc url_GetSegmentVersion_21627455(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentVersion_21627454(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   version: JString (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627456 = path.getOrDefault("segment-id")
  valid_21627456 = validateParameter(valid_21627456, JString, required = true,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "segment-id", valid_21627456
  var valid_21627457 = path.getOrDefault("version")
  valid_21627457 = validateParameter(valid_21627457, JString, required = true,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "version", valid_21627457
  var valid_21627458 = path.getOrDefault("application-id")
  valid_21627458 = validateParameter(valid_21627458, JString, required = true,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "application-id", valid_21627458
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
  var valid_21627459 = header.getOrDefault("X-Amz-Date")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Date", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Security-Token", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Algorithm", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Signature")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Signature", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Credential")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Credential", valid_21627465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627466: Call_GetSegmentVersion_21627453; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_21627466.validator(path, query, header, formData, body, _)
  let scheme = call_21627466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627466.makeUrl(scheme.get, call_21627466.host, call_21627466.base,
                               call_21627466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627466, uri, valid, _)

proc call*(call_21627467: Call_GetSegmentVersion_21627453; segmentId: string;
          version: string; applicationId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_21627468 = newJObject()
  add(path_21627468, "segment-id", newJString(segmentId))
  add(path_21627468, "version", newJString(version))
  add(path_21627468, "application-id", newJString(applicationId))
  result = call_21627467.call(path_21627468, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_21627453(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_21627454, base: "/",
    makeUrl: url_GetSegmentVersion_21627455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_21627469 = ref object of OpenApiRestCall_21625418
proc url_GetSegmentVersions_21627471(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "segment-id" in path, "`segment-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments/"),
               (kind: VariableSegment, value: "segment-id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentVersions_21627470(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `segment-id` field"
  var valid_21627472 = path.getOrDefault("segment-id")
  valid_21627472 = validateParameter(valid_21627472, JString, required = true,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "segment-id", valid_21627472
  var valid_21627473 = path.getOrDefault("application-id")
  valid_21627473 = validateParameter(valid_21627473, JString, required = true,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "application-id", valid_21627473
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627474 = query.getOrDefault("token")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "token", valid_21627474
  var valid_21627475 = query.getOrDefault("page-size")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "page-size", valid_21627475
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
  var valid_21627476 = header.getOrDefault("X-Amz-Date")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Date", valid_21627476
  var valid_21627477 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Security-Token", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-Algorithm", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Signature")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Signature", valid_21627480
  var valid_21627481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627481 = validateParameter(valid_21627481, JString, required = false,
                                   default = nil)
  if valid_21627481 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627481
  var valid_21627482 = header.getOrDefault("X-Amz-Credential")
  valid_21627482 = validateParameter(valid_21627482, JString, required = false,
                                   default = nil)
  if valid_21627482 != nil:
    section.add "X-Amz-Credential", valid_21627482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627483: Call_GetSegmentVersions_21627469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_21627483.validator(path, query, header, formData, body, _)
  let scheme = call_21627483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627483.makeUrl(scheme.get, call_21627483.host, call_21627483.base,
                               call_21627483.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627483, uri, valid, _)

proc call*(call_21627484: Call_GetSegmentVersions_21627469; segmentId: string;
          applicationId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627485 = newJObject()
  var query_21627486 = newJObject()
  add(query_21627486, "token", newJString(token))
  add(path_21627485, "segment-id", newJString(segmentId))
  add(path_21627485, "application-id", newJString(applicationId))
  add(query_21627486, "page-size", newJString(pageSize))
  result = call_21627484.call(path_21627485, query_21627486, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_21627469(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_21627470, base: "/",
    makeUrl: url_GetSegmentVersions_21627471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627501 = ref object of OpenApiRestCall_21625418
proc url_TagResource_21627503(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21627502(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627504 = path.getOrDefault("resource-arn")
  valid_21627504 = validateParameter(valid_21627504, JString, required = true,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "resource-arn", valid_21627504
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
  var valid_21627505 = header.getOrDefault("X-Amz-Date")
  valid_21627505 = validateParameter(valid_21627505, JString, required = false,
                                   default = nil)
  if valid_21627505 != nil:
    section.add "X-Amz-Date", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Security-Token", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Algorithm", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-Signature")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-Signature", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627510
  var valid_21627511 = header.getOrDefault("X-Amz-Credential")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-Credential", valid_21627511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627513: Call_TagResource_21627501; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_21627513.validator(path, query, header, formData, body, _)
  let scheme = call_21627513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627513.makeUrl(scheme.get, call_21627513.host, call_21627513.base,
                               call_21627513.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627513, uri, valid, _)

proc call*(call_21627514: Call_TagResource_21627501; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_21627515 = newJObject()
  var body_21627516 = newJObject()
  add(path_21627515, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21627516 = body
  result = call_21627514.call(path_21627515, nil, nil, nil, body_21627516)

var tagResource* = Call_TagResource_21627501(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}", validator: validate_TagResource_21627502,
    base: "/", makeUrl: url_TagResource_21627503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21627487 = ref object of OpenApiRestCall_21625418
proc url_ListTagsForResource_21627489(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21627488(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627490 = path.getOrDefault("resource-arn")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "resource-arn", valid_21627490
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
  var valid_21627491 = header.getOrDefault("X-Amz-Date")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Date", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Security-Token", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-Algorithm", valid_21627494
  var valid_21627495 = header.getOrDefault("X-Amz-Signature")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Signature", valid_21627495
  var valid_21627496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627496 = validateParameter(valid_21627496, JString, required = false,
                                   default = nil)
  if valid_21627496 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627496
  var valid_21627497 = header.getOrDefault("X-Amz-Credential")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-Credential", valid_21627497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627498: Call_ListTagsForResource_21627487; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_21627498.validator(path, query, header, formData, body, _)
  let scheme = call_21627498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627498.makeUrl(scheme.get, call_21627498.host, call_21627498.base,
                               call_21627498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627498, uri, valid, _)

proc call*(call_21627499: Call_ListTagsForResource_21627487; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21627500 = newJObject()
  add(path_21627500, "resource-arn", newJString(resourceArn))
  result = call_21627499.call(path_21627500, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21627487(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21627488, base: "/",
    makeUrl: url_ListTagsForResource_21627489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_21627517 = ref object of OpenApiRestCall_21625418
proc url_ListTemplateVersions_21627519(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  assert "template-type" in path, "`template-type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "template-type"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateVersions_21627518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-type: JString (required)
  ##                : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-type` field"
  var valid_21627520 = path.getOrDefault("template-type")
  valid_21627520 = validateParameter(valid_21627520, JString, required = true,
                                   default = nil)
  if valid_21627520 != nil:
    section.add "template-type", valid_21627520
  var valid_21627521 = path.getOrDefault("template-name")
  valid_21627521 = validateParameter(valid_21627521, JString, required = true,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "template-name", valid_21627521
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627522 = query.getOrDefault("next-token")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "next-token", valid_21627522
  var valid_21627523 = query.getOrDefault("page-size")
  valid_21627523 = validateParameter(valid_21627523, JString, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "page-size", valid_21627523
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
  var valid_21627524 = header.getOrDefault("X-Amz-Date")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "X-Amz-Date", valid_21627524
  var valid_21627525 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627525 = validateParameter(valid_21627525, JString, required = false,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "X-Amz-Security-Token", valid_21627525
  var valid_21627526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627526 = validateParameter(valid_21627526, JString, required = false,
                                   default = nil)
  if valid_21627526 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627526
  var valid_21627527 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627527 = validateParameter(valid_21627527, JString, required = false,
                                   default = nil)
  if valid_21627527 != nil:
    section.add "X-Amz-Algorithm", valid_21627527
  var valid_21627528 = header.getOrDefault("X-Amz-Signature")
  valid_21627528 = validateParameter(valid_21627528, JString, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "X-Amz-Signature", valid_21627528
  var valid_21627529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627529 = validateParameter(valid_21627529, JString, required = false,
                                   default = nil)
  if valid_21627529 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627529
  var valid_21627530 = header.getOrDefault("X-Amz-Credential")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "X-Amz-Credential", valid_21627530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627531: Call_ListTemplateVersions_21627517; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_21627531.validator(path, query, header, formData, body, _)
  let scheme = call_21627531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627531.makeUrl(scheme.get, call_21627531.host, call_21627531.base,
                               call_21627531.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627531, uri, valid, _)

proc call*(call_21627532: Call_ListTemplateVersions_21627517; templateType: string;
          templateName: string; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## listTemplateVersions
  ## Retrieves information about all the versions of a specific message template.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_21627533 = newJObject()
  var query_21627534 = newJObject()
  add(path_21627533, "template-type", newJString(templateType))
  add(path_21627533, "template-name", newJString(templateName))
  add(query_21627534, "next-token", newJString(nextToken))
  add(query_21627534, "page-size", newJString(pageSize))
  result = call_21627532.call(path_21627533, query_21627534, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_21627517(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_21627518, base: "/",
    makeUrl: url_ListTemplateVersions_21627519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_21627535 = ref object of OpenApiRestCall_21625418
proc url_ListTemplates_21627537(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTemplates_21627536(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   template-type: JString
  ##                : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   prefix: JString
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_21627538 = query.getOrDefault("template-type")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "template-type", valid_21627538
  var valid_21627539 = query.getOrDefault("next-token")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "next-token", valid_21627539
  var valid_21627540 = query.getOrDefault("prefix")
  valid_21627540 = validateParameter(valid_21627540, JString, required = false,
                                   default = nil)
  if valid_21627540 != nil:
    section.add "prefix", valid_21627540
  var valid_21627541 = query.getOrDefault("page-size")
  valid_21627541 = validateParameter(valid_21627541, JString, required = false,
                                   default = nil)
  if valid_21627541 != nil:
    section.add "page-size", valid_21627541
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
  var valid_21627542 = header.getOrDefault("X-Amz-Date")
  valid_21627542 = validateParameter(valid_21627542, JString, required = false,
                                   default = nil)
  if valid_21627542 != nil:
    section.add "X-Amz-Date", valid_21627542
  var valid_21627543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627543 = validateParameter(valid_21627543, JString, required = false,
                                   default = nil)
  if valid_21627543 != nil:
    section.add "X-Amz-Security-Token", valid_21627543
  var valid_21627544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627544 = validateParameter(valid_21627544, JString, required = false,
                                   default = nil)
  if valid_21627544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627544
  var valid_21627545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Algorithm", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-Signature")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-Signature", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-Credential")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Credential", valid_21627548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627549: Call_ListTemplates_21627535; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_21627549.validator(path, query, header, formData, body, _)
  let scheme = call_21627549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627549.makeUrl(scheme.get, call_21627549.host, call_21627549.base,
                               call_21627549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627549, uri, valid, _)

proc call*(call_21627550: Call_ListTemplates_21627535; templateType: string = "";
          nextToken: string = ""; prefix: string = ""; pageSize: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_21627551 = newJObject()
  add(query_21627551, "template-type", newJString(templateType))
  add(query_21627551, "next-token", newJString(nextToken))
  add(query_21627551, "prefix", newJString(prefix))
  add(query_21627551, "page-size", newJString(pageSize))
  result = call_21627550.call(nil, query_21627551, nil, nil, nil)

var listTemplates* = Call_ListTemplates_21627535(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_21627536, base: "/",
    makeUrl: url_ListTemplates_21627537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_21627552 = ref object of OpenApiRestCall_21625418
proc url_PhoneNumberValidate_21627554(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PhoneNumberValidate_21627553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a phone number.
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
  var valid_21627555 = header.getOrDefault("X-Amz-Date")
  valid_21627555 = validateParameter(valid_21627555, JString, required = false,
                                   default = nil)
  if valid_21627555 != nil:
    section.add "X-Amz-Date", valid_21627555
  var valid_21627556 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627556 = validateParameter(valid_21627556, JString, required = false,
                                   default = nil)
  if valid_21627556 != nil:
    section.add "X-Amz-Security-Token", valid_21627556
  var valid_21627557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627557 = validateParameter(valid_21627557, JString, required = false,
                                   default = nil)
  if valid_21627557 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627557
  var valid_21627558 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627558 = validateParameter(valid_21627558, JString, required = false,
                                   default = nil)
  if valid_21627558 != nil:
    section.add "X-Amz-Algorithm", valid_21627558
  var valid_21627559 = header.getOrDefault("X-Amz-Signature")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "X-Amz-Signature", valid_21627559
  var valid_21627560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627560 = validateParameter(valid_21627560, JString, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627560
  var valid_21627561 = header.getOrDefault("X-Amz-Credential")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "X-Amz-Credential", valid_21627561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627563: Call_PhoneNumberValidate_21627552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_21627563.validator(path, query, header, formData, body, _)
  let scheme = call_21627563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627563.makeUrl(scheme.get, call_21627563.host, call_21627563.base,
                               call_21627563.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627563, uri, valid, _)

proc call*(call_21627564: Call_PhoneNumberValidate_21627552; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_21627565 = newJObject()
  if body != nil:
    body_21627565 = body
  result = call_21627564.call(nil, nil, nil, nil, body_21627565)

var phoneNumberValidate* = Call_PhoneNumberValidate_21627552(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_21627553, base: "/",
    makeUrl: url_PhoneNumberValidate_21627554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_21627566 = ref object of OpenApiRestCall_21625418
proc url_PutEvents_21627568(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEvents_21627567(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627569 = path.getOrDefault("application-id")
  valid_21627569 = validateParameter(valid_21627569, JString, required = true,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "application-id", valid_21627569
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
  var valid_21627570 = header.getOrDefault("X-Amz-Date")
  valid_21627570 = validateParameter(valid_21627570, JString, required = false,
                                   default = nil)
  if valid_21627570 != nil:
    section.add "X-Amz-Date", valid_21627570
  var valid_21627571 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627571 = validateParameter(valid_21627571, JString, required = false,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "X-Amz-Security-Token", valid_21627571
  var valid_21627572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627572 = validateParameter(valid_21627572, JString, required = false,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627572
  var valid_21627573 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627573 = validateParameter(valid_21627573, JString, required = false,
                                   default = nil)
  if valid_21627573 != nil:
    section.add "X-Amz-Algorithm", valid_21627573
  var valid_21627574 = header.getOrDefault("X-Amz-Signature")
  valid_21627574 = validateParameter(valid_21627574, JString, required = false,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "X-Amz-Signature", valid_21627574
  var valid_21627575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627575 = validateParameter(valid_21627575, JString, required = false,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627575
  var valid_21627576 = header.getOrDefault("X-Amz-Credential")
  valid_21627576 = validateParameter(valid_21627576, JString, required = false,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "X-Amz-Credential", valid_21627576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627578: Call_PutEvents_21627566; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_21627578.validator(path, query, header, formData, body, _)
  let scheme = call_21627578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627578.makeUrl(scheme.get, call_21627578.host, call_21627578.base,
                               call_21627578.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627578, uri, valid, _)

proc call*(call_21627579: Call_PutEvents_21627566; applicationId: string;
          body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627580 = newJObject()
  var body_21627581 = newJObject()
  add(path_21627580, "application-id", newJString(applicationId))
  if body != nil:
    body_21627581 = body
  result = call_21627579.call(path_21627580, nil, nil, nil, body_21627581)

var putEvents* = Call_PutEvents_21627566(name: "putEvents",
                                      meth: HttpMethod.HttpPost,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/events",
                                      validator: validate_PutEvents_21627567,
                                      base: "/", makeUrl: url_PutEvents_21627568,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_21627582 = ref object of OpenApiRestCall_21625418
proc url_RemoveAttributes_21627584(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "attribute-type" in path, "`attribute-type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/attributes/"),
               (kind: VariableSegment, value: "attribute-type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveAttributes_21627583(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   attribute-type: JString (required)
  ##                 :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `attribute-type` field"
  var valid_21627585 = path.getOrDefault("attribute-type")
  valid_21627585 = validateParameter(valid_21627585, JString, required = true,
                                   default = nil)
  if valid_21627585 != nil:
    section.add "attribute-type", valid_21627585
  var valid_21627586 = path.getOrDefault("application-id")
  valid_21627586 = validateParameter(valid_21627586, JString, required = true,
                                   default = nil)
  if valid_21627586 != nil:
    section.add "application-id", valid_21627586
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
  var valid_21627587 = header.getOrDefault("X-Amz-Date")
  valid_21627587 = validateParameter(valid_21627587, JString, required = false,
                                   default = nil)
  if valid_21627587 != nil:
    section.add "X-Amz-Date", valid_21627587
  var valid_21627588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627588 = validateParameter(valid_21627588, JString, required = false,
                                   default = nil)
  if valid_21627588 != nil:
    section.add "X-Amz-Security-Token", valid_21627588
  var valid_21627589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627589 = validateParameter(valid_21627589, JString, required = false,
                                   default = nil)
  if valid_21627589 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627589
  var valid_21627590 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627590 = validateParameter(valid_21627590, JString, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "X-Amz-Algorithm", valid_21627590
  var valid_21627591 = header.getOrDefault("X-Amz-Signature")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "X-Amz-Signature", valid_21627591
  var valid_21627592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627592 = validateParameter(valid_21627592, JString, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Credential")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Credential", valid_21627593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627595: Call_RemoveAttributes_21627582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_21627595.validator(path, query, header, formData, body, _)
  let scheme = call_21627595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627595.makeUrl(scheme.get, call_21627595.host, call_21627595.base,
                               call_21627595.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627595, uri, valid, _)

proc call*(call_21627596: Call_RemoveAttributes_21627582; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627597 = newJObject()
  var body_21627598 = newJObject()
  add(path_21627597, "attribute-type", newJString(attributeType))
  add(path_21627597, "application-id", newJString(applicationId))
  if body != nil:
    body_21627598 = body
  result = call_21627596.call(path_21627597, nil, nil, nil, body_21627598)

var removeAttributes* = Call_RemoveAttributes_21627582(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_21627583, base: "/",
    makeUrl: url_RemoveAttributes_21627584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_21627599 = ref object of OpenApiRestCall_21625418
proc url_SendMessages_21627601(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/messages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SendMessages_21627600(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates and sends a direct message.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627602 = path.getOrDefault("application-id")
  valid_21627602 = validateParameter(valid_21627602, JString, required = true,
                                   default = nil)
  if valid_21627602 != nil:
    section.add "application-id", valid_21627602
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
  var valid_21627603 = header.getOrDefault("X-Amz-Date")
  valid_21627603 = validateParameter(valid_21627603, JString, required = false,
                                   default = nil)
  if valid_21627603 != nil:
    section.add "X-Amz-Date", valid_21627603
  var valid_21627604 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627604 = validateParameter(valid_21627604, JString, required = false,
                                   default = nil)
  if valid_21627604 != nil:
    section.add "X-Amz-Security-Token", valid_21627604
  var valid_21627605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627605 = validateParameter(valid_21627605, JString, required = false,
                                   default = nil)
  if valid_21627605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627605
  var valid_21627606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627606 = validateParameter(valid_21627606, JString, required = false,
                                   default = nil)
  if valid_21627606 != nil:
    section.add "X-Amz-Algorithm", valid_21627606
  var valid_21627607 = header.getOrDefault("X-Amz-Signature")
  valid_21627607 = validateParameter(valid_21627607, JString, required = false,
                                   default = nil)
  if valid_21627607 != nil:
    section.add "X-Amz-Signature", valid_21627607
  var valid_21627608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-Credential")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "X-Amz-Credential", valid_21627609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627611: Call_SendMessages_21627599; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_21627611.validator(path, query, header, formData, body, _)
  let scheme = call_21627611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627611.makeUrl(scheme.get, call_21627611.host, call_21627611.base,
                               call_21627611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627611, uri, valid, _)

proc call*(call_21627612: Call_SendMessages_21627599; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627613 = newJObject()
  var body_21627614 = newJObject()
  add(path_21627613, "application-id", newJString(applicationId))
  if body != nil:
    body_21627614 = body
  result = call_21627612.call(path_21627613, nil, nil, nil, body_21627614)

var sendMessages* = Call_SendMessages_21627599(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_21627600,
    base: "/", makeUrl: url_SendMessages_21627601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_21627615 = ref object of OpenApiRestCall_21625418
proc url_SendUsersMessages_21627617(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/users-messages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SendUsersMessages_21627616(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates and sends a message to a list of users.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627618 = path.getOrDefault("application-id")
  valid_21627618 = validateParameter(valid_21627618, JString, required = true,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "application-id", valid_21627618
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
  var valid_21627619 = header.getOrDefault("X-Amz-Date")
  valid_21627619 = validateParameter(valid_21627619, JString, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "X-Amz-Date", valid_21627619
  var valid_21627620 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "X-Amz-Security-Token", valid_21627620
  var valid_21627621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627621 = validateParameter(valid_21627621, JString, required = false,
                                   default = nil)
  if valid_21627621 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627621
  var valid_21627622 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627622 = validateParameter(valid_21627622, JString, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "X-Amz-Algorithm", valid_21627622
  var valid_21627623 = header.getOrDefault("X-Amz-Signature")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-Signature", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Credential")
  valid_21627625 = validateParameter(valid_21627625, JString, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "X-Amz-Credential", valid_21627625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627627: Call_SendUsersMessages_21627615; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_21627627.validator(path, query, header, formData, body, _)
  let scheme = call_21627627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627627.makeUrl(scheme.get, call_21627627.host, call_21627627.base,
                               call_21627627.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627627, uri, valid, _)

proc call*(call_21627628: Call_SendUsersMessages_21627615; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627629 = newJObject()
  var body_21627630 = newJObject()
  add(path_21627629, "application-id", newJString(applicationId))
  if body != nil:
    body_21627630 = body
  result = call_21627628.call(path_21627629, nil, nil, nil, body_21627630)

var sendUsersMessages* = Call_SendUsersMessages_21627615(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_21627616, base: "/",
    makeUrl: url_SendUsersMessages_21627617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627631 = ref object of OpenApiRestCall_21625418
proc url_UntagResource_21627633(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21627632(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627634 = path.getOrDefault("resource-arn")
  valid_21627634 = validateParameter(valid_21627634, JString, required = true,
                                   default = nil)
  if valid_21627634 != nil:
    section.add "resource-arn", valid_21627634
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21627635 = query.getOrDefault("tagKeys")
  valid_21627635 = validateParameter(valid_21627635, JArray, required = true,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "tagKeys", valid_21627635
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
  var valid_21627636 = header.getOrDefault("X-Amz-Date")
  valid_21627636 = validateParameter(valid_21627636, JString, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "X-Amz-Date", valid_21627636
  var valid_21627637 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627637 = validateParameter(valid_21627637, JString, required = false,
                                   default = nil)
  if valid_21627637 != nil:
    section.add "X-Amz-Security-Token", valid_21627637
  var valid_21627638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Algorithm", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Signature")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-Signature", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Credential")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Credential", valid_21627642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627643: Call_UntagResource_21627631; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_21627643.validator(path, query, header, formData, body, _)
  let scheme = call_21627643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627643.makeUrl(scheme.get, call_21627643.host, call_21627643.base,
                               call_21627643.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627643, uri, valid, _)

proc call*(call_21627644: Call_UntagResource_21627631; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21627645 = newJObject()
  var query_21627646 = newJObject()
  if tagKeys != nil:
    query_21627646.add "tagKeys", tagKeys
  add(path_21627645, "resource-arn", newJString(resourceArn))
  result = call_21627644.call(path_21627645, query_21627646, nil, nil, nil)

var untagResource* = Call_UntagResource_21627631(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21627632,
    base: "/", makeUrl: url_UntagResource_21627633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_21627647 = ref object of OpenApiRestCall_21625418
proc url_UpdateEndpointsBatch_21627649(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/endpoints")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEndpointsBatch_21627648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_21627650 = path.getOrDefault("application-id")
  valid_21627650 = validateParameter(valid_21627650, JString, required = true,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "application-id", valid_21627650
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
  var valid_21627651 = header.getOrDefault("X-Amz-Date")
  valid_21627651 = validateParameter(valid_21627651, JString, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "X-Amz-Date", valid_21627651
  var valid_21627652 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627652 = validateParameter(valid_21627652, JString, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "X-Amz-Security-Token", valid_21627652
  var valid_21627653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Algorithm", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-Signature")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-Signature", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627656
  var valid_21627657 = header.getOrDefault("X-Amz-Credential")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "X-Amz-Credential", valid_21627657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627659: Call_UpdateEndpointsBatch_21627647; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_21627659.validator(path, query, header, formData, body, _)
  let scheme = call_21627659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627659.makeUrl(scheme.get, call_21627659.host, call_21627659.base,
                               call_21627659.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627659, uri, valid, _)

proc call*(call_21627660: Call_UpdateEndpointsBatch_21627647;
          applicationId: string; body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627661 = newJObject()
  var body_21627662 = newJObject()
  add(path_21627661, "application-id", newJString(applicationId))
  if body != nil:
    body_21627662 = body
  result = call_21627660.call(path_21627661, nil, nil, nil, body_21627662)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_21627647(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_21627648, base: "/",
    makeUrl: url_UpdateEndpointsBatch_21627649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_21627663 = ref object of OpenApiRestCall_21625418
proc url_UpdateJourneyState_21627665(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  assert "journey-id" in path, "`journey-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/journeys/"),
               (kind: VariableSegment, value: "journey-id"),
               (kind: ConstantSegment, value: "/state")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJourneyState_21627664(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels (stops) an active journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `journey-id` field"
  var valid_21627666 = path.getOrDefault("journey-id")
  valid_21627666 = validateParameter(valid_21627666, JString, required = true,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "journey-id", valid_21627666
  var valid_21627667 = path.getOrDefault("application-id")
  valid_21627667 = validateParameter(valid_21627667, JString, required = true,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "application-id", valid_21627667
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
  var valid_21627668 = header.getOrDefault("X-Amz-Date")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Date", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Security-Token", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Algorithm", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Signature")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Signature", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Credential")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Credential", valid_21627674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627676: Call_UpdateJourneyState_21627663; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_21627676.validator(path, query, header, formData, body, _)
  let scheme = call_21627676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627676.makeUrl(scheme.get, call_21627676.host, call_21627676.base,
                               call_21627676.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627676, uri, valid, _)

proc call*(call_21627677: Call_UpdateJourneyState_21627663; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_21627678 = newJObject()
  var body_21627679 = newJObject()
  add(path_21627678, "journey-id", newJString(journeyId))
  add(path_21627678, "application-id", newJString(applicationId))
  if body != nil:
    body_21627679 = body
  result = call_21627677.call(path_21627678, nil, nil, nil, body_21627679)

var updateJourneyState* = Call_UpdateJourneyState_21627663(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_21627664, base: "/",
    makeUrl: url_UpdateJourneyState_21627665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_21627680 = ref object of OpenApiRestCall_21625418
proc url_UpdateTemplateActiveVersion_21627682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "template-name" in path, "`template-name` is a required path parameter"
  assert "template-type" in path, "`template-type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/templates/"),
               (kind: VariableSegment, value: "template-name"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "template-type"),
               (kind: ConstantSegment, value: "/active-version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateActiveVersion_21627681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-type: JString (required)
  ##                : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-type` field"
  var valid_21627683 = path.getOrDefault("template-type")
  valid_21627683 = validateParameter(valid_21627683, JString, required = true,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "template-type", valid_21627683
  var valid_21627684 = path.getOrDefault("template-name")
  valid_21627684 = validateParameter(valid_21627684, JString, required = true,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "template-name", valid_21627684
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
  var valid_21627685 = header.getOrDefault("X-Amz-Date")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Date", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Security-Token", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Algorithm", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Signature")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Signature", valid_21627689
  var valid_21627690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627690
  var valid_21627691 = header.getOrDefault("X-Amz-Credential")
  valid_21627691 = validateParameter(valid_21627691, JString, required = false,
                                   default = nil)
  if valid_21627691 != nil:
    section.add "X-Amz-Credential", valid_21627691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627693: Call_UpdateTemplateActiveVersion_21627680;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_21627693.validator(path, query, header, formData, body, _)
  let scheme = call_21627693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627693.makeUrl(scheme.get, call_21627693.host, call_21627693.base,
                               call_21627693.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627693, uri, valid, _)

proc call*(call_21627694: Call_UpdateTemplateActiveVersion_21627680;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_21627695 = newJObject()
  var body_21627696 = newJObject()
  add(path_21627695, "template-type", newJString(templateType))
  add(path_21627695, "template-name", newJString(templateName))
  if body != nil:
    body_21627696 = body
  result = call_21627694.call(path_21627695, nil, nil, nil, body_21627696)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_21627680(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_21627681, base: "/",
    makeUrl: url_UpdateTemplateActiveVersion_21627682,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}