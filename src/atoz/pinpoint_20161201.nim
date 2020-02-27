
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616850 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616850](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616850): Option[Scheme] {.used.} =
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
                           "us-east-1": "pinpoint.us-east-1.amazonaws.com", "cn-northwest-1": "pinpoint.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "pinpoint.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "pinpoint.ap-south-1.amazonaws.com",
                           "eu-north-1": "pinpoint.eu-north-1.amazonaws.com",
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
      "ap-northeast-2": "pinpoint.ap-northeast-2.amazonaws.com",
      "ap-south-1": "pinpoint.ap-south-1.amazonaws.com",
      "eu-north-1": "pinpoint.eu-north-1.amazonaws.com",
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
  Call_CreateApp_617449 = ref object of OpenApiRestCall_616850
proc url_CreateApp_617451(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_617450(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617452 = header.getOrDefault("X-Amz-Date")
  valid_617452 = validateParameter(valid_617452, JString, required = false,
                                 default = nil)
  if valid_617452 != nil:
    section.add "X-Amz-Date", valid_617452
  var valid_617453 = header.getOrDefault("X-Amz-Security-Token")
  valid_617453 = validateParameter(valid_617453, JString, required = false,
                                 default = nil)
  if valid_617453 != nil:
    section.add "X-Amz-Security-Token", valid_617453
  var valid_617454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617454 = validateParameter(valid_617454, JString, required = false,
                                 default = nil)
  if valid_617454 != nil:
    section.add "X-Amz-Content-Sha256", valid_617454
  var valid_617455 = header.getOrDefault("X-Amz-Algorithm")
  valid_617455 = validateParameter(valid_617455, JString, required = false,
                                 default = nil)
  if valid_617455 != nil:
    section.add "X-Amz-Algorithm", valid_617455
  var valid_617456 = header.getOrDefault("X-Amz-Signature")
  valid_617456 = validateParameter(valid_617456, JString, required = false,
                                 default = nil)
  if valid_617456 != nil:
    section.add "X-Amz-Signature", valid_617456
  var valid_617457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617457 = validateParameter(valid_617457, JString, required = false,
                                 default = nil)
  if valid_617457 != nil:
    section.add "X-Amz-SignedHeaders", valid_617457
  var valid_617458 = header.getOrDefault("X-Amz-Credential")
  valid_617458 = validateParameter(valid_617458, JString, required = false,
                                 default = nil)
  if valid_617458 != nil:
    section.add "X-Amz-Credential", valid_617458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617460: Call_CreateApp_617449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_617460.validator(path, query, header, formData, body, _)
  let scheme = call_617460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617460.url(scheme.get, call_617460.host, call_617460.base,
                         call_617460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617460, url, valid, _)

proc call*(call_617461: Call_CreateApp_617449; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_617462 = newJObject()
  if body != nil:
    body_617462 = body
  result = call_617461.call(nil, nil, nil, nil, body_617462)

var createApp* = Call_CreateApp_617449(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_617450,
                                    base: "/", url: url_CreateApp_617451,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_617189 = ref object of OpenApiRestCall_616850
proc url_GetApps_617191(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApps_617190(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617303 = query.getOrDefault("token")
  valid_617303 = validateParameter(valid_617303, JString, required = false,
                                 default = nil)
  if valid_617303 != nil:
    section.add "token", valid_617303
  var valid_617304 = query.getOrDefault("page-size")
  valid_617304 = validateParameter(valid_617304, JString, required = false,
                                 default = nil)
  if valid_617304 != nil:
    section.add "page-size", valid_617304
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
  var valid_617305 = header.getOrDefault("X-Amz-Date")
  valid_617305 = validateParameter(valid_617305, JString, required = false,
                                 default = nil)
  if valid_617305 != nil:
    section.add "X-Amz-Date", valid_617305
  var valid_617306 = header.getOrDefault("X-Amz-Security-Token")
  valid_617306 = validateParameter(valid_617306, JString, required = false,
                                 default = nil)
  if valid_617306 != nil:
    section.add "X-Amz-Security-Token", valid_617306
  var valid_617307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617307 = validateParameter(valid_617307, JString, required = false,
                                 default = nil)
  if valid_617307 != nil:
    section.add "X-Amz-Content-Sha256", valid_617307
  var valid_617308 = header.getOrDefault("X-Amz-Algorithm")
  valid_617308 = validateParameter(valid_617308, JString, required = false,
                                 default = nil)
  if valid_617308 != nil:
    section.add "X-Amz-Algorithm", valid_617308
  var valid_617309 = header.getOrDefault("X-Amz-Signature")
  valid_617309 = validateParameter(valid_617309, JString, required = false,
                                 default = nil)
  if valid_617309 != nil:
    section.add "X-Amz-Signature", valid_617309
  var valid_617310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617310 = validateParameter(valid_617310, JString, required = false,
                                 default = nil)
  if valid_617310 != nil:
    section.add "X-Amz-SignedHeaders", valid_617310
  var valid_617311 = header.getOrDefault("X-Amz-Credential")
  valid_617311 = validateParameter(valid_617311, JString, required = false,
                                 default = nil)
  if valid_617311 != nil:
    section.add "X-Amz-Credential", valid_617311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617335: Call_GetApps_617189; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_617335.validator(path, query, header, formData, body, _)
  let scheme = call_617335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617335.url(scheme.get, call_617335.host, call_617335.base,
                         call_617335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617335, url, valid, _)

proc call*(call_617406: Call_GetApps_617189; token: string = ""; pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_617407 = newJObject()
  add(query_617407, "token", newJString(token))
  add(query_617407, "page-size", newJString(pageSize))
  result = call_617406.call(nil, query_617407, nil, nil, nil)

var getApps* = Call_GetApps_617189(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_617190, base: "/",
                                url: url_GetApps_617191,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_617494 = ref object of OpenApiRestCall_616850
proc url_CreateCampaign_617496(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_617495(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617497 = path.getOrDefault("application-id")
  valid_617497 = validateParameter(valid_617497, JString, required = true,
                                 default = nil)
  if valid_617497 != nil:
    section.add "application-id", valid_617497
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
  var valid_617498 = header.getOrDefault("X-Amz-Date")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Date", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Security-Token")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Security-Token", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-Content-Sha256", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Algorithm")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "X-Amz-Algorithm", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Signature")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Signature", valid_617502
  var valid_617503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-SignedHeaders", valid_617503
  var valid_617504 = header.getOrDefault("X-Amz-Credential")
  valid_617504 = validateParameter(valid_617504, JString, required = false,
                                 default = nil)
  if valid_617504 != nil:
    section.add "X-Amz-Credential", valid_617504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617506: Call_CreateCampaign_617494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_617506.validator(path, query, header, formData, body, _)
  let scheme = call_617506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617506.url(scheme.get, call_617506.host, call_617506.base,
                         call_617506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617506, url, valid, _)

proc call*(call_617507: Call_CreateCampaign_617494; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617508 = newJObject()
  var body_617509 = newJObject()
  add(path_617508, "application-id", newJString(applicationId))
  if body != nil:
    body_617509 = body
  result = call_617507.call(path_617508, nil, nil, nil, body_617509)

var createCampaign* = Call_CreateCampaign_617494(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_617495, base: "/", url: url_CreateCampaign_617496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_617463 = ref object of OpenApiRestCall_616850
proc url_GetCampaigns_617465(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_617464(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617480 = path.getOrDefault("application-id")
  valid_617480 = validateParameter(valid_617480, JString, required = true,
                                 default = nil)
  if valid_617480 != nil:
    section.add "application-id", valid_617480
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_617481 = query.getOrDefault("token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "token", valid_617481
  var valid_617482 = query.getOrDefault("page-size")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "page-size", valid_617482
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
  var valid_617483 = header.getOrDefault("X-Amz-Date")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Date", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Security-Token")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Security-Token", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-Content-Sha256", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Algorithm")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "X-Amz-Algorithm", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Signature")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Signature", valid_617487
  var valid_617488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617488 = validateParameter(valid_617488, JString, required = false,
                                 default = nil)
  if valid_617488 != nil:
    section.add "X-Amz-SignedHeaders", valid_617488
  var valid_617489 = header.getOrDefault("X-Amz-Credential")
  valid_617489 = validateParameter(valid_617489, JString, required = false,
                                 default = nil)
  if valid_617489 != nil:
    section.add "X-Amz-Credential", valid_617489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617490: Call_GetCampaigns_617463; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_617490.validator(path, query, header, formData, body, _)
  let scheme = call_617490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617490.url(scheme.get, call_617490.host, call_617490.base,
                         call_617490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617490, url, valid, _)

proc call*(call_617491: Call_GetCampaigns_617463; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_617492 = newJObject()
  var query_617493 = newJObject()
  add(query_617493, "token", newJString(token))
  add(path_617492, "application-id", newJString(applicationId))
  add(query_617493, "page-size", newJString(pageSize))
  result = call_617491.call(path_617492, query_617493, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_617463(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_617464, base: "/", url: url_GetCampaigns_617465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_617526 = ref object of OpenApiRestCall_616850
proc url_UpdateEmailTemplate_617528(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_617527(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617529 = path.getOrDefault("template-name")
  valid_617529 = validateParameter(valid_617529, JString, required = true,
                                 default = nil)
  if valid_617529 != nil:
    section.add "template-name", valid_617529
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617530 = query.getOrDefault("create-new-version")
  valid_617530 = validateParameter(valid_617530, JBool, required = false, default = nil)
  if valid_617530 != nil:
    section.add "create-new-version", valid_617530
  var valid_617531 = query.getOrDefault("version")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "version", valid_617531
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
  var valid_617532 = header.getOrDefault("X-Amz-Date")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Date", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Security-Token")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-Security-Token", valid_617533
  var valid_617534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617534 = validateParameter(valid_617534, JString, required = false,
                                 default = nil)
  if valid_617534 != nil:
    section.add "X-Amz-Content-Sha256", valid_617534
  var valid_617535 = header.getOrDefault("X-Amz-Algorithm")
  valid_617535 = validateParameter(valid_617535, JString, required = false,
                                 default = nil)
  if valid_617535 != nil:
    section.add "X-Amz-Algorithm", valid_617535
  var valid_617536 = header.getOrDefault("X-Amz-Signature")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "X-Amz-Signature", valid_617536
  var valid_617537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-SignedHeaders", valid_617537
  var valid_617538 = header.getOrDefault("X-Amz-Credential")
  valid_617538 = validateParameter(valid_617538, JString, required = false,
                                 default = nil)
  if valid_617538 != nil:
    section.add "X-Amz-Credential", valid_617538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617540: Call_UpdateEmailTemplate_617526; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_617540.validator(path, query, header, formData, body, _)
  let scheme = call_617540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617540.url(scheme.get, call_617540.host, call_617540.base,
                         call_617540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617540, url, valid, _)

proc call*(call_617541: Call_UpdateEmailTemplate_617526; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template for messages that are sent through the email channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617542 = newJObject()
  var query_617543 = newJObject()
  var body_617544 = newJObject()
  add(query_617543, "create-new-version", newJBool(createNewVersion))
  add(query_617543, "version", newJString(version))
  add(path_617542, "template-name", newJString(templateName))
  if body != nil:
    body_617544 = body
  result = call_617541.call(path_617542, query_617543, nil, nil, body_617544)

var updateEmailTemplate* = Call_UpdateEmailTemplate_617526(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_617527, base: "/",
    url: url_UpdateEmailTemplate_617528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_617545 = ref object of OpenApiRestCall_616850
proc url_CreateEmailTemplate_617547(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_617546(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617548 = path.getOrDefault("template-name")
  valid_617548 = validateParameter(valid_617548, JString, required = true,
                                 default = nil)
  if valid_617548 != nil:
    section.add "template-name", valid_617548
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
  var valid_617549 = header.getOrDefault("X-Amz-Date")
  valid_617549 = validateParameter(valid_617549, JString, required = false,
                                 default = nil)
  if valid_617549 != nil:
    section.add "X-Amz-Date", valid_617549
  var valid_617550 = header.getOrDefault("X-Amz-Security-Token")
  valid_617550 = validateParameter(valid_617550, JString, required = false,
                                 default = nil)
  if valid_617550 != nil:
    section.add "X-Amz-Security-Token", valid_617550
  var valid_617551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-Content-Sha256", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-Algorithm")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-Algorithm", valid_617552
  var valid_617553 = header.getOrDefault("X-Amz-Signature")
  valid_617553 = validateParameter(valid_617553, JString, required = false,
                                 default = nil)
  if valid_617553 != nil:
    section.add "X-Amz-Signature", valid_617553
  var valid_617554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617554 = validateParameter(valid_617554, JString, required = false,
                                 default = nil)
  if valid_617554 != nil:
    section.add "X-Amz-SignedHeaders", valid_617554
  var valid_617555 = header.getOrDefault("X-Amz-Credential")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-Credential", valid_617555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617557: Call_CreateEmailTemplate_617545; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_617557.validator(path, query, header, formData, body, _)
  let scheme = call_617557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617557.url(scheme.get, call_617557.host, call_617557.base,
                         call_617557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617557, url, valid, _)

proc call*(call_617558: Call_CreateEmailTemplate_617545; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617559 = newJObject()
  var body_617560 = newJObject()
  add(path_617559, "template-name", newJString(templateName))
  if body != nil:
    body_617560 = body
  result = call_617558.call(path_617559, nil, nil, nil, body_617560)

var createEmailTemplate* = Call_CreateEmailTemplate_617545(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_617546, base: "/",
    url: url_CreateEmailTemplate_617547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_617510 = ref object of OpenApiRestCall_616850
proc url_GetEmailTemplate_617512(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_617511(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617513 = path.getOrDefault("template-name")
  valid_617513 = validateParameter(valid_617513, JString, required = true,
                                 default = nil)
  if valid_617513 != nil:
    section.add "template-name", valid_617513
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617514 = query.getOrDefault("version")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "version", valid_617514
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
  var valid_617515 = header.getOrDefault("X-Amz-Date")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-Date", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Security-Token")
  valid_617516 = validateParameter(valid_617516, JString, required = false,
                                 default = nil)
  if valid_617516 != nil:
    section.add "X-Amz-Security-Token", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Content-Sha256", valid_617517
  var valid_617518 = header.getOrDefault("X-Amz-Algorithm")
  valid_617518 = validateParameter(valid_617518, JString, required = false,
                                 default = nil)
  if valid_617518 != nil:
    section.add "X-Amz-Algorithm", valid_617518
  var valid_617519 = header.getOrDefault("X-Amz-Signature")
  valid_617519 = validateParameter(valid_617519, JString, required = false,
                                 default = nil)
  if valid_617519 != nil:
    section.add "X-Amz-Signature", valid_617519
  var valid_617520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617520 = validateParameter(valid_617520, JString, required = false,
                                 default = nil)
  if valid_617520 != nil:
    section.add "X-Amz-SignedHeaders", valid_617520
  var valid_617521 = header.getOrDefault("X-Amz-Credential")
  valid_617521 = validateParameter(valid_617521, JString, required = false,
                                 default = nil)
  if valid_617521 != nil:
    section.add "X-Amz-Credential", valid_617521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617522: Call_GetEmailTemplate_617510; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_617522.validator(path, query, header, formData, body, _)
  let scheme = call_617522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617522.url(scheme.get, call_617522.host, call_617522.base,
                         call_617522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617522, url, valid, _)

proc call*(call_617523: Call_GetEmailTemplate_617510; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617524 = newJObject()
  var query_617525 = newJObject()
  add(path_617524, "template-name", newJString(templateName))
  add(query_617525, "version", newJString(version))
  result = call_617523.call(path_617524, query_617525, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_617510(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_617511, base: "/",
    url: url_GetEmailTemplate_617512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_617561 = ref object of OpenApiRestCall_616850
proc url_DeleteEmailTemplate_617563(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_617562(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617564 = path.getOrDefault("template-name")
  valid_617564 = validateParameter(valid_617564, JString, required = true,
                                 default = nil)
  if valid_617564 != nil:
    section.add "template-name", valid_617564
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617565 = query.getOrDefault("version")
  valid_617565 = validateParameter(valid_617565, JString, required = false,
                                 default = nil)
  if valid_617565 != nil:
    section.add "version", valid_617565
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
  var valid_617566 = header.getOrDefault("X-Amz-Date")
  valid_617566 = validateParameter(valid_617566, JString, required = false,
                                 default = nil)
  if valid_617566 != nil:
    section.add "X-Amz-Date", valid_617566
  var valid_617567 = header.getOrDefault("X-Amz-Security-Token")
  valid_617567 = validateParameter(valid_617567, JString, required = false,
                                 default = nil)
  if valid_617567 != nil:
    section.add "X-Amz-Security-Token", valid_617567
  var valid_617568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617568 = validateParameter(valid_617568, JString, required = false,
                                 default = nil)
  if valid_617568 != nil:
    section.add "X-Amz-Content-Sha256", valid_617568
  var valid_617569 = header.getOrDefault("X-Amz-Algorithm")
  valid_617569 = validateParameter(valid_617569, JString, required = false,
                                 default = nil)
  if valid_617569 != nil:
    section.add "X-Amz-Algorithm", valid_617569
  var valid_617570 = header.getOrDefault("X-Amz-Signature")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Signature", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-SignedHeaders", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Credential")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Credential", valid_617572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617573: Call_DeleteEmailTemplate_617561; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_617573.validator(path, query, header, formData, body, _)
  let scheme = call_617573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617573.url(scheme.get, call_617573.host, call_617573.base,
                         call_617573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617573, url, valid, _)

proc call*(call_617574: Call_DeleteEmailTemplate_617561; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617575 = newJObject()
  var query_617576 = newJObject()
  add(path_617575, "template-name", newJString(templateName))
  add(query_617576, "version", newJString(version))
  result = call_617574.call(path_617575, query_617576, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_617561(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_617562, base: "/",
    url: url_DeleteEmailTemplate_617563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_617594 = ref object of OpenApiRestCall_616850
proc url_CreateExportJob_617596(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_617595(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617597 = path.getOrDefault("application-id")
  valid_617597 = validateParameter(valid_617597, JString, required = true,
                                 default = nil)
  if valid_617597 != nil:
    section.add "application-id", valid_617597
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
  var valid_617598 = header.getOrDefault("X-Amz-Date")
  valid_617598 = validateParameter(valid_617598, JString, required = false,
                                 default = nil)
  if valid_617598 != nil:
    section.add "X-Amz-Date", valid_617598
  var valid_617599 = header.getOrDefault("X-Amz-Security-Token")
  valid_617599 = validateParameter(valid_617599, JString, required = false,
                                 default = nil)
  if valid_617599 != nil:
    section.add "X-Amz-Security-Token", valid_617599
  var valid_617600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "X-Amz-Content-Sha256", valid_617600
  var valid_617601 = header.getOrDefault("X-Amz-Algorithm")
  valid_617601 = validateParameter(valid_617601, JString, required = false,
                                 default = nil)
  if valid_617601 != nil:
    section.add "X-Amz-Algorithm", valid_617601
  var valid_617602 = header.getOrDefault("X-Amz-Signature")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Signature", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-SignedHeaders", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Credential")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Credential", valid_617604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617606: Call_CreateExportJob_617594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_617606.validator(path, query, header, formData, body, _)
  let scheme = call_617606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617606.url(scheme.get, call_617606.host, call_617606.base,
                         call_617606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617606, url, valid, _)

proc call*(call_617607: Call_CreateExportJob_617594; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617608 = newJObject()
  var body_617609 = newJObject()
  add(path_617608, "application-id", newJString(applicationId))
  if body != nil:
    body_617609 = body
  result = call_617607.call(path_617608, nil, nil, nil, body_617609)

var createExportJob* = Call_CreateExportJob_617594(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_617595, base: "/", url: url_CreateExportJob_617596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_617577 = ref object of OpenApiRestCall_616850
proc url_GetExportJobs_617579(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_617578(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617580 = path.getOrDefault("application-id")
  valid_617580 = validateParameter(valid_617580, JString, required = true,
                                 default = nil)
  if valid_617580 != nil:
    section.add "application-id", valid_617580
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_617581 = query.getOrDefault("token")
  valid_617581 = validateParameter(valid_617581, JString, required = false,
                                 default = nil)
  if valid_617581 != nil:
    section.add "token", valid_617581
  var valid_617582 = query.getOrDefault("page-size")
  valid_617582 = validateParameter(valid_617582, JString, required = false,
                                 default = nil)
  if valid_617582 != nil:
    section.add "page-size", valid_617582
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
  var valid_617583 = header.getOrDefault("X-Amz-Date")
  valid_617583 = validateParameter(valid_617583, JString, required = false,
                                 default = nil)
  if valid_617583 != nil:
    section.add "X-Amz-Date", valid_617583
  var valid_617584 = header.getOrDefault("X-Amz-Security-Token")
  valid_617584 = validateParameter(valid_617584, JString, required = false,
                                 default = nil)
  if valid_617584 != nil:
    section.add "X-Amz-Security-Token", valid_617584
  var valid_617585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-Content-Sha256", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Algorithm")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Algorithm", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Signature")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Signature", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-SignedHeaders", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-Credential")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Credential", valid_617589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617590: Call_GetExportJobs_617577; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_617590.validator(path, query, header, formData, body, _)
  let scheme = call_617590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617590.url(scheme.get, call_617590.host, call_617590.base,
                         call_617590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617590, url, valid, _)

proc call*(call_617591: Call_GetExportJobs_617577; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_617592 = newJObject()
  var query_617593 = newJObject()
  add(query_617593, "token", newJString(token))
  add(path_617592, "application-id", newJString(applicationId))
  add(query_617593, "page-size", newJString(pageSize))
  result = call_617591.call(path_617592, query_617593, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_617577(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_617578, base: "/", url: url_GetExportJobs_617579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_617627 = ref object of OpenApiRestCall_616850
proc url_CreateImportJob_617629(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_617628(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617630 = path.getOrDefault("application-id")
  valid_617630 = validateParameter(valid_617630, JString, required = true,
                                 default = nil)
  if valid_617630 != nil:
    section.add "application-id", valid_617630
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
  var valid_617631 = header.getOrDefault("X-Amz-Date")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-Date", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Security-Token")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-Security-Token", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-Content-Sha256", valid_617633
  var valid_617634 = header.getOrDefault("X-Amz-Algorithm")
  valid_617634 = validateParameter(valid_617634, JString, required = false,
                                 default = nil)
  if valid_617634 != nil:
    section.add "X-Amz-Algorithm", valid_617634
  var valid_617635 = header.getOrDefault("X-Amz-Signature")
  valid_617635 = validateParameter(valid_617635, JString, required = false,
                                 default = nil)
  if valid_617635 != nil:
    section.add "X-Amz-Signature", valid_617635
  var valid_617636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617636 = validateParameter(valid_617636, JString, required = false,
                                 default = nil)
  if valid_617636 != nil:
    section.add "X-Amz-SignedHeaders", valid_617636
  var valid_617637 = header.getOrDefault("X-Amz-Credential")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "X-Amz-Credential", valid_617637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617639: Call_CreateImportJob_617627; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_617639.validator(path, query, header, formData, body, _)
  let scheme = call_617639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617639.url(scheme.get, call_617639.host, call_617639.base,
                         call_617639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617639, url, valid, _)

proc call*(call_617640: Call_CreateImportJob_617627; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617641 = newJObject()
  var body_617642 = newJObject()
  add(path_617641, "application-id", newJString(applicationId))
  if body != nil:
    body_617642 = body
  result = call_617640.call(path_617641, nil, nil, nil, body_617642)

var createImportJob* = Call_CreateImportJob_617627(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_617628, base: "/", url: url_CreateImportJob_617629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_617610 = ref object of OpenApiRestCall_616850
proc url_GetImportJobs_617612(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_617611(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617613 = path.getOrDefault("application-id")
  valid_617613 = validateParameter(valid_617613, JString, required = true,
                                 default = nil)
  if valid_617613 != nil:
    section.add "application-id", valid_617613
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_617614 = query.getOrDefault("token")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "token", valid_617614
  var valid_617615 = query.getOrDefault("page-size")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "page-size", valid_617615
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
  var valid_617616 = header.getOrDefault("X-Amz-Date")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Date", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Security-Token")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Security-Token", valid_617617
  var valid_617618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "X-Amz-Content-Sha256", valid_617618
  var valid_617619 = header.getOrDefault("X-Amz-Algorithm")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-Algorithm", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-Signature")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-Signature", valid_617620
  var valid_617621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617621 = validateParameter(valid_617621, JString, required = false,
                                 default = nil)
  if valid_617621 != nil:
    section.add "X-Amz-SignedHeaders", valid_617621
  var valid_617622 = header.getOrDefault("X-Amz-Credential")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Credential", valid_617622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617623: Call_GetImportJobs_617610; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_617623.validator(path, query, header, formData, body, _)
  let scheme = call_617623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617623.url(scheme.get, call_617623.host, call_617623.base,
                         call_617623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617623, url, valid, _)

proc call*(call_617624: Call_GetImportJobs_617610; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_617625 = newJObject()
  var query_617626 = newJObject()
  add(query_617626, "token", newJString(token))
  add(path_617625, "application-id", newJString(applicationId))
  add(query_617626, "page-size", newJString(pageSize))
  result = call_617624.call(path_617625, query_617626, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_617610(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_617611, base: "/", url: url_GetImportJobs_617612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_617660 = ref object of OpenApiRestCall_616850
proc url_CreateJourney_617662(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_617661(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617663 = path.getOrDefault("application-id")
  valid_617663 = validateParameter(valid_617663, JString, required = true,
                                 default = nil)
  if valid_617663 != nil:
    section.add "application-id", valid_617663
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
  var valid_617664 = header.getOrDefault("X-Amz-Date")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Date", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-Security-Token")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-Security-Token", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617666 = validateParameter(valid_617666, JString, required = false,
                                 default = nil)
  if valid_617666 != nil:
    section.add "X-Amz-Content-Sha256", valid_617666
  var valid_617667 = header.getOrDefault("X-Amz-Algorithm")
  valid_617667 = validateParameter(valid_617667, JString, required = false,
                                 default = nil)
  if valid_617667 != nil:
    section.add "X-Amz-Algorithm", valid_617667
  var valid_617668 = header.getOrDefault("X-Amz-Signature")
  valid_617668 = validateParameter(valid_617668, JString, required = false,
                                 default = nil)
  if valid_617668 != nil:
    section.add "X-Amz-Signature", valid_617668
  var valid_617669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617669 = validateParameter(valid_617669, JString, required = false,
                                 default = nil)
  if valid_617669 != nil:
    section.add "X-Amz-SignedHeaders", valid_617669
  var valid_617670 = header.getOrDefault("X-Amz-Credential")
  valid_617670 = validateParameter(valid_617670, JString, required = false,
                                 default = nil)
  if valid_617670 != nil:
    section.add "X-Amz-Credential", valid_617670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617672: Call_CreateJourney_617660; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_617672.validator(path, query, header, formData, body, _)
  let scheme = call_617672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617672.url(scheme.get, call_617672.host, call_617672.base,
                         call_617672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617672, url, valid, _)

proc call*(call_617673: Call_CreateJourney_617660; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617674 = newJObject()
  var body_617675 = newJObject()
  add(path_617674, "application-id", newJString(applicationId))
  if body != nil:
    body_617675 = body
  result = call_617673.call(path_617674, nil, nil, nil, body_617675)

var createJourney* = Call_CreateJourney_617660(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_617661, base: "/", url: url_CreateJourney_617662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_617643 = ref object of OpenApiRestCall_616850
proc url_ListJourneys_617645(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_617644(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617646 = path.getOrDefault("application-id")
  valid_617646 = validateParameter(valid_617646, JString, required = true,
                                 default = nil)
  if valid_617646 != nil:
    section.add "application-id", valid_617646
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_617647 = query.getOrDefault("token")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "token", valid_617647
  var valid_617648 = query.getOrDefault("page-size")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "page-size", valid_617648
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
  var valid_617649 = header.getOrDefault("X-Amz-Date")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-Date", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-Security-Token")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-Security-Token", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617651 = validateParameter(valid_617651, JString, required = false,
                                 default = nil)
  if valid_617651 != nil:
    section.add "X-Amz-Content-Sha256", valid_617651
  var valid_617652 = header.getOrDefault("X-Amz-Algorithm")
  valid_617652 = validateParameter(valid_617652, JString, required = false,
                                 default = nil)
  if valid_617652 != nil:
    section.add "X-Amz-Algorithm", valid_617652
  var valid_617653 = header.getOrDefault("X-Amz-Signature")
  valid_617653 = validateParameter(valid_617653, JString, required = false,
                                 default = nil)
  if valid_617653 != nil:
    section.add "X-Amz-Signature", valid_617653
  var valid_617654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617654 = validateParameter(valid_617654, JString, required = false,
                                 default = nil)
  if valid_617654 != nil:
    section.add "X-Amz-SignedHeaders", valid_617654
  var valid_617655 = header.getOrDefault("X-Amz-Credential")
  valid_617655 = validateParameter(valid_617655, JString, required = false,
                                 default = nil)
  if valid_617655 != nil:
    section.add "X-Amz-Credential", valid_617655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617656: Call_ListJourneys_617643; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_617656.validator(path, query, header, formData, body, _)
  let scheme = call_617656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617656.url(scheme.get, call_617656.host, call_617656.base,
                         call_617656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617656, url, valid, _)

proc call*(call_617657: Call_ListJourneys_617643; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_617658 = newJObject()
  var query_617659 = newJObject()
  add(query_617659, "token", newJString(token))
  add(path_617658, "application-id", newJString(applicationId))
  add(query_617659, "page-size", newJString(pageSize))
  result = call_617657.call(path_617658, query_617659, nil, nil, nil)

var listJourneys* = Call_ListJourneys_617643(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_617644,
    base: "/", url: url_ListJourneys_617645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_617692 = ref object of OpenApiRestCall_616850
proc url_UpdatePushTemplate_617694(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_617693(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617695 = path.getOrDefault("template-name")
  valid_617695 = validateParameter(valid_617695, JString, required = true,
                                 default = nil)
  if valid_617695 != nil:
    section.add "template-name", valid_617695
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617696 = query.getOrDefault("create-new-version")
  valid_617696 = validateParameter(valid_617696, JBool, required = false, default = nil)
  if valid_617696 != nil:
    section.add "create-new-version", valid_617696
  var valid_617697 = query.getOrDefault("version")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "version", valid_617697
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
  var valid_617698 = header.getOrDefault("X-Amz-Date")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Date", valid_617698
  var valid_617699 = header.getOrDefault("X-Amz-Security-Token")
  valid_617699 = validateParameter(valid_617699, JString, required = false,
                                 default = nil)
  if valid_617699 != nil:
    section.add "X-Amz-Security-Token", valid_617699
  var valid_617700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617700 = validateParameter(valid_617700, JString, required = false,
                                 default = nil)
  if valid_617700 != nil:
    section.add "X-Amz-Content-Sha256", valid_617700
  var valid_617701 = header.getOrDefault("X-Amz-Algorithm")
  valid_617701 = validateParameter(valid_617701, JString, required = false,
                                 default = nil)
  if valid_617701 != nil:
    section.add "X-Amz-Algorithm", valid_617701
  var valid_617702 = header.getOrDefault("X-Amz-Signature")
  valid_617702 = validateParameter(valid_617702, JString, required = false,
                                 default = nil)
  if valid_617702 != nil:
    section.add "X-Amz-Signature", valid_617702
  var valid_617703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617703 = validateParameter(valid_617703, JString, required = false,
                                 default = nil)
  if valid_617703 != nil:
    section.add "X-Amz-SignedHeaders", valid_617703
  var valid_617704 = header.getOrDefault("X-Amz-Credential")
  valid_617704 = validateParameter(valid_617704, JString, required = false,
                                 default = nil)
  if valid_617704 != nil:
    section.add "X-Amz-Credential", valid_617704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617706: Call_UpdatePushTemplate_617692; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_617706.validator(path, query, header, formData, body, _)
  let scheme = call_617706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617706.url(scheme.get, call_617706.host, call_617706.base,
                         call_617706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617706, url, valid, _)

proc call*(call_617707: Call_UpdatePushTemplate_617692; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617708 = newJObject()
  var query_617709 = newJObject()
  var body_617710 = newJObject()
  add(query_617709, "create-new-version", newJBool(createNewVersion))
  add(query_617709, "version", newJString(version))
  add(path_617708, "template-name", newJString(templateName))
  if body != nil:
    body_617710 = body
  result = call_617707.call(path_617708, query_617709, nil, nil, body_617710)

var updatePushTemplate* = Call_UpdatePushTemplate_617692(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_617693, base: "/",
    url: url_UpdatePushTemplate_617694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_617711 = ref object of OpenApiRestCall_616850
proc url_CreatePushTemplate_617713(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_617712(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617714 = path.getOrDefault("template-name")
  valid_617714 = validateParameter(valid_617714, JString, required = true,
                                 default = nil)
  if valid_617714 != nil:
    section.add "template-name", valid_617714
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
  var valid_617715 = header.getOrDefault("X-Amz-Date")
  valid_617715 = validateParameter(valid_617715, JString, required = false,
                                 default = nil)
  if valid_617715 != nil:
    section.add "X-Amz-Date", valid_617715
  var valid_617716 = header.getOrDefault("X-Amz-Security-Token")
  valid_617716 = validateParameter(valid_617716, JString, required = false,
                                 default = nil)
  if valid_617716 != nil:
    section.add "X-Amz-Security-Token", valid_617716
  var valid_617717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617717 = validateParameter(valid_617717, JString, required = false,
                                 default = nil)
  if valid_617717 != nil:
    section.add "X-Amz-Content-Sha256", valid_617717
  var valid_617718 = header.getOrDefault("X-Amz-Algorithm")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-Algorithm", valid_617718
  var valid_617719 = header.getOrDefault("X-Amz-Signature")
  valid_617719 = validateParameter(valid_617719, JString, required = false,
                                 default = nil)
  if valid_617719 != nil:
    section.add "X-Amz-Signature", valid_617719
  var valid_617720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-SignedHeaders", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Credential")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Credential", valid_617721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617723: Call_CreatePushTemplate_617711; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_617723.validator(path, query, header, formData, body, _)
  let scheme = call_617723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617723.url(scheme.get, call_617723.host, call_617723.base,
                         call_617723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617723, url, valid, _)

proc call*(call_617724: Call_CreatePushTemplate_617711; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617725 = newJObject()
  var body_617726 = newJObject()
  add(path_617725, "template-name", newJString(templateName))
  if body != nil:
    body_617726 = body
  result = call_617724.call(path_617725, nil, nil, nil, body_617726)

var createPushTemplate* = Call_CreatePushTemplate_617711(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_617712, base: "/",
    url: url_CreatePushTemplate_617713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_617676 = ref object of OpenApiRestCall_616850
proc url_GetPushTemplate_617678(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_617677(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617679 = path.getOrDefault("template-name")
  valid_617679 = validateParameter(valid_617679, JString, required = true,
                                 default = nil)
  if valid_617679 != nil:
    section.add "template-name", valid_617679
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617680 = query.getOrDefault("version")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "version", valid_617680
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
  var valid_617681 = header.getOrDefault("X-Amz-Date")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Date", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-Security-Token")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-Security-Token", valid_617682
  var valid_617683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-Content-Sha256", valid_617683
  var valid_617684 = header.getOrDefault("X-Amz-Algorithm")
  valid_617684 = validateParameter(valid_617684, JString, required = false,
                                 default = nil)
  if valid_617684 != nil:
    section.add "X-Amz-Algorithm", valid_617684
  var valid_617685 = header.getOrDefault("X-Amz-Signature")
  valid_617685 = validateParameter(valid_617685, JString, required = false,
                                 default = nil)
  if valid_617685 != nil:
    section.add "X-Amz-Signature", valid_617685
  var valid_617686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617686 = validateParameter(valid_617686, JString, required = false,
                                 default = nil)
  if valid_617686 != nil:
    section.add "X-Amz-SignedHeaders", valid_617686
  var valid_617687 = header.getOrDefault("X-Amz-Credential")
  valid_617687 = validateParameter(valid_617687, JString, required = false,
                                 default = nil)
  if valid_617687 != nil:
    section.add "X-Amz-Credential", valid_617687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617688: Call_GetPushTemplate_617676; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_617688.validator(path, query, header, formData, body, _)
  let scheme = call_617688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617688.url(scheme.get, call_617688.host, call_617688.base,
                         call_617688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617688, url, valid, _)

proc call*(call_617689: Call_GetPushTemplate_617676; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617690 = newJObject()
  var query_617691 = newJObject()
  add(path_617690, "template-name", newJString(templateName))
  add(query_617691, "version", newJString(version))
  result = call_617689.call(path_617690, query_617691, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_617676(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_617677, base: "/", url: url_GetPushTemplate_617678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_617727 = ref object of OpenApiRestCall_616850
proc url_DeletePushTemplate_617729(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_617728(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617730 = path.getOrDefault("template-name")
  valid_617730 = validateParameter(valid_617730, JString, required = true,
                                 default = nil)
  if valid_617730 != nil:
    section.add "template-name", valid_617730
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617731 = query.getOrDefault("version")
  valid_617731 = validateParameter(valid_617731, JString, required = false,
                                 default = nil)
  if valid_617731 != nil:
    section.add "version", valid_617731
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
  var valid_617732 = header.getOrDefault("X-Amz-Date")
  valid_617732 = validateParameter(valid_617732, JString, required = false,
                                 default = nil)
  if valid_617732 != nil:
    section.add "X-Amz-Date", valid_617732
  var valid_617733 = header.getOrDefault("X-Amz-Security-Token")
  valid_617733 = validateParameter(valid_617733, JString, required = false,
                                 default = nil)
  if valid_617733 != nil:
    section.add "X-Amz-Security-Token", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Content-Sha256", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-Algorithm")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Algorithm", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Signature")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Signature", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-SignedHeaders", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Credential")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Credential", valid_617738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617739: Call_DeletePushTemplate_617727; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_617739.validator(path, query, header, formData, body, _)
  let scheme = call_617739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617739.url(scheme.get, call_617739.host, call_617739.base,
                         call_617739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617739, url, valid, _)

proc call*(call_617740: Call_DeletePushTemplate_617727; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617741 = newJObject()
  var query_617742 = newJObject()
  add(path_617741, "template-name", newJString(templateName))
  add(query_617742, "version", newJString(version))
  result = call_617740.call(path_617741, query_617742, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_617727(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_617728, base: "/",
    url: url_DeletePushTemplate_617729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_617760 = ref object of OpenApiRestCall_616850
proc url_CreateSegment_617762(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_617761(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617763 = path.getOrDefault("application-id")
  valid_617763 = validateParameter(valid_617763, JString, required = true,
                                 default = nil)
  if valid_617763 != nil:
    section.add "application-id", valid_617763
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
  var valid_617764 = header.getOrDefault("X-Amz-Date")
  valid_617764 = validateParameter(valid_617764, JString, required = false,
                                 default = nil)
  if valid_617764 != nil:
    section.add "X-Amz-Date", valid_617764
  var valid_617765 = header.getOrDefault("X-Amz-Security-Token")
  valid_617765 = validateParameter(valid_617765, JString, required = false,
                                 default = nil)
  if valid_617765 != nil:
    section.add "X-Amz-Security-Token", valid_617765
  var valid_617766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617766 = validateParameter(valid_617766, JString, required = false,
                                 default = nil)
  if valid_617766 != nil:
    section.add "X-Amz-Content-Sha256", valid_617766
  var valid_617767 = header.getOrDefault("X-Amz-Algorithm")
  valid_617767 = validateParameter(valid_617767, JString, required = false,
                                 default = nil)
  if valid_617767 != nil:
    section.add "X-Amz-Algorithm", valid_617767
  var valid_617768 = header.getOrDefault("X-Amz-Signature")
  valid_617768 = validateParameter(valid_617768, JString, required = false,
                                 default = nil)
  if valid_617768 != nil:
    section.add "X-Amz-Signature", valid_617768
  var valid_617769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617769 = validateParameter(valid_617769, JString, required = false,
                                 default = nil)
  if valid_617769 != nil:
    section.add "X-Amz-SignedHeaders", valid_617769
  var valid_617770 = header.getOrDefault("X-Amz-Credential")
  valid_617770 = validateParameter(valid_617770, JString, required = false,
                                 default = nil)
  if valid_617770 != nil:
    section.add "X-Amz-Credential", valid_617770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617772: Call_CreateSegment_617760; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_617772.validator(path, query, header, formData, body, _)
  let scheme = call_617772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617772.url(scheme.get, call_617772.host, call_617772.base,
                         call_617772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617772, url, valid, _)

proc call*(call_617773: Call_CreateSegment_617760; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617774 = newJObject()
  var body_617775 = newJObject()
  add(path_617774, "application-id", newJString(applicationId))
  if body != nil:
    body_617775 = body
  result = call_617773.call(path_617774, nil, nil, nil, body_617775)

var createSegment* = Call_CreateSegment_617760(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_617761, base: "/", url: url_CreateSegment_617762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_617743 = ref object of OpenApiRestCall_616850
proc url_GetSegments_617745(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_617744(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617746 = path.getOrDefault("application-id")
  valid_617746 = validateParameter(valid_617746, JString, required = true,
                                 default = nil)
  if valid_617746 != nil:
    section.add "application-id", valid_617746
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_617747 = query.getOrDefault("token")
  valid_617747 = validateParameter(valid_617747, JString, required = false,
                                 default = nil)
  if valid_617747 != nil:
    section.add "token", valid_617747
  var valid_617748 = query.getOrDefault("page-size")
  valid_617748 = validateParameter(valid_617748, JString, required = false,
                                 default = nil)
  if valid_617748 != nil:
    section.add "page-size", valid_617748
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
  var valid_617749 = header.getOrDefault("X-Amz-Date")
  valid_617749 = validateParameter(valid_617749, JString, required = false,
                                 default = nil)
  if valid_617749 != nil:
    section.add "X-Amz-Date", valid_617749
  var valid_617750 = header.getOrDefault("X-Amz-Security-Token")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Security-Token", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-Content-Sha256", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Algorithm")
  valid_617752 = validateParameter(valid_617752, JString, required = false,
                                 default = nil)
  if valid_617752 != nil:
    section.add "X-Amz-Algorithm", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-Signature")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-Signature", valid_617753
  var valid_617754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617754 = validateParameter(valid_617754, JString, required = false,
                                 default = nil)
  if valid_617754 != nil:
    section.add "X-Amz-SignedHeaders", valid_617754
  var valid_617755 = header.getOrDefault("X-Amz-Credential")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "X-Amz-Credential", valid_617755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617756: Call_GetSegments_617743; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_617756.validator(path, query, header, formData, body, _)
  let scheme = call_617756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617756.url(scheme.get, call_617756.host, call_617756.base,
                         call_617756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617756, url, valid, _)

proc call*(call_617757: Call_GetSegments_617743; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_617758 = newJObject()
  var query_617759 = newJObject()
  add(query_617759, "token", newJString(token))
  add(path_617758, "application-id", newJString(applicationId))
  add(query_617759, "page-size", newJString(pageSize))
  result = call_617757.call(path_617758, query_617759, nil, nil, nil)

var getSegments* = Call_GetSegments_617743(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_617744,
                                        base: "/", url: url_GetSegments_617745,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_617792 = ref object of OpenApiRestCall_616850
proc url_UpdateSmsTemplate_617794(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_617793(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617795 = path.getOrDefault("template-name")
  valid_617795 = validateParameter(valid_617795, JString, required = true,
                                 default = nil)
  if valid_617795 != nil:
    section.add "template-name", valid_617795
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617796 = query.getOrDefault("create-new-version")
  valid_617796 = validateParameter(valid_617796, JBool, required = false, default = nil)
  if valid_617796 != nil:
    section.add "create-new-version", valid_617796
  var valid_617797 = query.getOrDefault("version")
  valid_617797 = validateParameter(valid_617797, JString, required = false,
                                 default = nil)
  if valid_617797 != nil:
    section.add "version", valid_617797
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
  var valid_617798 = header.getOrDefault("X-Amz-Date")
  valid_617798 = validateParameter(valid_617798, JString, required = false,
                                 default = nil)
  if valid_617798 != nil:
    section.add "X-Amz-Date", valid_617798
  var valid_617799 = header.getOrDefault("X-Amz-Security-Token")
  valid_617799 = validateParameter(valid_617799, JString, required = false,
                                 default = nil)
  if valid_617799 != nil:
    section.add "X-Amz-Security-Token", valid_617799
  var valid_617800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617800 = validateParameter(valid_617800, JString, required = false,
                                 default = nil)
  if valid_617800 != nil:
    section.add "X-Amz-Content-Sha256", valid_617800
  var valid_617801 = header.getOrDefault("X-Amz-Algorithm")
  valid_617801 = validateParameter(valid_617801, JString, required = false,
                                 default = nil)
  if valid_617801 != nil:
    section.add "X-Amz-Algorithm", valid_617801
  var valid_617802 = header.getOrDefault("X-Amz-Signature")
  valid_617802 = validateParameter(valid_617802, JString, required = false,
                                 default = nil)
  if valid_617802 != nil:
    section.add "X-Amz-Signature", valid_617802
  var valid_617803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617803 = validateParameter(valid_617803, JString, required = false,
                                 default = nil)
  if valid_617803 != nil:
    section.add "X-Amz-SignedHeaders", valid_617803
  var valid_617804 = header.getOrDefault("X-Amz-Credential")
  valid_617804 = validateParameter(valid_617804, JString, required = false,
                                 default = nil)
  if valid_617804 != nil:
    section.add "X-Amz-Credential", valid_617804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617806: Call_UpdateSmsTemplate_617792; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_617806.validator(path, query, header, formData, body, _)
  let scheme = call_617806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617806.url(scheme.get, call_617806.host, call_617806.base,
                         call_617806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617806, url, valid, _)

proc call*(call_617807: Call_UpdateSmsTemplate_617792; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617808 = newJObject()
  var query_617809 = newJObject()
  var body_617810 = newJObject()
  add(query_617809, "create-new-version", newJBool(createNewVersion))
  add(query_617809, "version", newJString(version))
  add(path_617808, "template-name", newJString(templateName))
  if body != nil:
    body_617810 = body
  result = call_617807.call(path_617808, query_617809, nil, nil, body_617810)

var updateSmsTemplate* = Call_UpdateSmsTemplate_617792(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_617793, base: "/",
    url: url_UpdateSmsTemplate_617794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_617811 = ref object of OpenApiRestCall_616850
proc url_CreateSmsTemplate_617813(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_617812(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617814 = path.getOrDefault("template-name")
  valid_617814 = validateParameter(valid_617814, JString, required = true,
                                 default = nil)
  if valid_617814 != nil:
    section.add "template-name", valid_617814
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
  var valid_617815 = header.getOrDefault("X-Amz-Date")
  valid_617815 = validateParameter(valid_617815, JString, required = false,
                                 default = nil)
  if valid_617815 != nil:
    section.add "X-Amz-Date", valid_617815
  var valid_617816 = header.getOrDefault("X-Amz-Security-Token")
  valid_617816 = validateParameter(valid_617816, JString, required = false,
                                 default = nil)
  if valid_617816 != nil:
    section.add "X-Amz-Security-Token", valid_617816
  var valid_617817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Content-Sha256", valid_617817
  var valid_617818 = header.getOrDefault("X-Amz-Algorithm")
  valid_617818 = validateParameter(valid_617818, JString, required = false,
                                 default = nil)
  if valid_617818 != nil:
    section.add "X-Amz-Algorithm", valid_617818
  var valid_617819 = header.getOrDefault("X-Amz-Signature")
  valid_617819 = validateParameter(valid_617819, JString, required = false,
                                 default = nil)
  if valid_617819 != nil:
    section.add "X-Amz-Signature", valid_617819
  var valid_617820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617820 = validateParameter(valid_617820, JString, required = false,
                                 default = nil)
  if valid_617820 != nil:
    section.add "X-Amz-SignedHeaders", valid_617820
  var valid_617821 = header.getOrDefault("X-Amz-Credential")
  valid_617821 = validateParameter(valid_617821, JString, required = false,
                                 default = nil)
  if valid_617821 != nil:
    section.add "X-Amz-Credential", valid_617821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617823: Call_CreateSmsTemplate_617811; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_617823.validator(path, query, header, formData, body, _)
  let scheme = call_617823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617823.url(scheme.get, call_617823.host, call_617823.base,
                         call_617823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617823, url, valid, _)

proc call*(call_617824: Call_CreateSmsTemplate_617811; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617825 = newJObject()
  var body_617826 = newJObject()
  add(path_617825, "template-name", newJString(templateName))
  if body != nil:
    body_617826 = body
  result = call_617824.call(path_617825, nil, nil, nil, body_617826)

var createSmsTemplate* = Call_CreateSmsTemplate_617811(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_617812, base: "/",
    url: url_CreateSmsTemplate_617813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_617776 = ref object of OpenApiRestCall_616850
proc url_GetSmsTemplate_617778(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_617777(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617779 = path.getOrDefault("template-name")
  valid_617779 = validateParameter(valid_617779, JString, required = true,
                                 default = nil)
  if valid_617779 != nil:
    section.add "template-name", valid_617779
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617780 = query.getOrDefault("version")
  valid_617780 = validateParameter(valid_617780, JString, required = false,
                                 default = nil)
  if valid_617780 != nil:
    section.add "version", valid_617780
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
  var valid_617781 = header.getOrDefault("X-Amz-Date")
  valid_617781 = validateParameter(valid_617781, JString, required = false,
                                 default = nil)
  if valid_617781 != nil:
    section.add "X-Amz-Date", valid_617781
  var valid_617782 = header.getOrDefault("X-Amz-Security-Token")
  valid_617782 = validateParameter(valid_617782, JString, required = false,
                                 default = nil)
  if valid_617782 != nil:
    section.add "X-Amz-Security-Token", valid_617782
  var valid_617783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617783 = validateParameter(valid_617783, JString, required = false,
                                 default = nil)
  if valid_617783 != nil:
    section.add "X-Amz-Content-Sha256", valid_617783
  var valid_617784 = header.getOrDefault("X-Amz-Algorithm")
  valid_617784 = validateParameter(valid_617784, JString, required = false,
                                 default = nil)
  if valid_617784 != nil:
    section.add "X-Amz-Algorithm", valid_617784
  var valid_617785 = header.getOrDefault("X-Amz-Signature")
  valid_617785 = validateParameter(valid_617785, JString, required = false,
                                 default = nil)
  if valid_617785 != nil:
    section.add "X-Amz-Signature", valid_617785
  var valid_617786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617786 = validateParameter(valid_617786, JString, required = false,
                                 default = nil)
  if valid_617786 != nil:
    section.add "X-Amz-SignedHeaders", valid_617786
  var valid_617787 = header.getOrDefault("X-Amz-Credential")
  valid_617787 = validateParameter(valid_617787, JString, required = false,
                                 default = nil)
  if valid_617787 != nil:
    section.add "X-Amz-Credential", valid_617787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617788: Call_GetSmsTemplate_617776; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_617788.validator(path, query, header, formData, body, _)
  let scheme = call_617788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617788.url(scheme.get, call_617788.host, call_617788.base,
                         call_617788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617788, url, valid, _)

proc call*(call_617789: Call_GetSmsTemplate_617776; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617790 = newJObject()
  var query_617791 = newJObject()
  add(path_617790, "template-name", newJString(templateName))
  add(query_617791, "version", newJString(version))
  result = call_617789.call(path_617790, query_617791, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_617776(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_617777, base: "/", url: url_GetSmsTemplate_617778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_617827 = ref object of OpenApiRestCall_616850
proc url_DeleteSmsTemplate_617829(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_617828(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617830 = path.getOrDefault("template-name")
  valid_617830 = validateParameter(valid_617830, JString, required = true,
                                 default = nil)
  if valid_617830 != nil:
    section.add "template-name", valid_617830
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617831 = query.getOrDefault("version")
  valid_617831 = validateParameter(valid_617831, JString, required = false,
                                 default = nil)
  if valid_617831 != nil:
    section.add "version", valid_617831
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
  var valid_617832 = header.getOrDefault("X-Amz-Date")
  valid_617832 = validateParameter(valid_617832, JString, required = false,
                                 default = nil)
  if valid_617832 != nil:
    section.add "X-Amz-Date", valid_617832
  var valid_617833 = header.getOrDefault("X-Amz-Security-Token")
  valid_617833 = validateParameter(valid_617833, JString, required = false,
                                 default = nil)
  if valid_617833 != nil:
    section.add "X-Amz-Security-Token", valid_617833
  var valid_617834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617834 = validateParameter(valid_617834, JString, required = false,
                                 default = nil)
  if valid_617834 != nil:
    section.add "X-Amz-Content-Sha256", valid_617834
  var valid_617835 = header.getOrDefault("X-Amz-Algorithm")
  valid_617835 = validateParameter(valid_617835, JString, required = false,
                                 default = nil)
  if valid_617835 != nil:
    section.add "X-Amz-Algorithm", valid_617835
  var valid_617836 = header.getOrDefault("X-Amz-Signature")
  valid_617836 = validateParameter(valid_617836, JString, required = false,
                                 default = nil)
  if valid_617836 != nil:
    section.add "X-Amz-Signature", valid_617836
  var valid_617837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617837 = validateParameter(valid_617837, JString, required = false,
                                 default = nil)
  if valid_617837 != nil:
    section.add "X-Amz-SignedHeaders", valid_617837
  var valid_617838 = header.getOrDefault("X-Amz-Credential")
  valid_617838 = validateParameter(valid_617838, JString, required = false,
                                 default = nil)
  if valid_617838 != nil:
    section.add "X-Amz-Credential", valid_617838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617839: Call_DeleteSmsTemplate_617827; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_617839.validator(path, query, header, formData, body, _)
  let scheme = call_617839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617839.url(scheme.get, call_617839.host, call_617839.base,
                         call_617839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617839, url, valid, _)

proc call*(call_617840: Call_DeleteSmsTemplate_617827; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617841 = newJObject()
  var query_617842 = newJObject()
  add(path_617841, "template-name", newJString(templateName))
  add(query_617842, "version", newJString(version))
  result = call_617840.call(path_617841, query_617842, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_617827(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_617828, base: "/",
    url: url_DeleteSmsTemplate_617829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_617859 = ref object of OpenApiRestCall_616850
proc url_UpdateVoiceTemplate_617861(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceTemplate_617860(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617862 = path.getOrDefault("template-name")
  valid_617862 = validateParameter(valid_617862, JString, required = true,
                                 default = nil)
  if valid_617862 != nil:
    section.add "template-name", valid_617862
  result.add "path", section
  ## parameters in `query` object:
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617863 = query.getOrDefault("create-new-version")
  valid_617863 = validateParameter(valid_617863, JBool, required = false, default = nil)
  if valid_617863 != nil:
    section.add "create-new-version", valid_617863
  var valid_617864 = query.getOrDefault("version")
  valid_617864 = validateParameter(valid_617864, JString, required = false,
                                 default = nil)
  if valid_617864 != nil:
    section.add "version", valid_617864
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
  var valid_617865 = header.getOrDefault("X-Amz-Date")
  valid_617865 = validateParameter(valid_617865, JString, required = false,
                                 default = nil)
  if valid_617865 != nil:
    section.add "X-Amz-Date", valid_617865
  var valid_617866 = header.getOrDefault("X-Amz-Security-Token")
  valid_617866 = validateParameter(valid_617866, JString, required = false,
                                 default = nil)
  if valid_617866 != nil:
    section.add "X-Amz-Security-Token", valid_617866
  var valid_617867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617867 = validateParameter(valid_617867, JString, required = false,
                                 default = nil)
  if valid_617867 != nil:
    section.add "X-Amz-Content-Sha256", valid_617867
  var valid_617868 = header.getOrDefault("X-Amz-Algorithm")
  valid_617868 = validateParameter(valid_617868, JString, required = false,
                                 default = nil)
  if valid_617868 != nil:
    section.add "X-Amz-Algorithm", valid_617868
  var valid_617869 = header.getOrDefault("X-Amz-Signature")
  valid_617869 = validateParameter(valid_617869, JString, required = false,
                                 default = nil)
  if valid_617869 != nil:
    section.add "X-Amz-Signature", valid_617869
  var valid_617870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617870 = validateParameter(valid_617870, JString, required = false,
                                 default = nil)
  if valid_617870 != nil:
    section.add "X-Amz-SignedHeaders", valid_617870
  var valid_617871 = header.getOrDefault("X-Amz-Credential")
  valid_617871 = validateParameter(valid_617871, JString, required = false,
                                 default = nil)
  if valid_617871 != nil:
    section.add "X-Amz-Credential", valid_617871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617873: Call_UpdateVoiceTemplate_617859; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_617873.validator(path, query, header, formData, body, _)
  let scheme = call_617873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617873.url(scheme.get, call_617873.host, call_617873.base,
                         call_617873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617873, url, valid, _)

proc call*(call_617874: Call_UpdateVoiceTemplate_617859; templateName: string;
          body: JsonNode; createNewVersion: bool = false; version: string = ""): Recallable =
  ## updateVoiceTemplate
  ## Updates an existing message template for messages that are sent through the voice channel.
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617875 = newJObject()
  var query_617876 = newJObject()
  var body_617877 = newJObject()
  add(query_617876, "create-new-version", newJBool(createNewVersion))
  add(query_617876, "version", newJString(version))
  add(path_617875, "template-name", newJString(templateName))
  if body != nil:
    body_617877 = body
  result = call_617874.call(path_617875, query_617876, nil, nil, body_617877)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_617859(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_617860, base: "/",
    url: url_UpdateVoiceTemplate_617861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_617878 = ref object of OpenApiRestCall_616850
proc url_CreateVoiceTemplate_617880(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceTemplate_617879(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617881 = path.getOrDefault("template-name")
  valid_617881 = validateParameter(valid_617881, JString, required = true,
                                 default = nil)
  if valid_617881 != nil:
    section.add "template-name", valid_617881
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
  var valid_617882 = header.getOrDefault("X-Amz-Date")
  valid_617882 = validateParameter(valid_617882, JString, required = false,
                                 default = nil)
  if valid_617882 != nil:
    section.add "X-Amz-Date", valid_617882
  var valid_617883 = header.getOrDefault("X-Amz-Security-Token")
  valid_617883 = validateParameter(valid_617883, JString, required = false,
                                 default = nil)
  if valid_617883 != nil:
    section.add "X-Amz-Security-Token", valid_617883
  var valid_617884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617884 = validateParameter(valid_617884, JString, required = false,
                                 default = nil)
  if valid_617884 != nil:
    section.add "X-Amz-Content-Sha256", valid_617884
  var valid_617885 = header.getOrDefault("X-Amz-Algorithm")
  valid_617885 = validateParameter(valid_617885, JString, required = false,
                                 default = nil)
  if valid_617885 != nil:
    section.add "X-Amz-Algorithm", valid_617885
  var valid_617886 = header.getOrDefault("X-Amz-Signature")
  valid_617886 = validateParameter(valid_617886, JString, required = false,
                                 default = nil)
  if valid_617886 != nil:
    section.add "X-Amz-Signature", valid_617886
  var valid_617887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617887 = validateParameter(valid_617887, JString, required = false,
                                 default = nil)
  if valid_617887 != nil:
    section.add "X-Amz-SignedHeaders", valid_617887
  var valid_617888 = header.getOrDefault("X-Amz-Credential")
  valid_617888 = validateParameter(valid_617888, JString, required = false,
                                 default = nil)
  if valid_617888 != nil:
    section.add "X-Amz-Credential", valid_617888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617890: Call_CreateVoiceTemplate_617878; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_617890.validator(path, query, header, formData, body, _)
  let scheme = call_617890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617890.url(scheme.get, call_617890.host, call_617890.base,
                         call_617890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617890, url, valid, _)

proc call*(call_617891: Call_CreateVoiceTemplate_617878; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_617892 = newJObject()
  var body_617893 = newJObject()
  add(path_617892, "template-name", newJString(templateName))
  if body != nil:
    body_617893 = body
  result = call_617891.call(path_617892, nil, nil, nil, body_617893)

var createVoiceTemplate* = Call_CreateVoiceTemplate_617878(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_617879, base: "/",
    url: url_CreateVoiceTemplate_617880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_617843 = ref object of OpenApiRestCall_616850
proc url_GetVoiceTemplate_617845(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceTemplate_617844(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617846 = path.getOrDefault("template-name")
  valid_617846 = validateParameter(valid_617846, JString, required = true,
                                 default = nil)
  if valid_617846 != nil:
    section.add "template-name", valid_617846
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617847 = query.getOrDefault("version")
  valid_617847 = validateParameter(valid_617847, JString, required = false,
                                 default = nil)
  if valid_617847 != nil:
    section.add "version", valid_617847
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
  var valid_617848 = header.getOrDefault("X-Amz-Date")
  valid_617848 = validateParameter(valid_617848, JString, required = false,
                                 default = nil)
  if valid_617848 != nil:
    section.add "X-Amz-Date", valid_617848
  var valid_617849 = header.getOrDefault("X-Amz-Security-Token")
  valid_617849 = validateParameter(valid_617849, JString, required = false,
                                 default = nil)
  if valid_617849 != nil:
    section.add "X-Amz-Security-Token", valid_617849
  var valid_617850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617850 = validateParameter(valid_617850, JString, required = false,
                                 default = nil)
  if valid_617850 != nil:
    section.add "X-Amz-Content-Sha256", valid_617850
  var valid_617851 = header.getOrDefault("X-Amz-Algorithm")
  valid_617851 = validateParameter(valid_617851, JString, required = false,
                                 default = nil)
  if valid_617851 != nil:
    section.add "X-Amz-Algorithm", valid_617851
  var valid_617852 = header.getOrDefault("X-Amz-Signature")
  valid_617852 = validateParameter(valid_617852, JString, required = false,
                                 default = nil)
  if valid_617852 != nil:
    section.add "X-Amz-Signature", valid_617852
  var valid_617853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617853 = validateParameter(valid_617853, JString, required = false,
                                 default = nil)
  if valid_617853 != nil:
    section.add "X-Amz-SignedHeaders", valid_617853
  var valid_617854 = header.getOrDefault("X-Amz-Credential")
  valid_617854 = validateParameter(valid_617854, JString, required = false,
                                 default = nil)
  if valid_617854 != nil:
    section.add "X-Amz-Credential", valid_617854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617855: Call_GetVoiceTemplate_617843; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_617855.validator(path, query, header, formData, body, _)
  let scheme = call_617855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617855.url(scheme.get, call_617855.host, call_617855.base,
                         call_617855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617855, url, valid, _)

proc call*(call_617856: Call_GetVoiceTemplate_617843; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617857 = newJObject()
  var query_617858 = newJObject()
  add(path_617857, "template-name", newJString(templateName))
  add(query_617858, "version", newJString(version))
  result = call_617856.call(path_617857, query_617858, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_617843(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_617844, base: "/",
    url: url_GetVoiceTemplate_617845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_617894 = ref object of OpenApiRestCall_616850
proc url_DeleteVoiceTemplate_617896(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceTemplate_617895(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617897 = path.getOrDefault("template-name")
  valid_617897 = validateParameter(valid_617897, JString, required = true,
                                 default = nil)
  if valid_617897 != nil:
    section.add "template-name", valid_617897
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_617898 = query.getOrDefault("version")
  valid_617898 = validateParameter(valid_617898, JString, required = false,
                                 default = nil)
  if valid_617898 != nil:
    section.add "version", valid_617898
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
  var valid_617899 = header.getOrDefault("X-Amz-Date")
  valid_617899 = validateParameter(valid_617899, JString, required = false,
                                 default = nil)
  if valid_617899 != nil:
    section.add "X-Amz-Date", valid_617899
  var valid_617900 = header.getOrDefault("X-Amz-Security-Token")
  valid_617900 = validateParameter(valid_617900, JString, required = false,
                                 default = nil)
  if valid_617900 != nil:
    section.add "X-Amz-Security-Token", valid_617900
  var valid_617901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617901 = validateParameter(valid_617901, JString, required = false,
                                 default = nil)
  if valid_617901 != nil:
    section.add "X-Amz-Content-Sha256", valid_617901
  var valid_617902 = header.getOrDefault("X-Amz-Algorithm")
  valid_617902 = validateParameter(valid_617902, JString, required = false,
                                 default = nil)
  if valid_617902 != nil:
    section.add "X-Amz-Algorithm", valid_617902
  var valid_617903 = header.getOrDefault("X-Amz-Signature")
  valid_617903 = validateParameter(valid_617903, JString, required = false,
                                 default = nil)
  if valid_617903 != nil:
    section.add "X-Amz-Signature", valid_617903
  var valid_617904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617904 = validateParameter(valid_617904, JString, required = false,
                                 default = nil)
  if valid_617904 != nil:
    section.add "X-Amz-SignedHeaders", valid_617904
  var valid_617905 = header.getOrDefault("X-Amz-Credential")
  valid_617905 = validateParameter(valid_617905, JString, required = false,
                                 default = nil)
  if valid_617905 != nil:
    section.add "X-Amz-Credential", valid_617905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617906: Call_DeleteVoiceTemplate_617894; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_617906.validator(path, query, header, formData, body, _)
  let scheme = call_617906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617906.url(scheme.get, call_617906.host, call_617906.base,
                         call_617906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617906, url, valid, _)

proc call*(call_617907: Call_DeleteVoiceTemplate_617894; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_617908 = newJObject()
  var query_617909 = newJObject()
  add(path_617908, "template-name", newJString(templateName))
  add(query_617909, "version", newJString(version))
  result = call_617907.call(path_617908, query_617909, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_617894(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_617895, base: "/",
    url: url_DeleteVoiceTemplate_617896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_617924 = ref object of OpenApiRestCall_616850
proc url_UpdateAdmChannel_617926(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_617925(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617927 = path.getOrDefault("application-id")
  valid_617927 = validateParameter(valid_617927, JString, required = true,
                                 default = nil)
  if valid_617927 != nil:
    section.add "application-id", valid_617927
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
  var valid_617928 = header.getOrDefault("X-Amz-Date")
  valid_617928 = validateParameter(valid_617928, JString, required = false,
                                 default = nil)
  if valid_617928 != nil:
    section.add "X-Amz-Date", valid_617928
  var valid_617929 = header.getOrDefault("X-Amz-Security-Token")
  valid_617929 = validateParameter(valid_617929, JString, required = false,
                                 default = nil)
  if valid_617929 != nil:
    section.add "X-Amz-Security-Token", valid_617929
  var valid_617930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617930 = validateParameter(valid_617930, JString, required = false,
                                 default = nil)
  if valid_617930 != nil:
    section.add "X-Amz-Content-Sha256", valid_617930
  var valid_617931 = header.getOrDefault("X-Amz-Algorithm")
  valid_617931 = validateParameter(valid_617931, JString, required = false,
                                 default = nil)
  if valid_617931 != nil:
    section.add "X-Amz-Algorithm", valid_617931
  var valid_617932 = header.getOrDefault("X-Amz-Signature")
  valid_617932 = validateParameter(valid_617932, JString, required = false,
                                 default = nil)
  if valid_617932 != nil:
    section.add "X-Amz-Signature", valid_617932
  var valid_617933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617933 = validateParameter(valid_617933, JString, required = false,
                                 default = nil)
  if valid_617933 != nil:
    section.add "X-Amz-SignedHeaders", valid_617933
  var valid_617934 = header.getOrDefault("X-Amz-Credential")
  valid_617934 = validateParameter(valid_617934, JString, required = false,
                                 default = nil)
  if valid_617934 != nil:
    section.add "X-Amz-Credential", valid_617934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617936: Call_UpdateAdmChannel_617924; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_617936.validator(path, query, header, formData, body, _)
  let scheme = call_617936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617936.url(scheme.get, call_617936.host, call_617936.base,
                         call_617936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617936, url, valid, _)

proc call*(call_617937: Call_UpdateAdmChannel_617924; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617938 = newJObject()
  var body_617939 = newJObject()
  add(path_617938, "application-id", newJString(applicationId))
  if body != nil:
    body_617939 = body
  result = call_617937.call(path_617938, nil, nil, nil, body_617939)

var updateAdmChannel* = Call_UpdateAdmChannel_617924(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_617925, base: "/",
    url: url_UpdateAdmChannel_617926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_617910 = ref object of OpenApiRestCall_616850
proc url_GetAdmChannel_617912(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_617911(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617913 = path.getOrDefault("application-id")
  valid_617913 = validateParameter(valid_617913, JString, required = true,
                                 default = nil)
  if valid_617913 != nil:
    section.add "application-id", valid_617913
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
  var valid_617914 = header.getOrDefault("X-Amz-Date")
  valid_617914 = validateParameter(valid_617914, JString, required = false,
                                 default = nil)
  if valid_617914 != nil:
    section.add "X-Amz-Date", valid_617914
  var valid_617915 = header.getOrDefault("X-Amz-Security-Token")
  valid_617915 = validateParameter(valid_617915, JString, required = false,
                                 default = nil)
  if valid_617915 != nil:
    section.add "X-Amz-Security-Token", valid_617915
  var valid_617916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617916 = validateParameter(valid_617916, JString, required = false,
                                 default = nil)
  if valid_617916 != nil:
    section.add "X-Amz-Content-Sha256", valid_617916
  var valid_617917 = header.getOrDefault("X-Amz-Algorithm")
  valid_617917 = validateParameter(valid_617917, JString, required = false,
                                 default = nil)
  if valid_617917 != nil:
    section.add "X-Amz-Algorithm", valid_617917
  var valid_617918 = header.getOrDefault("X-Amz-Signature")
  valid_617918 = validateParameter(valid_617918, JString, required = false,
                                 default = nil)
  if valid_617918 != nil:
    section.add "X-Amz-Signature", valid_617918
  var valid_617919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617919 = validateParameter(valid_617919, JString, required = false,
                                 default = nil)
  if valid_617919 != nil:
    section.add "X-Amz-SignedHeaders", valid_617919
  var valid_617920 = header.getOrDefault("X-Amz-Credential")
  valid_617920 = validateParameter(valid_617920, JString, required = false,
                                 default = nil)
  if valid_617920 != nil:
    section.add "X-Amz-Credential", valid_617920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617921: Call_GetAdmChannel_617910; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_617921.validator(path, query, header, formData, body, _)
  let scheme = call_617921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617921.url(scheme.get, call_617921.host, call_617921.base,
                         call_617921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617921, url, valid, _)

proc call*(call_617922: Call_GetAdmChannel_617910; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_617923 = newJObject()
  add(path_617923, "application-id", newJString(applicationId))
  result = call_617922.call(path_617923, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_617910(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_617911, base: "/", url: url_GetAdmChannel_617912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_617940 = ref object of OpenApiRestCall_616850
proc url_DeleteAdmChannel_617942(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_617941(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617943 = path.getOrDefault("application-id")
  valid_617943 = validateParameter(valid_617943, JString, required = true,
                                 default = nil)
  if valid_617943 != nil:
    section.add "application-id", valid_617943
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
  var valid_617944 = header.getOrDefault("X-Amz-Date")
  valid_617944 = validateParameter(valid_617944, JString, required = false,
                                 default = nil)
  if valid_617944 != nil:
    section.add "X-Amz-Date", valid_617944
  var valid_617945 = header.getOrDefault("X-Amz-Security-Token")
  valid_617945 = validateParameter(valid_617945, JString, required = false,
                                 default = nil)
  if valid_617945 != nil:
    section.add "X-Amz-Security-Token", valid_617945
  var valid_617946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617946 = validateParameter(valid_617946, JString, required = false,
                                 default = nil)
  if valid_617946 != nil:
    section.add "X-Amz-Content-Sha256", valid_617946
  var valid_617947 = header.getOrDefault("X-Amz-Algorithm")
  valid_617947 = validateParameter(valid_617947, JString, required = false,
                                 default = nil)
  if valid_617947 != nil:
    section.add "X-Amz-Algorithm", valid_617947
  var valid_617948 = header.getOrDefault("X-Amz-Signature")
  valid_617948 = validateParameter(valid_617948, JString, required = false,
                                 default = nil)
  if valid_617948 != nil:
    section.add "X-Amz-Signature", valid_617948
  var valid_617949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617949 = validateParameter(valid_617949, JString, required = false,
                                 default = nil)
  if valid_617949 != nil:
    section.add "X-Amz-SignedHeaders", valid_617949
  var valid_617950 = header.getOrDefault("X-Amz-Credential")
  valid_617950 = validateParameter(valid_617950, JString, required = false,
                                 default = nil)
  if valid_617950 != nil:
    section.add "X-Amz-Credential", valid_617950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617951: Call_DeleteAdmChannel_617940; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_617951.validator(path, query, header, formData, body, _)
  let scheme = call_617951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617951.url(scheme.get, call_617951.host, call_617951.base,
                         call_617951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617951, url, valid, _)

proc call*(call_617952: Call_DeleteAdmChannel_617940; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_617953 = newJObject()
  add(path_617953, "application-id", newJString(applicationId))
  result = call_617952.call(path_617953, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_617940(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_617941, base: "/",
    url: url_DeleteAdmChannel_617942, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_617968 = ref object of OpenApiRestCall_616850
proc url_UpdateApnsChannel_617970(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_617969(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617971 = path.getOrDefault("application-id")
  valid_617971 = validateParameter(valid_617971, JString, required = true,
                                 default = nil)
  if valid_617971 != nil:
    section.add "application-id", valid_617971
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
  var valid_617972 = header.getOrDefault("X-Amz-Date")
  valid_617972 = validateParameter(valid_617972, JString, required = false,
                                 default = nil)
  if valid_617972 != nil:
    section.add "X-Amz-Date", valid_617972
  var valid_617973 = header.getOrDefault("X-Amz-Security-Token")
  valid_617973 = validateParameter(valid_617973, JString, required = false,
                                 default = nil)
  if valid_617973 != nil:
    section.add "X-Amz-Security-Token", valid_617973
  var valid_617974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617974 = validateParameter(valid_617974, JString, required = false,
                                 default = nil)
  if valid_617974 != nil:
    section.add "X-Amz-Content-Sha256", valid_617974
  var valid_617975 = header.getOrDefault("X-Amz-Algorithm")
  valid_617975 = validateParameter(valid_617975, JString, required = false,
                                 default = nil)
  if valid_617975 != nil:
    section.add "X-Amz-Algorithm", valid_617975
  var valid_617976 = header.getOrDefault("X-Amz-Signature")
  valid_617976 = validateParameter(valid_617976, JString, required = false,
                                 default = nil)
  if valid_617976 != nil:
    section.add "X-Amz-Signature", valid_617976
  var valid_617977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617977 = validateParameter(valid_617977, JString, required = false,
                                 default = nil)
  if valid_617977 != nil:
    section.add "X-Amz-SignedHeaders", valid_617977
  var valid_617978 = header.getOrDefault("X-Amz-Credential")
  valid_617978 = validateParameter(valid_617978, JString, required = false,
                                 default = nil)
  if valid_617978 != nil:
    section.add "X-Amz-Credential", valid_617978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617980: Call_UpdateApnsChannel_617968; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_617980.validator(path, query, header, formData, body, _)
  let scheme = call_617980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617980.url(scheme.get, call_617980.host, call_617980.base,
                         call_617980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617980, url, valid, _)

proc call*(call_617981: Call_UpdateApnsChannel_617968; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_617982 = newJObject()
  var body_617983 = newJObject()
  add(path_617982, "application-id", newJString(applicationId))
  if body != nil:
    body_617983 = body
  result = call_617981.call(path_617982, nil, nil, nil, body_617983)

var updateApnsChannel* = Call_UpdateApnsChannel_617968(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_617969, base: "/",
    url: url_UpdateApnsChannel_617970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_617954 = ref object of OpenApiRestCall_616850
proc url_GetApnsChannel_617956(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_617955(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617957 = path.getOrDefault("application-id")
  valid_617957 = validateParameter(valid_617957, JString, required = true,
                                 default = nil)
  if valid_617957 != nil:
    section.add "application-id", valid_617957
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
  var valid_617958 = header.getOrDefault("X-Amz-Date")
  valid_617958 = validateParameter(valid_617958, JString, required = false,
                                 default = nil)
  if valid_617958 != nil:
    section.add "X-Amz-Date", valid_617958
  var valid_617959 = header.getOrDefault("X-Amz-Security-Token")
  valid_617959 = validateParameter(valid_617959, JString, required = false,
                                 default = nil)
  if valid_617959 != nil:
    section.add "X-Amz-Security-Token", valid_617959
  var valid_617960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617960 = validateParameter(valid_617960, JString, required = false,
                                 default = nil)
  if valid_617960 != nil:
    section.add "X-Amz-Content-Sha256", valid_617960
  var valid_617961 = header.getOrDefault("X-Amz-Algorithm")
  valid_617961 = validateParameter(valid_617961, JString, required = false,
                                 default = nil)
  if valid_617961 != nil:
    section.add "X-Amz-Algorithm", valid_617961
  var valid_617962 = header.getOrDefault("X-Amz-Signature")
  valid_617962 = validateParameter(valid_617962, JString, required = false,
                                 default = nil)
  if valid_617962 != nil:
    section.add "X-Amz-Signature", valid_617962
  var valid_617963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617963 = validateParameter(valid_617963, JString, required = false,
                                 default = nil)
  if valid_617963 != nil:
    section.add "X-Amz-SignedHeaders", valid_617963
  var valid_617964 = header.getOrDefault("X-Amz-Credential")
  valid_617964 = validateParameter(valid_617964, JString, required = false,
                                 default = nil)
  if valid_617964 != nil:
    section.add "X-Amz-Credential", valid_617964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617965: Call_GetApnsChannel_617954; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_617965.validator(path, query, header, formData, body, _)
  let scheme = call_617965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617965.url(scheme.get, call_617965.host, call_617965.base,
                         call_617965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617965, url, valid, _)

proc call*(call_617966: Call_GetApnsChannel_617954; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_617967 = newJObject()
  add(path_617967, "application-id", newJString(applicationId))
  result = call_617966.call(path_617967, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_617954(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_617955, base: "/", url: url_GetApnsChannel_617956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_617984 = ref object of OpenApiRestCall_616850
proc url_DeleteApnsChannel_617986(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_617985(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617987 = path.getOrDefault("application-id")
  valid_617987 = validateParameter(valid_617987, JString, required = true,
                                 default = nil)
  if valid_617987 != nil:
    section.add "application-id", valid_617987
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
  var valid_617988 = header.getOrDefault("X-Amz-Date")
  valid_617988 = validateParameter(valid_617988, JString, required = false,
                                 default = nil)
  if valid_617988 != nil:
    section.add "X-Amz-Date", valid_617988
  var valid_617989 = header.getOrDefault("X-Amz-Security-Token")
  valid_617989 = validateParameter(valid_617989, JString, required = false,
                                 default = nil)
  if valid_617989 != nil:
    section.add "X-Amz-Security-Token", valid_617989
  var valid_617990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617990 = validateParameter(valid_617990, JString, required = false,
                                 default = nil)
  if valid_617990 != nil:
    section.add "X-Amz-Content-Sha256", valid_617990
  var valid_617991 = header.getOrDefault("X-Amz-Algorithm")
  valid_617991 = validateParameter(valid_617991, JString, required = false,
                                 default = nil)
  if valid_617991 != nil:
    section.add "X-Amz-Algorithm", valid_617991
  var valid_617992 = header.getOrDefault("X-Amz-Signature")
  valid_617992 = validateParameter(valid_617992, JString, required = false,
                                 default = nil)
  if valid_617992 != nil:
    section.add "X-Amz-Signature", valid_617992
  var valid_617993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617993 = validateParameter(valid_617993, JString, required = false,
                                 default = nil)
  if valid_617993 != nil:
    section.add "X-Amz-SignedHeaders", valid_617993
  var valid_617994 = header.getOrDefault("X-Amz-Credential")
  valid_617994 = validateParameter(valid_617994, JString, required = false,
                                 default = nil)
  if valid_617994 != nil:
    section.add "X-Amz-Credential", valid_617994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617995: Call_DeleteApnsChannel_617984; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_617995.validator(path, query, header, formData, body, _)
  let scheme = call_617995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617995.url(scheme.get, call_617995.host, call_617995.base,
                         call_617995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617995, url, valid, _)

proc call*(call_617996: Call_DeleteApnsChannel_617984; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_617997 = newJObject()
  add(path_617997, "application-id", newJString(applicationId))
  result = call_617996.call(path_617997, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_617984(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_617985, base: "/",
    url: url_DeleteApnsChannel_617986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_618012 = ref object of OpenApiRestCall_616850
proc url_UpdateApnsSandboxChannel_618014(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsSandboxChannel_618013(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618015 = path.getOrDefault("application-id")
  valid_618015 = validateParameter(valid_618015, JString, required = true,
                                 default = nil)
  if valid_618015 != nil:
    section.add "application-id", valid_618015
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
  var valid_618016 = header.getOrDefault("X-Amz-Date")
  valid_618016 = validateParameter(valid_618016, JString, required = false,
                                 default = nil)
  if valid_618016 != nil:
    section.add "X-Amz-Date", valid_618016
  var valid_618017 = header.getOrDefault("X-Amz-Security-Token")
  valid_618017 = validateParameter(valid_618017, JString, required = false,
                                 default = nil)
  if valid_618017 != nil:
    section.add "X-Amz-Security-Token", valid_618017
  var valid_618018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618018 = validateParameter(valid_618018, JString, required = false,
                                 default = nil)
  if valid_618018 != nil:
    section.add "X-Amz-Content-Sha256", valid_618018
  var valid_618019 = header.getOrDefault("X-Amz-Algorithm")
  valid_618019 = validateParameter(valid_618019, JString, required = false,
                                 default = nil)
  if valid_618019 != nil:
    section.add "X-Amz-Algorithm", valid_618019
  var valid_618020 = header.getOrDefault("X-Amz-Signature")
  valid_618020 = validateParameter(valid_618020, JString, required = false,
                                 default = nil)
  if valid_618020 != nil:
    section.add "X-Amz-Signature", valid_618020
  var valid_618021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618021 = validateParameter(valid_618021, JString, required = false,
                                 default = nil)
  if valid_618021 != nil:
    section.add "X-Amz-SignedHeaders", valid_618021
  var valid_618022 = header.getOrDefault("X-Amz-Credential")
  valid_618022 = validateParameter(valid_618022, JString, required = false,
                                 default = nil)
  if valid_618022 != nil:
    section.add "X-Amz-Credential", valid_618022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618024: Call_UpdateApnsSandboxChannel_618012; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_618024.validator(path, query, header, formData, body, _)
  let scheme = call_618024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618024.url(scheme.get, call_618024.host, call_618024.base,
                         call_618024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618024, url, valid, _)

proc call*(call_618025: Call_UpdateApnsSandboxChannel_618012;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618026 = newJObject()
  var body_618027 = newJObject()
  add(path_618026, "application-id", newJString(applicationId))
  if body != nil:
    body_618027 = body
  result = call_618025.call(path_618026, nil, nil, nil, body_618027)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_618012(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_618013, base: "/",
    url: url_UpdateApnsSandboxChannel_618014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_617998 = ref object of OpenApiRestCall_616850
proc url_GetApnsSandboxChannel_618000(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetApnsSandboxChannel_617999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618001 = path.getOrDefault("application-id")
  valid_618001 = validateParameter(valid_618001, JString, required = true,
                                 default = nil)
  if valid_618001 != nil:
    section.add "application-id", valid_618001
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
  var valid_618002 = header.getOrDefault("X-Amz-Date")
  valid_618002 = validateParameter(valid_618002, JString, required = false,
                                 default = nil)
  if valid_618002 != nil:
    section.add "X-Amz-Date", valid_618002
  var valid_618003 = header.getOrDefault("X-Amz-Security-Token")
  valid_618003 = validateParameter(valid_618003, JString, required = false,
                                 default = nil)
  if valid_618003 != nil:
    section.add "X-Amz-Security-Token", valid_618003
  var valid_618004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618004 = validateParameter(valid_618004, JString, required = false,
                                 default = nil)
  if valid_618004 != nil:
    section.add "X-Amz-Content-Sha256", valid_618004
  var valid_618005 = header.getOrDefault("X-Amz-Algorithm")
  valid_618005 = validateParameter(valid_618005, JString, required = false,
                                 default = nil)
  if valid_618005 != nil:
    section.add "X-Amz-Algorithm", valid_618005
  var valid_618006 = header.getOrDefault("X-Amz-Signature")
  valid_618006 = validateParameter(valid_618006, JString, required = false,
                                 default = nil)
  if valid_618006 != nil:
    section.add "X-Amz-Signature", valid_618006
  var valid_618007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618007 = validateParameter(valid_618007, JString, required = false,
                                 default = nil)
  if valid_618007 != nil:
    section.add "X-Amz-SignedHeaders", valid_618007
  var valid_618008 = header.getOrDefault("X-Amz-Credential")
  valid_618008 = validateParameter(valid_618008, JString, required = false,
                                 default = nil)
  if valid_618008 != nil:
    section.add "X-Amz-Credential", valid_618008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618009: Call_GetApnsSandboxChannel_617998; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_618009.validator(path, query, header, formData, body, _)
  let scheme = call_618009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618009.url(scheme.get, call_618009.host, call_618009.base,
                         call_618009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618009, url, valid, _)

proc call*(call_618010: Call_GetApnsSandboxChannel_617998; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618011 = newJObject()
  add(path_618011, "application-id", newJString(applicationId))
  result = call_618010.call(path_618011, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_617998(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_617999, base: "/",
    url: url_GetApnsSandboxChannel_618000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_618028 = ref object of OpenApiRestCall_616850
proc url_DeleteApnsSandboxChannel_618030(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsSandboxChannel_618029(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618031 = path.getOrDefault("application-id")
  valid_618031 = validateParameter(valid_618031, JString, required = true,
                                 default = nil)
  if valid_618031 != nil:
    section.add "application-id", valid_618031
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
  var valid_618032 = header.getOrDefault("X-Amz-Date")
  valid_618032 = validateParameter(valid_618032, JString, required = false,
                                 default = nil)
  if valid_618032 != nil:
    section.add "X-Amz-Date", valid_618032
  var valid_618033 = header.getOrDefault("X-Amz-Security-Token")
  valid_618033 = validateParameter(valid_618033, JString, required = false,
                                 default = nil)
  if valid_618033 != nil:
    section.add "X-Amz-Security-Token", valid_618033
  var valid_618034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618034 = validateParameter(valid_618034, JString, required = false,
                                 default = nil)
  if valid_618034 != nil:
    section.add "X-Amz-Content-Sha256", valid_618034
  var valid_618035 = header.getOrDefault("X-Amz-Algorithm")
  valid_618035 = validateParameter(valid_618035, JString, required = false,
                                 default = nil)
  if valid_618035 != nil:
    section.add "X-Amz-Algorithm", valid_618035
  var valid_618036 = header.getOrDefault("X-Amz-Signature")
  valid_618036 = validateParameter(valid_618036, JString, required = false,
                                 default = nil)
  if valid_618036 != nil:
    section.add "X-Amz-Signature", valid_618036
  var valid_618037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618037 = validateParameter(valid_618037, JString, required = false,
                                 default = nil)
  if valid_618037 != nil:
    section.add "X-Amz-SignedHeaders", valid_618037
  var valid_618038 = header.getOrDefault("X-Amz-Credential")
  valid_618038 = validateParameter(valid_618038, JString, required = false,
                                 default = nil)
  if valid_618038 != nil:
    section.add "X-Amz-Credential", valid_618038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618039: Call_DeleteApnsSandboxChannel_618028; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618039.validator(path, query, header, formData, body, _)
  let scheme = call_618039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618039.url(scheme.get, call_618039.host, call_618039.base,
                         call_618039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618039, url, valid, _)

proc call*(call_618040: Call_DeleteApnsSandboxChannel_618028; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618041 = newJObject()
  add(path_618041, "application-id", newJString(applicationId))
  result = call_618040.call(path_618041, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_618028(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_618029, base: "/",
    url: url_DeleteApnsSandboxChannel_618030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_618056 = ref object of OpenApiRestCall_616850
proc url_UpdateApnsVoipChannel_618058(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_618057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618059 = path.getOrDefault("application-id")
  valid_618059 = validateParameter(valid_618059, JString, required = true,
                                 default = nil)
  if valid_618059 != nil:
    section.add "application-id", valid_618059
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
  var valid_618060 = header.getOrDefault("X-Amz-Date")
  valid_618060 = validateParameter(valid_618060, JString, required = false,
                                 default = nil)
  if valid_618060 != nil:
    section.add "X-Amz-Date", valid_618060
  var valid_618061 = header.getOrDefault("X-Amz-Security-Token")
  valid_618061 = validateParameter(valid_618061, JString, required = false,
                                 default = nil)
  if valid_618061 != nil:
    section.add "X-Amz-Security-Token", valid_618061
  var valid_618062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618062 = validateParameter(valid_618062, JString, required = false,
                                 default = nil)
  if valid_618062 != nil:
    section.add "X-Amz-Content-Sha256", valid_618062
  var valid_618063 = header.getOrDefault("X-Amz-Algorithm")
  valid_618063 = validateParameter(valid_618063, JString, required = false,
                                 default = nil)
  if valid_618063 != nil:
    section.add "X-Amz-Algorithm", valid_618063
  var valid_618064 = header.getOrDefault("X-Amz-Signature")
  valid_618064 = validateParameter(valid_618064, JString, required = false,
                                 default = nil)
  if valid_618064 != nil:
    section.add "X-Amz-Signature", valid_618064
  var valid_618065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618065 = validateParameter(valid_618065, JString, required = false,
                                 default = nil)
  if valid_618065 != nil:
    section.add "X-Amz-SignedHeaders", valid_618065
  var valid_618066 = header.getOrDefault("X-Amz-Credential")
  valid_618066 = validateParameter(valid_618066, JString, required = false,
                                 default = nil)
  if valid_618066 != nil:
    section.add "X-Amz-Credential", valid_618066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618068: Call_UpdateApnsVoipChannel_618056; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_618068.validator(path, query, header, formData, body, _)
  let scheme = call_618068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618068.url(scheme.get, call_618068.host, call_618068.base,
                         call_618068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618068, url, valid, _)

proc call*(call_618069: Call_UpdateApnsVoipChannel_618056; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618070 = newJObject()
  var body_618071 = newJObject()
  add(path_618070, "application-id", newJString(applicationId))
  if body != nil:
    body_618071 = body
  result = call_618069.call(path_618070, nil, nil, nil, body_618071)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_618056(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_618057, base: "/",
    url: url_UpdateApnsVoipChannel_618058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_618042 = ref object of OpenApiRestCall_616850
proc url_GetApnsVoipChannel_618044(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_618043(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618045 = path.getOrDefault("application-id")
  valid_618045 = validateParameter(valid_618045, JString, required = true,
                                 default = nil)
  if valid_618045 != nil:
    section.add "application-id", valid_618045
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
  var valid_618046 = header.getOrDefault("X-Amz-Date")
  valid_618046 = validateParameter(valid_618046, JString, required = false,
                                 default = nil)
  if valid_618046 != nil:
    section.add "X-Amz-Date", valid_618046
  var valid_618047 = header.getOrDefault("X-Amz-Security-Token")
  valid_618047 = validateParameter(valid_618047, JString, required = false,
                                 default = nil)
  if valid_618047 != nil:
    section.add "X-Amz-Security-Token", valid_618047
  var valid_618048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618048 = validateParameter(valid_618048, JString, required = false,
                                 default = nil)
  if valid_618048 != nil:
    section.add "X-Amz-Content-Sha256", valid_618048
  var valid_618049 = header.getOrDefault("X-Amz-Algorithm")
  valid_618049 = validateParameter(valid_618049, JString, required = false,
                                 default = nil)
  if valid_618049 != nil:
    section.add "X-Amz-Algorithm", valid_618049
  var valid_618050 = header.getOrDefault("X-Amz-Signature")
  valid_618050 = validateParameter(valid_618050, JString, required = false,
                                 default = nil)
  if valid_618050 != nil:
    section.add "X-Amz-Signature", valid_618050
  var valid_618051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618051 = validateParameter(valid_618051, JString, required = false,
                                 default = nil)
  if valid_618051 != nil:
    section.add "X-Amz-SignedHeaders", valid_618051
  var valid_618052 = header.getOrDefault("X-Amz-Credential")
  valid_618052 = validateParameter(valid_618052, JString, required = false,
                                 default = nil)
  if valid_618052 != nil:
    section.add "X-Amz-Credential", valid_618052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618053: Call_GetApnsVoipChannel_618042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_618053.validator(path, query, header, formData, body, _)
  let scheme = call_618053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618053.url(scheme.get, call_618053.host, call_618053.base,
                         call_618053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618053, url, valid, _)

proc call*(call_618054: Call_GetApnsVoipChannel_618042; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618055 = newJObject()
  add(path_618055, "application-id", newJString(applicationId))
  result = call_618054.call(path_618055, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_618042(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_618043, base: "/",
    url: url_GetApnsVoipChannel_618044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_618072 = ref object of OpenApiRestCall_616850
proc url_DeleteApnsVoipChannel_618074(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_618073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618075 = path.getOrDefault("application-id")
  valid_618075 = validateParameter(valid_618075, JString, required = true,
                                 default = nil)
  if valid_618075 != nil:
    section.add "application-id", valid_618075
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
  var valid_618076 = header.getOrDefault("X-Amz-Date")
  valid_618076 = validateParameter(valid_618076, JString, required = false,
                                 default = nil)
  if valid_618076 != nil:
    section.add "X-Amz-Date", valid_618076
  var valid_618077 = header.getOrDefault("X-Amz-Security-Token")
  valid_618077 = validateParameter(valid_618077, JString, required = false,
                                 default = nil)
  if valid_618077 != nil:
    section.add "X-Amz-Security-Token", valid_618077
  var valid_618078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618078 = validateParameter(valid_618078, JString, required = false,
                                 default = nil)
  if valid_618078 != nil:
    section.add "X-Amz-Content-Sha256", valid_618078
  var valid_618079 = header.getOrDefault("X-Amz-Algorithm")
  valid_618079 = validateParameter(valid_618079, JString, required = false,
                                 default = nil)
  if valid_618079 != nil:
    section.add "X-Amz-Algorithm", valid_618079
  var valid_618080 = header.getOrDefault("X-Amz-Signature")
  valid_618080 = validateParameter(valid_618080, JString, required = false,
                                 default = nil)
  if valid_618080 != nil:
    section.add "X-Amz-Signature", valid_618080
  var valid_618081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618081 = validateParameter(valid_618081, JString, required = false,
                                 default = nil)
  if valid_618081 != nil:
    section.add "X-Amz-SignedHeaders", valid_618081
  var valid_618082 = header.getOrDefault("X-Amz-Credential")
  valid_618082 = validateParameter(valid_618082, JString, required = false,
                                 default = nil)
  if valid_618082 != nil:
    section.add "X-Amz-Credential", valid_618082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618083: Call_DeleteApnsVoipChannel_618072; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618083.validator(path, query, header, formData, body, _)
  let scheme = call_618083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618083.url(scheme.get, call_618083.host, call_618083.base,
                         call_618083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618083, url, valid, _)

proc call*(call_618084: Call_DeleteApnsVoipChannel_618072; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618085 = newJObject()
  add(path_618085, "application-id", newJString(applicationId))
  result = call_618084.call(path_618085, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_618072(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_618073, base: "/",
    url: url_DeleteApnsVoipChannel_618074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_618100 = ref object of OpenApiRestCall_616850
proc url_UpdateApnsVoipSandboxChannel_618102(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_618101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618103 = path.getOrDefault("application-id")
  valid_618103 = validateParameter(valid_618103, JString, required = true,
                                 default = nil)
  if valid_618103 != nil:
    section.add "application-id", valid_618103
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
  var valid_618104 = header.getOrDefault("X-Amz-Date")
  valid_618104 = validateParameter(valid_618104, JString, required = false,
                                 default = nil)
  if valid_618104 != nil:
    section.add "X-Amz-Date", valid_618104
  var valid_618105 = header.getOrDefault("X-Amz-Security-Token")
  valid_618105 = validateParameter(valid_618105, JString, required = false,
                                 default = nil)
  if valid_618105 != nil:
    section.add "X-Amz-Security-Token", valid_618105
  var valid_618106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618106 = validateParameter(valid_618106, JString, required = false,
                                 default = nil)
  if valid_618106 != nil:
    section.add "X-Amz-Content-Sha256", valid_618106
  var valid_618107 = header.getOrDefault("X-Amz-Algorithm")
  valid_618107 = validateParameter(valid_618107, JString, required = false,
                                 default = nil)
  if valid_618107 != nil:
    section.add "X-Amz-Algorithm", valid_618107
  var valid_618108 = header.getOrDefault("X-Amz-Signature")
  valid_618108 = validateParameter(valid_618108, JString, required = false,
                                 default = nil)
  if valid_618108 != nil:
    section.add "X-Amz-Signature", valid_618108
  var valid_618109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618109 = validateParameter(valid_618109, JString, required = false,
                                 default = nil)
  if valid_618109 != nil:
    section.add "X-Amz-SignedHeaders", valid_618109
  var valid_618110 = header.getOrDefault("X-Amz-Credential")
  valid_618110 = validateParameter(valid_618110, JString, required = false,
                                 default = nil)
  if valid_618110 != nil:
    section.add "X-Amz-Credential", valid_618110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618112: Call_UpdateApnsVoipSandboxChannel_618100;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_618112.validator(path, query, header, formData, body, _)
  let scheme = call_618112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618112.url(scheme.get, call_618112.host, call_618112.base,
                         call_618112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618112, url, valid, _)

proc call*(call_618113: Call_UpdateApnsVoipSandboxChannel_618100;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618114 = newJObject()
  var body_618115 = newJObject()
  add(path_618114, "application-id", newJString(applicationId))
  if body != nil:
    body_618115 = body
  result = call_618113.call(path_618114, nil, nil, nil, body_618115)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_618100(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_618101, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_618102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_618086 = ref object of OpenApiRestCall_616850
proc url_GetApnsVoipSandboxChannel_618088(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_618087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618089 = path.getOrDefault("application-id")
  valid_618089 = validateParameter(valid_618089, JString, required = true,
                                 default = nil)
  if valid_618089 != nil:
    section.add "application-id", valid_618089
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
  var valid_618090 = header.getOrDefault("X-Amz-Date")
  valid_618090 = validateParameter(valid_618090, JString, required = false,
                                 default = nil)
  if valid_618090 != nil:
    section.add "X-Amz-Date", valid_618090
  var valid_618091 = header.getOrDefault("X-Amz-Security-Token")
  valid_618091 = validateParameter(valid_618091, JString, required = false,
                                 default = nil)
  if valid_618091 != nil:
    section.add "X-Amz-Security-Token", valid_618091
  var valid_618092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618092 = validateParameter(valid_618092, JString, required = false,
                                 default = nil)
  if valid_618092 != nil:
    section.add "X-Amz-Content-Sha256", valid_618092
  var valid_618093 = header.getOrDefault("X-Amz-Algorithm")
  valid_618093 = validateParameter(valid_618093, JString, required = false,
                                 default = nil)
  if valid_618093 != nil:
    section.add "X-Amz-Algorithm", valid_618093
  var valid_618094 = header.getOrDefault("X-Amz-Signature")
  valid_618094 = validateParameter(valid_618094, JString, required = false,
                                 default = nil)
  if valid_618094 != nil:
    section.add "X-Amz-Signature", valid_618094
  var valid_618095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618095 = validateParameter(valid_618095, JString, required = false,
                                 default = nil)
  if valid_618095 != nil:
    section.add "X-Amz-SignedHeaders", valid_618095
  var valid_618096 = header.getOrDefault("X-Amz-Credential")
  valid_618096 = validateParameter(valid_618096, JString, required = false,
                                 default = nil)
  if valid_618096 != nil:
    section.add "X-Amz-Credential", valid_618096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618097: Call_GetApnsVoipSandboxChannel_618086;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_618097.validator(path, query, header, formData, body, _)
  let scheme = call_618097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618097.url(scheme.get, call_618097.host, call_618097.base,
                         call_618097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618097, url, valid, _)

proc call*(call_618098: Call_GetApnsVoipSandboxChannel_618086;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618099 = newJObject()
  add(path_618099, "application-id", newJString(applicationId))
  result = call_618098.call(path_618099, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_618086(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_618087, base: "/",
    url: url_GetApnsVoipSandboxChannel_618088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_618116 = ref object of OpenApiRestCall_616850
proc url_DeleteApnsVoipSandboxChannel_618118(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_618117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618119 = path.getOrDefault("application-id")
  valid_618119 = validateParameter(valid_618119, JString, required = true,
                                 default = nil)
  if valid_618119 != nil:
    section.add "application-id", valid_618119
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
  var valid_618120 = header.getOrDefault("X-Amz-Date")
  valid_618120 = validateParameter(valid_618120, JString, required = false,
                                 default = nil)
  if valid_618120 != nil:
    section.add "X-Amz-Date", valid_618120
  var valid_618121 = header.getOrDefault("X-Amz-Security-Token")
  valid_618121 = validateParameter(valid_618121, JString, required = false,
                                 default = nil)
  if valid_618121 != nil:
    section.add "X-Amz-Security-Token", valid_618121
  var valid_618122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618122 = validateParameter(valid_618122, JString, required = false,
                                 default = nil)
  if valid_618122 != nil:
    section.add "X-Amz-Content-Sha256", valid_618122
  var valid_618123 = header.getOrDefault("X-Amz-Algorithm")
  valid_618123 = validateParameter(valid_618123, JString, required = false,
                                 default = nil)
  if valid_618123 != nil:
    section.add "X-Amz-Algorithm", valid_618123
  var valid_618124 = header.getOrDefault("X-Amz-Signature")
  valid_618124 = validateParameter(valid_618124, JString, required = false,
                                 default = nil)
  if valid_618124 != nil:
    section.add "X-Amz-Signature", valid_618124
  var valid_618125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618125 = validateParameter(valid_618125, JString, required = false,
                                 default = nil)
  if valid_618125 != nil:
    section.add "X-Amz-SignedHeaders", valid_618125
  var valid_618126 = header.getOrDefault("X-Amz-Credential")
  valid_618126 = validateParameter(valid_618126, JString, required = false,
                                 default = nil)
  if valid_618126 != nil:
    section.add "X-Amz-Credential", valid_618126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618127: Call_DeleteApnsVoipSandboxChannel_618116;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618127.validator(path, query, header, formData, body, _)
  let scheme = call_618127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618127.url(scheme.get, call_618127.host, call_618127.base,
                         call_618127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618127, url, valid, _)

proc call*(call_618128: Call_DeleteApnsVoipSandboxChannel_618116;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618129 = newJObject()
  add(path_618129, "application-id", newJString(applicationId))
  result = call_618128.call(path_618129, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_618116(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_618117, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_618118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_618130 = ref object of OpenApiRestCall_616850
proc url_GetApp_618132(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_618131(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618133 = path.getOrDefault("application-id")
  valid_618133 = validateParameter(valid_618133, JString, required = true,
                                 default = nil)
  if valid_618133 != nil:
    section.add "application-id", valid_618133
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
  var valid_618134 = header.getOrDefault("X-Amz-Date")
  valid_618134 = validateParameter(valid_618134, JString, required = false,
                                 default = nil)
  if valid_618134 != nil:
    section.add "X-Amz-Date", valid_618134
  var valid_618135 = header.getOrDefault("X-Amz-Security-Token")
  valid_618135 = validateParameter(valid_618135, JString, required = false,
                                 default = nil)
  if valid_618135 != nil:
    section.add "X-Amz-Security-Token", valid_618135
  var valid_618136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618136 = validateParameter(valid_618136, JString, required = false,
                                 default = nil)
  if valid_618136 != nil:
    section.add "X-Amz-Content-Sha256", valid_618136
  var valid_618137 = header.getOrDefault("X-Amz-Algorithm")
  valid_618137 = validateParameter(valid_618137, JString, required = false,
                                 default = nil)
  if valid_618137 != nil:
    section.add "X-Amz-Algorithm", valid_618137
  var valid_618138 = header.getOrDefault("X-Amz-Signature")
  valid_618138 = validateParameter(valid_618138, JString, required = false,
                                 default = nil)
  if valid_618138 != nil:
    section.add "X-Amz-Signature", valid_618138
  var valid_618139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618139 = validateParameter(valid_618139, JString, required = false,
                                 default = nil)
  if valid_618139 != nil:
    section.add "X-Amz-SignedHeaders", valid_618139
  var valid_618140 = header.getOrDefault("X-Amz-Credential")
  valid_618140 = validateParameter(valid_618140, JString, required = false,
                                 default = nil)
  if valid_618140 != nil:
    section.add "X-Amz-Credential", valid_618140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618141: Call_GetApp_618130; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_618141.validator(path, query, header, formData, body, _)
  let scheme = call_618141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618141.url(scheme.get, call_618141.host, call_618141.base,
                         call_618141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618141, url, valid, _)

proc call*(call_618142: Call_GetApp_618130; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618143 = newJObject()
  add(path_618143, "application-id", newJString(applicationId))
  result = call_618142.call(path_618143, nil, nil, nil, nil)

var getApp* = Call_GetApp_618130(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_618131, base: "/",
                              url: url_GetApp_618132,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_618144 = ref object of OpenApiRestCall_616850
proc url_DeleteApp_618146(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_618145(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618147 = path.getOrDefault("application-id")
  valid_618147 = validateParameter(valid_618147, JString, required = true,
                                 default = nil)
  if valid_618147 != nil:
    section.add "application-id", valid_618147
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
  var valid_618148 = header.getOrDefault("X-Amz-Date")
  valid_618148 = validateParameter(valid_618148, JString, required = false,
                                 default = nil)
  if valid_618148 != nil:
    section.add "X-Amz-Date", valid_618148
  var valid_618149 = header.getOrDefault("X-Amz-Security-Token")
  valid_618149 = validateParameter(valid_618149, JString, required = false,
                                 default = nil)
  if valid_618149 != nil:
    section.add "X-Amz-Security-Token", valid_618149
  var valid_618150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618150 = validateParameter(valid_618150, JString, required = false,
                                 default = nil)
  if valid_618150 != nil:
    section.add "X-Amz-Content-Sha256", valid_618150
  var valid_618151 = header.getOrDefault("X-Amz-Algorithm")
  valid_618151 = validateParameter(valid_618151, JString, required = false,
                                 default = nil)
  if valid_618151 != nil:
    section.add "X-Amz-Algorithm", valid_618151
  var valid_618152 = header.getOrDefault("X-Amz-Signature")
  valid_618152 = validateParameter(valid_618152, JString, required = false,
                                 default = nil)
  if valid_618152 != nil:
    section.add "X-Amz-Signature", valid_618152
  var valid_618153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618153 = validateParameter(valid_618153, JString, required = false,
                                 default = nil)
  if valid_618153 != nil:
    section.add "X-Amz-SignedHeaders", valid_618153
  var valid_618154 = header.getOrDefault("X-Amz-Credential")
  valid_618154 = validateParameter(valid_618154, JString, required = false,
                                 default = nil)
  if valid_618154 != nil:
    section.add "X-Amz-Credential", valid_618154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618155: Call_DeleteApp_618144; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_618155.validator(path, query, header, formData, body, _)
  let scheme = call_618155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618155.url(scheme.get, call_618155.host, call_618155.base,
                         call_618155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618155, url, valid, _)

proc call*(call_618156: Call_DeleteApp_618144; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618157 = newJObject()
  add(path_618157, "application-id", newJString(applicationId))
  result = call_618156.call(path_618157, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_618144(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_618145,
                                    base: "/", url: url_DeleteApp_618146,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_618172 = ref object of OpenApiRestCall_616850
proc url_UpdateBaiduChannel_618174(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_618173(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618175 = path.getOrDefault("application-id")
  valid_618175 = validateParameter(valid_618175, JString, required = true,
                                 default = nil)
  if valid_618175 != nil:
    section.add "application-id", valid_618175
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
  var valid_618176 = header.getOrDefault("X-Amz-Date")
  valid_618176 = validateParameter(valid_618176, JString, required = false,
                                 default = nil)
  if valid_618176 != nil:
    section.add "X-Amz-Date", valid_618176
  var valid_618177 = header.getOrDefault("X-Amz-Security-Token")
  valid_618177 = validateParameter(valid_618177, JString, required = false,
                                 default = nil)
  if valid_618177 != nil:
    section.add "X-Amz-Security-Token", valid_618177
  var valid_618178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618178 = validateParameter(valid_618178, JString, required = false,
                                 default = nil)
  if valid_618178 != nil:
    section.add "X-Amz-Content-Sha256", valid_618178
  var valid_618179 = header.getOrDefault("X-Amz-Algorithm")
  valid_618179 = validateParameter(valid_618179, JString, required = false,
                                 default = nil)
  if valid_618179 != nil:
    section.add "X-Amz-Algorithm", valid_618179
  var valid_618180 = header.getOrDefault("X-Amz-Signature")
  valid_618180 = validateParameter(valid_618180, JString, required = false,
                                 default = nil)
  if valid_618180 != nil:
    section.add "X-Amz-Signature", valid_618180
  var valid_618181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618181 = validateParameter(valid_618181, JString, required = false,
                                 default = nil)
  if valid_618181 != nil:
    section.add "X-Amz-SignedHeaders", valid_618181
  var valid_618182 = header.getOrDefault("X-Amz-Credential")
  valid_618182 = validateParameter(valid_618182, JString, required = false,
                                 default = nil)
  if valid_618182 != nil:
    section.add "X-Amz-Credential", valid_618182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618184: Call_UpdateBaiduChannel_618172; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_618184.validator(path, query, header, formData, body, _)
  let scheme = call_618184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618184.url(scheme.get, call_618184.host, call_618184.base,
                         call_618184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618184, url, valid, _)

proc call*(call_618185: Call_UpdateBaiduChannel_618172; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618186 = newJObject()
  var body_618187 = newJObject()
  add(path_618186, "application-id", newJString(applicationId))
  if body != nil:
    body_618187 = body
  result = call_618185.call(path_618186, nil, nil, nil, body_618187)

var updateBaiduChannel* = Call_UpdateBaiduChannel_618172(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_618173, base: "/",
    url: url_UpdateBaiduChannel_618174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_618158 = ref object of OpenApiRestCall_616850
proc url_GetBaiduChannel_618160(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_618159(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618161 = path.getOrDefault("application-id")
  valid_618161 = validateParameter(valid_618161, JString, required = true,
                                 default = nil)
  if valid_618161 != nil:
    section.add "application-id", valid_618161
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
  var valid_618162 = header.getOrDefault("X-Amz-Date")
  valid_618162 = validateParameter(valid_618162, JString, required = false,
                                 default = nil)
  if valid_618162 != nil:
    section.add "X-Amz-Date", valid_618162
  var valid_618163 = header.getOrDefault("X-Amz-Security-Token")
  valid_618163 = validateParameter(valid_618163, JString, required = false,
                                 default = nil)
  if valid_618163 != nil:
    section.add "X-Amz-Security-Token", valid_618163
  var valid_618164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618164 = validateParameter(valid_618164, JString, required = false,
                                 default = nil)
  if valid_618164 != nil:
    section.add "X-Amz-Content-Sha256", valid_618164
  var valid_618165 = header.getOrDefault("X-Amz-Algorithm")
  valid_618165 = validateParameter(valid_618165, JString, required = false,
                                 default = nil)
  if valid_618165 != nil:
    section.add "X-Amz-Algorithm", valid_618165
  var valid_618166 = header.getOrDefault("X-Amz-Signature")
  valid_618166 = validateParameter(valid_618166, JString, required = false,
                                 default = nil)
  if valid_618166 != nil:
    section.add "X-Amz-Signature", valid_618166
  var valid_618167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618167 = validateParameter(valid_618167, JString, required = false,
                                 default = nil)
  if valid_618167 != nil:
    section.add "X-Amz-SignedHeaders", valid_618167
  var valid_618168 = header.getOrDefault("X-Amz-Credential")
  valid_618168 = validateParameter(valid_618168, JString, required = false,
                                 default = nil)
  if valid_618168 != nil:
    section.add "X-Amz-Credential", valid_618168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618169: Call_GetBaiduChannel_618158; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_618169.validator(path, query, header, formData, body, _)
  let scheme = call_618169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618169.url(scheme.get, call_618169.host, call_618169.base,
                         call_618169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618169, url, valid, _)

proc call*(call_618170: Call_GetBaiduChannel_618158; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618171 = newJObject()
  add(path_618171, "application-id", newJString(applicationId))
  result = call_618170.call(path_618171, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_618158(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_618159, base: "/", url: url_GetBaiduChannel_618160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_618188 = ref object of OpenApiRestCall_616850
proc url_DeleteBaiduChannel_618190(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_618189(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618191 = path.getOrDefault("application-id")
  valid_618191 = validateParameter(valid_618191, JString, required = true,
                                 default = nil)
  if valid_618191 != nil:
    section.add "application-id", valid_618191
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
  var valid_618192 = header.getOrDefault("X-Amz-Date")
  valid_618192 = validateParameter(valid_618192, JString, required = false,
                                 default = nil)
  if valid_618192 != nil:
    section.add "X-Amz-Date", valid_618192
  var valid_618193 = header.getOrDefault("X-Amz-Security-Token")
  valid_618193 = validateParameter(valid_618193, JString, required = false,
                                 default = nil)
  if valid_618193 != nil:
    section.add "X-Amz-Security-Token", valid_618193
  var valid_618194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618194 = validateParameter(valid_618194, JString, required = false,
                                 default = nil)
  if valid_618194 != nil:
    section.add "X-Amz-Content-Sha256", valid_618194
  var valid_618195 = header.getOrDefault("X-Amz-Algorithm")
  valid_618195 = validateParameter(valid_618195, JString, required = false,
                                 default = nil)
  if valid_618195 != nil:
    section.add "X-Amz-Algorithm", valid_618195
  var valid_618196 = header.getOrDefault("X-Amz-Signature")
  valid_618196 = validateParameter(valid_618196, JString, required = false,
                                 default = nil)
  if valid_618196 != nil:
    section.add "X-Amz-Signature", valid_618196
  var valid_618197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618197 = validateParameter(valid_618197, JString, required = false,
                                 default = nil)
  if valid_618197 != nil:
    section.add "X-Amz-SignedHeaders", valid_618197
  var valid_618198 = header.getOrDefault("X-Amz-Credential")
  valid_618198 = validateParameter(valid_618198, JString, required = false,
                                 default = nil)
  if valid_618198 != nil:
    section.add "X-Amz-Credential", valid_618198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618199: Call_DeleteBaiduChannel_618188; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618199.validator(path, query, header, formData, body, _)
  let scheme = call_618199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618199.url(scheme.get, call_618199.host, call_618199.base,
                         call_618199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618199, url, valid, _)

proc call*(call_618200: Call_DeleteBaiduChannel_618188; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618201 = newJObject()
  add(path_618201, "application-id", newJString(applicationId))
  result = call_618200.call(path_618201, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_618188(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_618189, base: "/",
    url: url_DeleteBaiduChannel_618190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_618217 = ref object of OpenApiRestCall_616850
proc url_UpdateCampaign_618219(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_618218(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618220 = path.getOrDefault("application-id")
  valid_618220 = validateParameter(valid_618220, JString, required = true,
                                 default = nil)
  if valid_618220 != nil:
    section.add "application-id", valid_618220
  var valid_618221 = path.getOrDefault("campaign-id")
  valid_618221 = validateParameter(valid_618221, JString, required = true,
                                 default = nil)
  if valid_618221 != nil:
    section.add "campaign-id", valid_618221
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
  var valid_618222 = header.getOrDefault("X-Amz-Date")
  valid_618222 = validateParameter(valid_618222, JString, required = false,
                                 default = nil)
  if valid_618222 != nil:
    section.add "X-Amz-Date", valid_618222
  var valid_618223 = header.getOrDefault("X-Amz-Security-Token")
  valid_618223 = validateParameter(valid_618223, JString, required = false,
                                 default = nil)
  if valid_618223 != nil:
    section.add "X-Amz-Security-Token", valid_618223
  var valid_618224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618224 = validateParameter(valid_618224, JString, required = false,
                                 default = nil)
  if valid_618224 != nil:
    section.add "X-Amz-Content-Sha256", valid_618224
  var valid_618225 = header.getOrDefault("X-Amz-Algorithm")
  valid_618225 = validateParameter(valid_618225, JString, required = false,
                                 default = nil)
  if valid_618225 != nil:
    section.add "X-Amz-Algorithm", valid_618225
  var valid_618226 = header.getOrDefault("X-Amz-Signature")
  valid_618226 = validateParameter(valid_618226, JString, required = false,
                                 default = nil)
  if valid_618226 != nil:
    section.add "X-Amz-Signature", valid_618226
  var valid_618227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618227 = validateParameter(valid_618227, JString, required = false,
                                 default = nil)
  if valid_618227 != nil:
    section.add "X-Amz-SignedHeaders", valid_618227
  var valid_618228 = header.getOrDefault("X-Amz-Credential")
  valid_618228 = validateParameter(valid_618228, JString, required = false,
                                 default = nil)
  if valid_618228 != nil:
    section.add "X-Amz-Credential", valid_618228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618230: Call_UpdateCampaign_618217; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_618230.validator(path, query, header, formData, body, _)
  let scheme = call_618230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618230.url(scheme.get, call_618230.host, call_618230.base,
                         call_618230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618230, url, valid, _)

proc call*(call_618231: Call_UpdateCampaign_618217; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_618232 = newJObject()
  var body_618233 = newJObject()
  add(path_618232, "application-id", newJString(applicationId))
  if body != nil:
    body_618233 = body
  add(path_618232, "campaign-id", newJString(campaignId))
  result = call_618231.call(path_618232, nil, nil, nil, body_618233)

var updateCampaign* = Call_UpdateCampaign_618217(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_618218, base: "/", url: url_UpdateCampaign_618219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_618202 = ref object of OpenApiRestCall_616850
proc url_GetCampaign_618204(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_618203(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618205 = path.getOrDefault("application-id")
  valid_618205 = validateParameter(valid_618205, JString, required = true,
                                 default = nil)
  if valid_618205 != nil:
    section.add "application-id", valid_618205
  var valid_618206 = path.getOrDefault("campaign-id")
  valid_618206 = validateParameter(valid_618206, JString, required = true,
                                 default = nil)
  if valid_618206 != nil:
    section.add "campaign-id", valid_618206
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
  var valid_618207 = header.getOrDefault("X-Amz-Date")
  valid_618207 = validateParameter(valid_618207, JString, required = false,
                                 default = nil)
  if valid_618207 != nil:
    section.add "X-Amz-Date", valid_618207
  var valid_618208 = header.getOrDefault("X-Amz-Security-Token")
  valid_618208 = validateParameter(valid_618208, JString, required = false,
                                 default = nil)
  if valid_618208 != nil:
    section.add "X-Amz-Security-Token", valid_618208
  var valid_618209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618209 = validateParameter(valid_618209, JString, required = false,
                                 default = nil)
  if valid_618209 != nil:
    section.add "X-Amz-Content-Sha256", valid_618209
  var valid_618210 = header.getOrDefault("X-Amz-Algorithm")
  valid_618210 = validateParameter(valid_618210, JString, required = false,
                                 default = nil)
  if valid_618210 != nil:
    section.add "X-Amz-Algorithm", valid_618210
  var valid_618211 = header.getOrDefault("X-Amz-Signature")
  valid_618211 = validateParameter(valid_618211, JString, required = false,
                                 default = nil)
  if valid_618211 != nil:
    section.add "X-Amz-Signature", valid_618211
  var valid_618212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618212 = validateParameter(valid_618212, JString, required = false,
                                 default = nil)
  if valid_618212 != nil:
    section.add "X-Amz-SignedHeaders", valid_618212
  var valid_618213 = header.getOrDefault("X-Amz-Credential")
  valid_618213 = validateParameter(valid_618213, JString, required = false,
                                 default = nil)
  if valid_618213 != nil:
    section.add "X-Amz-Credential", valid_618213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618214: Call_GetCampaign_618202; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_618214.validator(path, query, header, formData, body, _)
  let scheme = call_618214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618214.url(scheme.get, call_618214.host, call_618214.base,
                         call_618214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618214, url, valid, _)

proc call*(call_618215: Call_GetCampaign_618202; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_618216 = newJObject()
  add(path_618216, "application-id", newJString(applicationId))
  add(path_618216, "campaign-id", newJString(campaignId))
  result = call_618215.call(path_618216, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_618202(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_618203,
                                        base: "/", url: url_GetCampaign_618204,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_618234 = ref object of OpenApiRestCall_616850
proc url_DeleteCampaign_618236(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_618235(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618237 = path.getOrDefault("application-id")
  valid_618237 = validateParameter(valid_618237, JString, required = true,
                                 default = nil)
  if valid_618237 != nil:
    section.add "application-id", valid_618237
  var valid_618238 = path.getOrDefault("campaign-id")
  valid_618238 = validateParameter(valid_618238, JString, required = true,
                                 default = nil)
  if valid_618238 != nil:
    section.add "campaign-id", valid_618238
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
  var valid_618239 = header.getOrDefault("X-Amz-Date")
  valid_618239 = validateParameter(valid_618239, JString, required = false,
                                 default = nil)
  if valid_618239 != nil:
    section.add "X-Amz-Date", valid_618239
  var valid_618240 = header.getOrDefault("X-Amz-Security-Token")
  valid_618240 = validateParameter(valid_618240, JString, required = false,
                                 default = nil)
  if valid_618240 != nil:
    section.add "X-Amz-Security-Token", valid_618240
  var valid_618241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618241 = validateParameter(valid_618241, JString, required = false,
                                 default = nil)
  if valid_618241 != nil:
    section.add "X-Amz-Content-Sha256", valid_618241
  var valid_618242 = header.getOrDefault("X-Amz-Algorithm")
  valid_618242 = validateParameter(valid_618242, JString, required = false,
                                 default = nil)
  if valid_618242 != nil:
    section.add "X-Amz-Algorithm", valid_618242
  var valid_618243 = header.getOrDefault("X-Amz-Signature")
  valid_618243 = validateParameter(valid_618243, JString, required = false,
                                 default = nil)
  if valid_618243 != nil:
    section.add "X-Amz-Signature", valid_618243
  var valid_618244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618244 = validateParameter(valid_618244, JString, required = false,
                                 default = nil)
  if valid_618244 != nil:
    section.add "X-Amz-SignedHeaders", valid_618244
  var valid_618245 = header.getOrDefault("X-Amz-Credential")
  valid_618245 = validateParameter(valid_618245, JString, required = false,
                                 default = nil)
  if valid_618245 != nil:
    section.add "X-Amz-Credential", valid_618245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618246: Call_DeleteCampaign_618234; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_618246.validator(path, query, header, formData, body, _)
  let scheme = call_618246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618246.url(scheme.get, call_618246.host, call_618246.base,
                         call_618246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618246, url, valid, _)

proc call*(call_618247: Call_DeleteCampaign_618234; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_618248 = newJObject()
  add(path_618248, "application-id", newJString(applicationId))
  add(path_618248, "campaign-id", newJString(campaignId))
  result = call_618247.call(path_618248, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_618234(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_618235, base: "/", url: url_DeleteCampaign_618236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_618263 = ref object of OpenApiRestCall_616850
proc url_UpdateEmailChannel_618265(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_618264(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618266 = path.getOrDefault("application-id")
  valid_618266 = validateParameter(valid_618266, JString, required = true,
                                 default = nil)
  if valid_618266 != nil:
    section.add "application-id", valid_618266
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
  var valid_618267 = header.getOrDefault("X-Amz-Date")
  valid_618267 = validateParameter(valid_618267, JString, required = false,
                                 default = nil)
  if valid_618267 != nil:
    section.add "X-Amz-Date", valid_618267
  var valid_618268 = header.getOrDefault("X-Amz-Security-Token")
  valid_618268 = validateParameter(valid_618268, JString, required = false,
                                 default = nil)
  if valid_618268 != nil:
    section.add "X-Amz-Security-Token", valid_618268
  var valid_618269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618269 = validateParameter(valid_618269, JString, required = false,
                                 default = nil)
  if valid_618269 != nil:
    section.add "X-Amz-Content-Sha256", valid_618269
  var valid_618270 = header.getOrDefault("X-Amz-Algorithm")
  valid_618270 = validateParameter(valid_618270, JString, required = false,
                                 default = nil)
  if valid_618270 != nil:
    section.add "X-Amz-Algorithm", valid_618270
  var valid_618271 = header.getOrDefault("X-Amz-Signature")
  valid_618271 = validateParameter(valid_618271, JString, required = false,
                                 default = nil)
  if valid_618271 != nil:
    section.add "X-Amz-Signature", valid_618271
  var valid_618272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618272 = validateParameter(valid_618272, JString, required = false,
                                 default = nil)
  if valid_618272 != nil:
    section.add "X-Amz-SignedHeaders", valid_618272
  var valid_618273 = header.getOrDefault("X-Amz-Credential")
  valid_618273 = validateParameter(valid_618273, JString, required = false,
                                 default = nil)
  if valid_618273 != nil:
    section.add "X-Amz-Credential", valid_618273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618275: Call_UpdateEmailChannel_618263; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_618275.validator(path, query, header, formData, body, _)
  let scheme = call_618275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618275.url(scheme.get, call_618275.host, call_618275.base,
                         call_618275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618275, url, valid, _)

proc call*(call_618276: Call_UpdateEmailChannel_618263; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618277 = newJObject()
  var body_618278 = newJObject()
  add(path_618277, "application-id", newJString(applicationId))
  if body != nil:
    body_618278 = body
  result = call_618276.call(path_618277, nil, nil, nil, body_618278)

var updateEmailChannel* = Call_UpdateEmailChannel_618263(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_618264, base: "/",
    url: url_UpdateEmailChannel_618265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_618249 = ref object of OpenApiRestCall_616850
proc url_GetEmailChannel_618251(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_618250(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618252 = path.getOrDefault("application-id")
  valid_618252 = validateParameter(valid_618252, JString, required = true,
                                 default = nil)
  if valid_618252 != nil:
    section.add "application-id", valid_618252
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
  var valid_618253 = header.getOrDefault("X-Amz-Date")
  valid_618253 = validateParameter(valid_618253, JString, required = false,
                                 default = nil)
  if valid_618253 != nil:
    section.add "X-Amz-Date", valid_618253
  var valid_618254 = header.getOrDefault("X-Amz-Security-Token")
  valid_618254 = validateParameter(valid_618254, JString, required = false,
                                 default = nil)
  if valid_618254 != nil:
    section.add "X-Amz-Security-Token", valid_618254
  var valid_618255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618255 = validateParameter(valid_618255, JString, required = false,
                                 default = nil)
  if valid_618255 != nil:
    section.add "X-Amz-Content-Sha256", valid_618255
  var valid_618256 = header.getOrDefault("X-Amz-Algorithm")
  valid_618256 = validateParameter(valid_618256, JString, required = false,
                                 default = nil)
  if valid_618256 != nil:
    section.add "X-Amz-Algorithm", valid_618256
  var valid_618257 = header.getOrDefault("X-Amz-Signature")
  valid_618257 = validateParameter(valid_618257, JString, required = false,
                                 default = nil)
  if valid_618257 != nil:
    section.add "X-Amz-Signature", valid_618257
  var valid_618258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618258 = validateParameter(valid_618258, JString, required = false,
                                 default = nil)
  if valid_618258 != nil:
    section.add "X-Amz-SignedHeaders", valid_618258
  var valid_618259 = header.getOrDefault("X-Amz-Credential")
  valid_618259 = validateParameter(valid_618259, JString, required = false,
                                 default = nil)
  if valid_618259 != nil:
    section.add "X-Amz-Credential", valid_618259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618260: Call_GetEmailChannel_618249; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_618260.validator(path, query, header, formData, body, _)
  let scheme = call_618260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618260.url(scheme.get, call_618260.host, call_618260.base,
                         call_618260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618260, url, valid, _)

proc call*(call_618261: Call_GetEmailChannel_618249; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618262 = newJObject()
  add(path_618262, "application-id", newJString(applicationId))
  result = call_618261.call(path_618262, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_618249(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_618250, base: "/", url: url_GetEmailChannel_618251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_618279 = ref object of OpenApiRestCall_616850
proc url_DeleteEmailChannel_618281(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_618280(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618282 = path.getOrDefault("application-id")
  valid_618282 = validateParameter(valid_618282, JString, required = true,
                                 default = nil)
  if valid_618282 != nil:
    section.add "application-id", valid_618282
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
  var valid_618283 = header.getOrDefault("X-Amz-Date")
  valid_618283 = validateParameter(valid_618283, JString, required = false,
                                 default = nil)
  if valid_618283 != nil:
    section.add "X-Amz-Date", valid_618283
  var valid_618284 = header.getOrDefault("X-Amz-Security-Token")
  valid_618284 = validateParameter(valid_618284, JString, required = false,
                                 default = nil)
  if valid_618284 != nil:
    section.add "X-Amz-Security-Token", valid_618284
  var valid_618285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618285 = validateParameter(valid_618285, JString, required = false,
                                 default = nil)
  if valid_618285 != nil:
    section.add "X-Amz-Content-Sha256", valid_618285
  var valid_618286 = header.getOrDefault("X-Amz-Algorithm")
  valid_618286 = validateParameter(valid_618286, JString, required = false,
                                 default = nil)
  if valid_618286 != nil:
    section.add "X-Amz-Algorithm", valid_618286
  var valid_618287 = header.getOrDefault("X-Amz-Signature")
  valid_618287 = validateParameter(valid_618287, JString, required = false,
                                 default = nil)
  if valid_618287 != nil:
    section.add "X-Amz-Signature", valid_618287
  var valid_618288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618288 = validateParameter(valid_618288, JString, required = false,
                                 default = nil)
  if valid_618288 != nil:
    section.add "X-Amz-SignedHeaders", valid_618288
  var valid_618289 = header.getOrDefault("X-Amz-Credential")
  valid_618289 = validateParameter(valid_618289, JString, required = false,
                                 default = nil)
  if valid_618289 != nil:
    section.add "X-Amz-Credential", valid_618289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618290: Call_DeleteEmailChannel_618279; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618290.validator(path, query, header, formData, body, _)
  let scheme = call_618290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618290.url(scheme.get, call_618290.host, call_618290.base,
                         call_618290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618290, url, valid, _)

proc call*(call_618291: Call_DeleteEmailChannel_618279; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618292 = newJObject()
  add(path_618292, "application-id", newJString(applicationId))
  result = call_618291.call(path_618292, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_618279(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_618280, base: "/",
    url: url_DeleteEmailChannel_618281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_618308 = ref object of OpenApiRestCall_616850
proc url_UpdateEndpoint_618310(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_618309(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   endpoint-id: JString (required)
  ##              : The unique identifier for the endpoint.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `endpoint-id` field"
  var valid_618311 = path.getOrDefault("endpoint-id")
  valid_618311 = validateParameter(valid_618311, JString, required = true,
                                 default = nil)
  if valid_618311 != nil:
    section.add "endpoint-id", valid_618311
  var valid_618312 = path.getOrDefault("application-id")
  valid_618312 = validateParameter(valid_618312, JString, required = true,
                                 default = nil)
  if valid_618312 != nil:
    section.add "application-id", valid_618312
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
  var valid_618313 = header.getOrDefault("X-Amz-Date")
  valid_618313 = validateParameter(valid_618313, JString, required = false,
                                 default = nil)
  if valid_618313 != nil:
    section.add "X-Amz-Date", valid_618313
  var valid_618314 = header.getOrDefault("X-Amz-Security-Token")
  valid_618314 = validateParameter(valid_618314, JString, required = false,
                                 default = nil)
  if valid_618314 != nil:
    section.add "X-Amz-Security-Token", valid_618314
  var valid_618315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618315 = validateParameter(valid_618315, JString, required = false,
                                 default = nil)
  if valid_618315 != nil:
    section.add "X-Amz-Content-Sha256", valid_618315
  var valid_618316 = header.getOrDefault("X-Amz-Algorithm")
  valid_618316 = validateParameter(valid_618316, JString, required = false,
                                 default = nil)
  if valid_618316 != nil:
    section.add "X-Amz-Algorithm", valid_618316
  var valid_618317 = header.getOrDefault("X-Amz-Signature")
  valid_618317 = validateParameter(valid_618317, JString, required = false,
                                 default = nil)
  if valid_618317 != nil:
    section.add "X-Amz-Signature", valid_618317
  var valid_618318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618318 = validateParameter(valid_618318, JString, required = false,
                                 default = nil)
  if valid_618318 != nil:
    section.add "X-Amz-SignedHeaders", valid_618318
  var valid_618319 = header.getOrDefault("X-Amz-Credential")
  valid_618319 = validateParameter(valid_618319, JString, required = false,
                                 default = nil)
  if valid_618319 != nil:
    section.add "X-Amz-Credential", valid_618319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618321: Call_UpdateEndpoint_618308; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_618321.validator(path, query, header, formData, body, _)
  let scheme = call_618321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618321.url(scheme.get, call_618321.host, call_618321.base,
                         call_618321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618321, url, valid, _)

proc call*(call_618322: Call_UpdateEndpoint_618308; endpointId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618323 = newJObject()
  var body_618324 = newJObject()
  add(path_618323, "endpoint-id", newJString(endpointId))
  add(path_618323, "application-id", newJString(applicationId))
  if body != nil:
    body_618324 = body
  result = call_618322.call(path_618323, nil, nil, nil, body_618324)

var updateEndpoint* = Call_UpdateEndpoint_618308(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_618309, base: "/", url: url_UpdateEndpoint_618310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_618293 = ref object of OpenApiRestCall_616850
proc url_GetEndpoint_618295(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_618294(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618296 = path.getOrDefault("application-id")
  valid_618296 = validateParameter(valid_618296, JString, required = true,
                                 default = nil)
  if valid_618296 != nil:
    section.add "application-id", valid_618296
  var valid_618297 = path.getOrDefault("endpoint-id")
  valid_618297 = validateParameter(valid_618297, JString, required = true,
                                 default = nil)
  if valid_618297 != nil:
    section.add "endpoint-id", valid_618297
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
  var valid_618298 = header.getOrDefault("X-Amz-Date")
  valid_618298 = validateParameter(valid_618298, JString, required = false,
                                 default = nil)
  if valid_618298 != nil:
    section.add "X-Amz-Date", valid_618298
  var valid_618299 = header.getOrDefault("X-Amz-Security-Token")
  valid_618299 = validateParameter(valid_618299, JString, required = false,
                                 default = nil)
  if valid_618299 != nil:
    section.add "X-Amz-Security-Token", valid_618299
  var valid_618300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618300 = validateParameter(valid_618300, JString, required = false,
                                 default = nil)
  if valid_618300 != nil:
    section.add "X-Amz-Content-Sha256", valid_618300
  var valid_618301 = header.getOrDefault("X-Amz-Algorithm")
  valid_618301 = validateParameter(valid_618301, JString, required = false,
                                 default = nil)
  if valid_618301 != nil:
    section.add "X-Amz-Algorithm", valid_618301
  var valid_618302 = header.getOrDefault("X-Amz-Signature")
  valid_618302 = validateParameter(valid_618302, JString, required = false,
                                 default = nil)
  if valid_618302 != nil:
    section.add "X-Amz-Signature", valid_618302
  var valid_618303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618303 = validateParameter(valid_618303, JString, required = false,
                                 default = nil)
  if valid_618303 != nil:
    section.add "X-Amz-SignedHeaders", valid_618303
  var valid_618304 = header.getOrDefault("X-Amz-Credential")
  valid_618304 = validateParameter(valid_618304, JString, required = false,
                                 default = nil)
  if valid_618304 != nil:
    section.add "X-Amz-Credential", valid_618304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618305: Call_GetEndpoint_618293; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_618305.validator(path, query, header, formData, body, _)
  let scheme = call_618305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618305.url(scheme.get, call_618305.host, call_618305.base,
                         call_618305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618305, url, valid, _)

proc call*(call_618306: Call_GetEndpoint_618293; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_618307 = newJObject()
  add(path_618307, "application-id", newJString(applicationId))
  add(path_618307, "endpoint-id", newJString(endpointId))
  result = call_618306.call(path_618307, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_618293(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_618294,
                                        base: "/", url: url_GetEndpoint_618295,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_618325 = ref object of OpenApiRestCall_616850
proc url_DeleteEndpoint_618327(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_618326(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618328 = path.getOrDefault("application-id")
  valid_618328 = validateParameter(valid_618328, JString, required = true,
                                 default = nil)
  if valid_618328 != nil:
    section.add "application-id", valid_618328
  var valid_618329 = path.getOrDefault("endpoint-id")
  valid_618329 = validateParameter(valid_618329, JString, required = true,
                                 default = nil)
  if valid_618329 != nil:
    section.add "endpoint-id", valid_618329
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
  var valid_618330 = header.getOrDefault("X-Amz-Date")
  valid_618330 = validateParameter(valid_618330, JString, required = false,
                                 default = nil)
  if valid_618330 != nil:
    section.add "X-Amz-Date", valid_618330
  var valid_618331 = header.getOrDefault("X-Amz-Security-Token")
  valid_618331 = validateParameter(valid_618331, JString, required = false,
                                 default = nil)
  if valid_618331 != nil:
    section.add "X-Amz-Security-Token", valid_618331
  var valid_618332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618332 = validateParameter(valid_618332, JString, required = false,
                                 default = nil)
  if valid_618332 != nil:
    section.add "X-Amz-Content-Sha256", valid_618332
  var valid_618333 = header.getOrDefault("X-Amz-Algorithm")
  valid_618333 = validateParameter(valid_618333, JString, required = false,
                                 default = nil)
  if valid_618333 != nil:
    section.add "X-Amz-Algorithm", valid_618333
  var valid_618334 = header.getOrDefault("X-Amz-Signature")
  valid_618334 = validateParameter(valid_618334, JString, required = false,
                                 default = nil)
  if valid_618334 != nil:
    section.add "X-Amz-Signature", valid_618334
  var valid_618335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618335 = validateParameter(valid_618335, JString, required = false,
                                 default = nil)
  if valid_618335 != nil:
    section.add "X-Amz-SignedHeaders", valid_618335
  var valid_618336 = header.getOrDefault("X-Amz-Credential")
  valid_618336 = validateParameter(valid_618336, JString, required = false,
                                 default = nil)
  if valid_618336 != nil:
    section.add "X-Amz-Credential", valid_618336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618337: Call_DeleteEndpoint_618325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_618337.validator(path, query, header, formData, body, _)
  let scheme = call_618337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618337.url(scheme.get, call_618337.host, call_618337.base,
                         call_618337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618337, url, valid, _)

proc call*(call_618338: Call_DeleteEndpoint_618325; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_618339 = newJObject()
  add(path_618339, "application-id", newJString(applicationId))
  add(path_618339, "endpoint-id", newJString(endpointId))
  result = call_618338.call(path_618339, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_618325(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_618326, base: "/", url: url_DeleteEndpoint_618327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_618354 = ref object of OpenApiRestCall_616850
proc url_PutEventStream_618356(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_618355(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618357 = path.getOrDefault("application-id")
  valid_618357 = validateParameter(valid_618357, JString, required = true,
                                 default = nil)
  if valid_618357 != nil:
    section.add "application-id", valid_618357
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
  var valid_618358 = header.getOrDefault("X-Amz-Date")
  valid_618358 = validateParameter(valid_618358, JString, required = false,
                                 default = nil)
  if valid_618358 != nil:
    section.add "X-Amz-Date", valid_618358
  var valid_618359 = header.getOrDefault("X-Amz-Security-Token")
  valid_618359 = validateParameter(valid_618359, JString, required = false,
                                 default = nil)
  if valid_618359 != nil:
    section.add "X-Amz-Security-Token", valid_618359
  var valid_618360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618360 = validateParameter(valid_618360, JString, required = false,
                                 default = nil)
  if valid_618360 != nil:
    section.add "X-Amz-Content-Sha256", valid_618360
  var valid_618361 = header.getOrDefault("X-Amz-Algorithm")
  valid_618361 = validateParameter(valid_618361, JString, required = false,
                                 default = nil)
  if valid_618361 != nil:
    section.add "X-Amz-Algorithm", valid_618361
  var valid_618362 = header.getOrDefault("X-Amz-Signature")
  valid_618362 = validateParameter(valid_618362, JString, required = false,
                                 default = nil)
  if valid_618362 != nil:
    section.add "X-Amz-Signature", valid_618362
  var valid_618363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618363 = validateParameter(valid_618363, JString, required = false,
                                 default = nil)
  if valid_618363 != nil:
    section.add "X-Amz-SignedHeaders", valid_618363
  var valid_618364 = header.getOrDefault("X-Amz-Credential")
  valid_618364 = validateParameter(valid_618364, JString, required = false,
                                 default = nil)
  if valid_618364 != nil:
    section.add "X-Amz-Credential", valid_618364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618366: Call_PutEventStream_618354; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_618366.validator(path, query, header, formData, body, _)
  let scheme = call_618366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618366.url(scheme.get, call_618366.host, call_618366.base,
                         call_618366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618366, url, valid, _)

proc call*(call_618367: Call_PutEventStream_618354; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618368 = newJObject()
  var body_618369 = newJObject()
  add(path_618368, "application-id", newJString(applicationId))
  if body != nil:
    body_618369 = body
  result = call_618367.call(path_618368, nil, nil, nil, body_618369)

var putEventStream* = Call_PutEventStream_618354(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_618355, base: "/", url: url_PutEventStream_618356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_618340 = ref object of OpenApiRestCall_616850
proc url_GetEventStream_618342(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_618341(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618343 = path.getOrDefault("application-id")
  valid_618343 = validateParameter(valid_618343, JString, required = true,
                                 default = nil)
  if valid_618343 != nil:
    section.add "application-id", valid_618343
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
  var valid_618344 = header.getOrDefault("X-Amz-Date")
  valid_618344 = validateParameter(valid_618344, JString, required = false,
                                 default = nil)
  if valid_618344 != nil:
    section.add "X-Amz-Date", valid_618344
  var valid_618345 = header.getOrDefault("X-Amz-Security-Token")
  valid_618345 = validateParameter(valid_618345, JString, required = false,
                                 default = nil)
  if valid_618345 != nil:
    section.add "X-Amz-Security-Token", valid_618345
  var valid_618346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618346 = validateParameter(valid_618346, JString, required = false,
                                 default = nil)
  if valid_618346 != nil:
    section.add "X-Amz-Content-Sha256", valid_618346
  var valid_618347 = header.getOrDefault("X-Amz-Algorithm")
  valid_618347 = validateParameter(valid_618347, JString, required = false,
                                 default = nil)
  if valid_618347 != nil:
    section.add "X-Amz-Algorithm", valid_618347
  var valid_618348 = header.getOrDefault("X-Amz-Signature")
  valid_618348 = validateParameter(valid_618348, JString, required = false,
                                 default = nil)
  if valid_618348 != nil:
    section.add "X-Amz-Signature", valid_618348
  var valid_618349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618349 = validateParameter(valid_618349, JString, required = false,
                                 default = nil)
  if valid_618349 != nil:
    section.add "X-Amz-SignedHeaders", valid_618349
  var valid_618350 = header.getOrDefault("X-Amz-Credential")
  valid_618350 = validateParameter(valid_618350, JString, required = false,
                                 default = nil)
  if valid_618350 != nil:
    section.add "X-Amz-Credential", valid_618350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618351: Call_GetEventStream_618340; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_618351.validator(path, query, header, formData, body, _)
  let scheme = call_618351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618351.url(scheme.get, call_618351.host, call_618351.base,
                         call_618351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618351, url, valid, _)

proc call*(call_618352: Call_GetEventStream_618340; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618353 = newJObject()
  add(path_618353, "application-id", newJString(applicationId))
  result = call_618352.call(path_618353, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_618340(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_618341, base: "/", url: url_GetEventStream_618342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_618370 = ref object of OpenApiRestCall_616850
proc url_DeleteEventStream_618372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_618371(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618373 = path.getOrDefault("application-id")
  valid_618373 = validateParameter(valid_618373, JString, required = true,
                                 default = nil)
  if valid_618373 != nil:
    section.add "application-id", valid_618373
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
  var valid_618374 = header.getOrDefault("X-Amz-Date")
  valid_618374 = validateParameter(valid_618374, JString, required = false,
                                 default = nil)
  if valid_618374 != nil:
    section.add "X-Amz-Date", valid_618374
  var valid_618375 = header.getOrDefault("X-Amz-Security-Token")
  valid_618375 = validateParameter(valid_618375, JString, required = false,
                                 default = nil)
  if valid_618375 != nil:
    section.add "X-Amz-Security-Token", valid_618375
  var valid_618376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618376 = validateParameter(valid_618376, JString, required = false,
                                 default = nil)
  if valid_618376 != nil:
    section.add "X-Amz-Content-Sha256", valid_618376
  var valid_618377 = header.getOrDefault("X-Amz-Algorithm")
  valid_618377 = validateParameter(valid_618377, JString, required = false,
                                 default = nil)
  if valid_618377 != nil:
    section.add "X-Amz-Algorithm", valid_618377
  var valid_618378 = header.getOrDefault("X-Amz-Signature")
  valid_618378 = validateParameter(valid_618378, JString, required = false,
                                 default = nil)
  if valid_618378 != nil:
    section.add "X-Amz-Signature", valid_618378
  var valid_618379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618379 = validateParameter(valid_618379, JString, required = false,
                                 default = nil)
  if valid_618379 != nil:
    section.add "X-Amz-SignedHeaders", valid_618379
  var valid_618380 = header.getOrDefault("X-Amz-Credential")
  valid_618380 = validateParameter(valid_618380, JString, required = false,
                                 default = nil)
  if valid_618380 != nil:
    section.add "X-Amz-Credential", valid_618380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618381: Call_DeleteEventStream_618370; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_618381.validator(path, query, header, formData, body, _)
  let scheme = call_618381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618381.url(scheme.get, call_618381.host, call_618381.base,
                         call_618381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618381, url, valid, _)

proc call*(call_618382: Call_DeleteEventStream_618370; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618383 = newJObject()
  add(path_618383, "application-id", newJString(applicationId))
  result = call_618382.call(path_618383, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_618370(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_618371, base: "/",
    url: url_DeleteEventStream_618372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_618398 = ref object of OpenApiRestCall_616850
proc url_UpdateGcmChannel_618400(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_618399(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618401 = path.getOrDefault("application-id")
  valid_618401 = validateParameter(valid_618401, JString, required = true,
                                 default = nil)
  if valid_618401 != nil:
    section.add "application-id", valid_618401
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
  var valid_618402 = header.getOrDefault("X-Amz-Date")
  valid_618402 = validateParameter(valid_618402, JString, required = false,
                                 default = nil)
  if valid_618402 != nil:
    section.add "X-Amz-Date", valid_618402
  var valid_618403 = header.getOrDefault("X-Amz-Security-Token")
  valid_618403 = validateParameter(valid_618403, JString, required = false,
                                 default = nil)
  if valid_618403 != nil:
    section.add "X-Amz-Security-Token", valid_618403
  var valid_618404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618404 = validateParameter(valid_618404, JString, required = false,
                                 default = nil)
  if valid_618404 != nil:
    section.add "X-Amz-Content-Sha256", valid_618404
  var valid_618405 = header.getOrDefault("X-Amz-Algorithm")
  valid_618405 = validateParameter(valid_618405, JString, required = false,
                                 default = nil)
  if valid_618405 != nil:
    section.add "X-Amz-Algorithm", valid_618405
  var valid_618406 = header.getOrDefault("X-Amz-Signature")
  valid_618406 = validateParameter(valid_618406, JString, required = false,
                                 default = nil)
  if valid_618406 != nil:
    section.add "X-Amz-Signature", valid_618406
  var valid_618407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618407 = validateParameter(valid_618407, JString, required = false,
                                 default = nil)
  if valid_618407 != nil:
    section.add "X-Amz-SignedHeaders", valid_618407
  var valid_618408 = header.getOrDefault("X-Amz-Credential")
  valid_618408 = validateParameter(valid_618408, JString, required = false,
                                 default = nil)
  if valid_618408 != nil:
    section.add "X-Amz-Credential", valid_618408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618410: Call_UpdateGcmChannel_618398; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_618410.validator(path, query, header, formData, body, _)
  let scheme = call_618410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618410.url(scheme.get, call_618410.host, call_618410.base,
                         call_618410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618410, url, valid, _)

proc call*(call_618411: Call_UpdateGcmChannel_618398; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618412 = newJObject()
  var body_618413 = newJObject()
  add(path_618412, "application-id", newJString(applicationId))
  if body != nil:
    body_618413 = body
  result = call_618411.call(path_618412, nil, nil, nil, body_618413)

var updateGcmChannel* = Call_UpdateGcmChannel_618398(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_618399, base: "/",
    url: url_UpdateGcmChannel_618400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_618384 = ref object of OpenApiRestCall_616850
proc url_GetGcmChannel_618386(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_618385(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618387 = path.getOrDefault("application-id")
  valid_618387 = validateParameter(valid_618387, JString, required = true,
                                 default = nil)
  if valid_618387 != nil:
    section.add "application-id", valid_618387
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
  var valid_618388 = header.getOrDefault("X-Amz-Date")
  valid_618388 = validateParameter(valid_618388, JString, required = false,
                                 default = nil)
  if valid_618388 != nil:
    section.add "X-Amz-Date", valid_618388
  var valid_618389 = header.getOrDefault("X-Amz-Security-Token")
  valid_618389 = validateParameter(valid_618389, JString, required = false,
                                 default = nil)
  if valid_618389 != nil:
    section.add "X-Amz-Security-Token", valid_618389
  var valid_618390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618390 = validateParameter(valid_618390, JString, required = false,
                                 default = nil)
  if valid_618390 != nil:
    section.add "X-Amz-Content-Sha256", valid_618390
  var valid_618391 = header.getOrDefault("X-Amz-Algorithm")
  valid_618391 = validateParameter(valid_618391, JString, required = false,
                                 default = nil)
  if valid_618391 != nil:
    section.add "X-Amz-Algorithm", valid_618391
  var valid_618392 = header.getOrDefault("X-Amz-Signature")
  valid_618392 = validateParameter(valid_618392, JString, required = false,
                                 default = nil)
  if valid_618392 != nil:
    section.add "X-Amz-Signature", valid_618392
  var valid_618393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618393 = validateParameter(valid_618393, JString, required = false,
                                 default = nil)
  if valid_618393 != nil:
    section.add "X-Amz-SignedHeaders", valid_618393
  var valid_618394 = header.getOrDefault("X-Amz-Credential")
  valid_618394 = validateParameter(valid_618394, JString, required = false,
                                 default = nil)
  if valid_618394 != nil:
    section.add "X-Amz-Credential", valid_618394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618395: Call_GetGcmChannel_618384; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_618395.validator(path, query, header, formData, body, _)
  let scheme = call_618395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618395.url(scheme.get, call_618395.host, call_618395.base,
                         call_618395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618395, url, valid, _)

proc call*(call_618396: Call_GetGcmChannel_618384; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618397 = newJObject()
  add(path_618397, "application-id", newJString(applicationId))
  result = call_618396.call(path_618397, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_618384(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_618385, base: "/", url: url_GetGcmChannel_618386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_618414 = ref object of OpenApiRestCall_616850
proc url_DeleteGcmChannel_618416(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_618415(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618417 = path.getOrDefault("application-id")
  valid_618417 = validateParameter(valid_618417, JString, required = true,
                                 default = nil)
  if valid_618417 != nil:
    section.add "application-id", valid_618417
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
  var valid_618418 = header.getOrDefault("X-Amz-Date")
  valid_618418 = validateParameter(valid_618418, JString, required = false,
                                 default = nil)
  if valid_618418 != nil:
    section.add "X-Amz-Date", valid_618418
  var valid_618419 = header.getOrDefault("X-Amz-Security-Token")
  valid_618419 = validateParameter(valid_618419, JString, required = false,
                                 default = nil)
  if valid_618419 != nil:
    section.add "X-Amz-Security-Token", valid_618419
  var valid_618420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618420 = validateParameter(valid_618420, JString, required = false,
                                 default = nil)
  if valid_618420 != nil:
    section.add "X-Amz-Content-Sha256", valid_618420
  var valid_618421 = header.getOrDefault("X-Amz-Algorithm")
  valid_618421 = validateParameter(valid_618421, JString, required = false,
                                 default = nil)
  if valid_618421 != nil:
    section.add "X-Amz-Algorithm", valid_618421
  var valid_618422 = header.getOrDefault("X-Amz-Signature")
  valid_618422 = validateParameter(valid_618422, JString, required = false,
                                 default = nil)
  if valid_618422 != nil:
    section.add "X-Amz-Signature", valid_618422
  var valid_618423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618423 = validateParameter(valid_618423, JString, required = false,
                                 default = nil)
  if valid_618423 != nil:
    section.add "X-Amz-SignedHeaders", valid_618423
  var valid_618424 = header.getOrDefault("X-Amz-Credential")
  valid_618424 = validateParameter(valid_618424, JString, required = false,
                                 default = nil)
  if valid_618424 != nil:
    section.add "X-Amz-Credential", valid_618424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618425: Call_DeleteGcmChannel_618414; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618425.validator(path, query, header, formData, body, _)
  let scheme = call_618425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618425.url(scheme.get, call_618425.host, call_618425.base,
                         call_618425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618425, url, valid, _)

proc call*(call_618426: Call_DeleteGcmChannel_618414; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618427 = newJObject()
  add(path_618427, "application-id", newJString(applicationId))
  result = call_618426.call(path_618427, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_618414(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_618415, base: "/",
    url: url_DeleteGcmChannel_618416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_618443 = ref object of OpenApiRestCall_616850
proc url_UpdateJourney_618445(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_618444(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618446 = path.getOrDefault("journey-id")
  valid_618446 = validateParameter(valid_618446, JString, required = true,
                                 default = nil)
  if valid_618446 != nil:
    section.add "journey-id", valid_618446
  var valid_618447 = path.getOrDefault("application-id")
  valid_618447 = validateParameter(valid_618447, JString, required = true,
                                 default = nil)
  if valid_618447 != nil:
    section.add "application-id", valid_618447
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
  var valid_618448 = header.getOrDefault("X-Amz-Date")
  valid_618448 = validateParameter(valid_618448, JString, required = false,
                                 default = nil)
  if valid_618448 != nil:
    section.add "X-Amz-Date", valid_618448
  var valid_618449 = header.getOrDefault("X-Amz-Security-Token")
  valid_618449 = validateParameter(valid_618449, JString, required = false,
                                 default = nil)
  if valid_618449 != nil:
    section.add "X-Amz-Security-Token", valid_618449
  var valid_618450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618450 = validateParameter(valid_618450, JString, required = false,
                                 default = nil)
  if valid_618450 != nil:
    section.add "X-Amz-Content-Sha256", valid_618450
  var valid_618451 = header.getOrDefault("X-Amz-Algorithm")
  valid_618451 = validateParameter(valid_618451, JString, required = false,
                                 default = nil)
  if valid_618451 != nil:
    section.add "X-Amz-Algorithm", valid_618451
  var valid_618452 = header.getOrDefault("X-Amz-Signature")
  valid_618452 = validateParameter(valid_618452, JString, required = false,
                                 default = nil)
  if valid_618452 != nil:
    section.add "X-Amz-Signature", valid_618452
  var valid_618453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618453 = validateParameter(valid_618453, JString, required = false,
                                 default = nil)
  if valid_618453 != nil:
    section.add "X-Amz-SignedHeaders", valid_618453
  var valid_618454 = header.getOrDefault("X-Amz-Credential")
  valid_618454 = validateParameter(valid_618454, JString, required = false,
                                 default = nil)
  if valid_618454 != nil:
    section.add "X-Amz-Credential", valid_618454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618456: Call_UpdateJourney_618443; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_618456.validator(path, query, header, formData, body, _)
  let scheme = call_618456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618456.url(scheme.get, call_618456.host, call_618456.base,
                         call_618456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618456, url, valid, _)

proc call*(call_618457: Call_UpdateJourney_618443; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618458 = newJObject()
  var body_618459 = newJObject()
  add(path_618458, "journey-id", newJString(journeyId))
  add(path_618458, "application-id", newJString(applicationId))
  if body != nil:
    body_618459 = body
  result = call_618457.call(path_618458, nil, nil, nil, body_618459)

var updateJourney* = Call_UpdateJourney_618443(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_618444, base: "/", url: url_UpdateJourney_618445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_618428 = ref object of OpenApiRestCall_616850
proc url_GetJourney_618430(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetJourney_618429(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618431 = path.getOrDefault("journey-id")
  valid_618431 = validateParameter(valid_618431, JString, required = true,
                                 default = nil)
  if valid_618431 != nil:
    section.add "journey-id", valid_618431
  var valid_618432 = path.getOrDefault("application-id")
  valid_618432 = validateParameter(valid_618432, JString, required = true,
                                 default = nil)
  if valid_618432 != nil:
    section.add "application-id", valid_618432
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
  var valid_618433 = header.getOrDefault("X-Amz-Date")
  valid_618433 = validateParameter(valid_618433, JString, required = false,
                                 default = nil)
  if valid_618433 != nil:
    section.add "X-Amz-Date", valid_618433
  var valid_618434 = header.getOrDefault("X-Amz-Security-Token")
  valid_618434 = validateParameter(valid_618434, JString, required = false,
                                 default = nil)
  if valid_618434 != nil:
    section.add "X-Amz-Security-Token", valid_618434
  var valid_618435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618435 = validateParameter(valid_618435, JString, required = false,
                                 default = nil)
  if valid_618435 != nil:
    section.add "X-Amz-Content-Sha256", valid_618435
  var valid_618436 = header.getOrDefault("X-Amz-Algorithm")
  valid_618436 = validateParameter(valid_618436, JString, required = false,
                                 default = nil)
  if valid_618436 != nil:
    section.add "X-Amz-Algorithm", valid_618436
  var valid_618437 = header.getOrDefault("X-Amz-Signature")
  valid_618437 = validateParameter(valid_618437, JString, required = false,
                                 default = nil)
  if valid_618437 != nil:
    section.add "X-Amz-Signature", valid_618437
  var valid_618438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618438 = validateParameter(valid_618438, JString, required = false,
                                 default = nil)
  if valid_618438 != nil:
    section.add "X-Amz-SignedHeaders", valid_618438
  var valid_618439 = header.getOrDefault("X-Amz-Credential")
  valid_618439 = validateParameter(valid_618439, JString, required = false,
                                 default = nil)
  if valid_618439 != nil:
    section.add "X-Amz-Credential", valid_618439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618440: Call_GetJourney_618428; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_618440.validator(path, query, header, formData, body, _)
  let scheme = call_618440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618440.url(scheme.get, call_618440.host, call_618440.base,
                         call_618440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618440, url, valid, _)

proc call*(call_618441: Call_GetJourney_618428; journeyId: string;
          applicationId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618442 = newJObject()
  add(path_618442, "journey-id", newJString(journeyId))
  add(path_618442, "application-id", newJString(applicationId))
  result = call_618441.call(path_618442, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_618428(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_618429,
                                      base: "/", url: url_GetJourney_618430,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_618460 = ref object of OpenApiRestCall_616850
proc url_DeleteJourney_618462(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_618461(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618463 = path.getOrDefault("journey-id")
  valid_618463 = validateParameter(valid_618463, JString, required = true,
                                 default = nil)
  if valid_618463 != nil:
    section.add "journey-id", valid_618463
  var valid_618464 = path.getOrDefault("application-id")
  valid_618464 = validateParameter(valid_618464, JString, required = true,
                                 default = nil)
  if valid_618464 != nil:
    section.add "application-id", valid_618464
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
  var valid_618465 = header.getOrDefault("X-Amz-Date")
  valid_618465 = validateParameter(valid_618465, JString, required = false,
                                 default = nil)
  if valid_618465 != nil:
    section.add "X-Amz-Date", valid_618465
  var valid_618466 = header.getOrDefault("X-Amz-Security-Token")
  valid_618466 = validateParameter(valid_618466, JString, required = false,
                                 default = nil)
  if valid_618466 != nil:
    section.add "X-Amz-Security-Token", valid_618466
  var valid_618467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618467 = validateParameter(valid_618467, JString, required = false,
                                 default = nil)
  if valid_618467 != nil:
    section.add "X-Amz-Content-Sha256", valid_618467
  var valid_618468 = header.getOrDefault("X-Amz-Algorithm")
  valid_618468 = validateParameter(valid_618468, JString, required = false,
                                 default = nil)
  if valid_618468 != nil:
    section.add "X-Amz-Algorithm", valid_618468
  var valid_618469 = header.getOrDefault("X-Amz-Signature")
  valid_618469 = validateParameter(valid_618469, JString, required = false,
                                 default = nil)
  if valid_618469 != nil:
    section.add "X-Amz-Signature", valid_618469
  var valid_618470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618470 = validateParameter(valid_618470, JString, required = false,
                                 default = nil)
  if valid_618470 != nil:
    section.add "X-Amz-SignedHeaders", valid_618470
  var valid_618471 = header.getOrDefault("X-Amz-Credential")
  valid_618471 = validateParameter(valid_618471, JString, required = false,
                                 default = nil)
  if valid_618471 != nil:
    section.add "X-Amz-Credential", valid_618471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618472: Call_DeleteJourney_618460; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_618472.validator(path, query, header, formData, body, _)
  let scheme = call_618472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618472.url(scheme.get, call_618472.host, call_618472.base,
                         call_618472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618472, url, valid, _)

proc call*(call_618473: Call_DeleteJourney_618460; journeyId: string;
          applicationId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618474 = newJObject()
  add(path_618474, "journey-id", newJString(journeyId))
  add(path_618474, "application-id", newJString(applicationId))
  result = call_618473.call(path_618474, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_618460(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_618461, base: "/", url: url_DeleteJourney_618462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_618490 = ref object of OpenApiRestCall_616850
proc url_UpdateSegment_618492(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_618491(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618493 = path.getOrDefault("application-id")
  valid_618493 = validateParameter(valid_618493, JString, required = true,
                                 default = nil)
  if valid_618493 != nil:
    section.add "application-id", valid_618493
  var valid_618494 = path.getOrDefault("segment-id")
  valid_618494 = validateParameter(valid_618494, JString, required = true,
                                 default = nil)
  if valid_618494 != nil:
    section.add "segment-id", valid_618494
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
  var valid_618495 = header.getOrDefault("X-Amz-Date")
  valid_618495 = validateParameter(valid_618495, JString, required = false,
                                 default = nil)
  if valid_618495 != nil:
    section.add "X-Amz-Date", valid_618495
  var valid_618496 = header.getOrDefault("X-Amz-Security-Token")
  valid_618496 = validateParameter(valid_618496, JString, required = false,
                                 default = nil)
  if valid_618496 != nil:
    section.add "X-Amz-Security-Token", valid_618496
  var valid_618497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618497 = validateParameter(valid_618497, JString, required = false,
                                 default = nil)
  if valid_618497 != nil:
    section.add "X-Amz-Content-Sha256", valid_618497
  var valid_618498 = header.getOrDefault("X-Amz-Algorithm")
  valid_618498 = validateParameter(valid_618498, JString, required = false,
                                 default = nil)
  if valid_618498 != nil:
    section.add "X-Amz-Algorithm", valid_618498
  var valid_618499 = header.getOrDefault("X-Amz-Signature")
  valid_618499 = validateParameter(valid_618499, JString, required = false,
                                 default = nil)
  if valid_618499 != nil:
    section.add "X-Amz-Signature", valid_618499
  var valid_618500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618500 = validateParameter(valid_618500, JString, required = false,
                                 default = nil)
  if valid_618500 != nil:
    section.add "X-Amz-SignedHeaders", valid_618500
  var valid_618501 = header.getOrDefault("X-Amz-Credential")
  valid_618501 = validateParameter(valid_618501, JString, required = false,
                                 default = nil)
  if valid_618501 != nil:
    section.add "X-Amz-Credential", valid_618501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618503: Call_UpdateSegment_618490; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_618503.validator(path, query, header, formData, body, _)
  let scheme = call_618503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618503.url(scheme.get, call_618503.host, call_618503.base,
                         call_618503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618503, url, valid, _)

proc call*(call_618504: Call_UpdateSegment_618490; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_618505 = newJObject()
  var body_618506 = newJObject()
  add(path_618505, "application-id", newJString(applicationId))
  add(path_618505, "segment-id", newJString(segmentId))
  if body != nil:
    body_618506 = body
  result = call_618504.call(path_618505, nil, nil, nil, body_618506)

var updateSegment* = Call_UpdateSegment_618490(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_618491, base: "/", url: url_UpdateSegment_618492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_618475 = ref object of OpenApiRestCall_616850
proc url_GetSegment_618477(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSegment_618476(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618478 = path.getOrDefault("application-id")
  valid_618478 = validateParameter(valid_618478, JString, required = true,
                                 default = nil)
  if valid_618478 != nil:
    section.add "application-id", valid_618478
  var valid_618479 = path.getOrDefault("segment-id")
  valid_618479 = validateParameter(valid_618479, JString, required = true,
                                 default = nil)
  if valid_618479 != nil:
    section.add "segment-id", valid_618479
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
  var valid_618480 = header.getOrDefault("X-Amz-Date")
  valid_618480 = validateParameter(valid_618480, JString, required = false,
                                 default = nil)
  if valid_618480 != nil:
    section.add "X-Amz-Date", valid_618480
  var valid_618481 = header.getOrDefault("X-Amz-Security-Token")
  valid_618481 = validateParameter(valid_618481, JString, required = false,
                                 default = nil)
  if valid_618481 != nil:
    section.add "X-Amz-Security-Token", valid_618481
  var valid_618482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618482 = validateParameter(valid_618482, JString, required = false,
                                 default = nil)
  if valid_618482 != nil:
    section.add "X-Amz-Content-Sha256", valid_618482
  var valid_618483 = header.getOrDefault("X-Amz-Algorithm")
  valid_618483 = validateParameter(valid_618483, JString, required = false,
                                 default = nil)
  if valid_618483 != nil:
    section.add "X-Amz-Algorithm", valid_618483
  var valid_618484 = header.getOrDefault("X-Amz-Signature")
  valid_618484 = validateParameter(valid_618484, JString, required = false,
                                 default = nil)
  if valid_618484 != nil:
    section.add "X-Amz-Signature", valid_618484
  var valid_618485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618485 = validateParameter(valid_618485, JString, required = false,
                                 default = nil)
  if valid_618485 != nil:
    section.add "X-Amz-SignedHeaders", valid_618485
  var valid_618486 = header.getOrDefault("X-Amz-Credential")
  valid_618486 = validateParameter(valid_618486, JString, required = false,
                                 default = nil)
  if valid_618486 != nil:
    section.add "X-Amz-Credential", valid_618486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618487: Call_GetSegment_618475; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_618487.validator(path, query, header, formData, body, _)
  let scheme = call_618487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618487.url(scheme.get, call_618487.host, call_618487.base,
                         call_618487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618487, url, valid, _)

proc call*(call_618488: Call_GetSegment_618475; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_618489 = newJObject()
  add(path_618489, "application-id", newJString(applicationId))
  add(path_618489, "segment-id", newJString(segmentId))
  result = call_618488.call(path_618489, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_618475(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_618476,
                                      base: "/", url: url_GetSegment_618477,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_618507 = ref object of OpenApiRestCall_616850
proc url_DeleteSegment_618509(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_618508(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Deletes a segment from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618510 = path.getOrDefault("application-id")
  valid_618510 = validateParameter(valid_618510, JString, required = true,
                                 default = nil)
  if valid_618510 != nil:
    section.add "application-id", valid_618510
  var valid_618511 = path.getOrDefault("segment-id")
  valid_618511 = validateParameter(valid_618511, JString, required = true,
                                 default = nil)
  if valid_618511 != nil:
    section.add "segment-id", valid_618511
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
  var valid_618512 = header.getOrDefault("X-Amz-Date")
  valid_618512 = validateParameter(valid_618512, JString, required = false,
                                 default = nil)
  if valid_618512 != nil:
    section.add "X-Amz-Date", valid_618512
  var valid_618513 = header.getOrDefault("X-Amz-Security-Token")
  valid_618513 = validateParameter(valid_618513, JString, required = false,
                                 default = nil)
  if valid_618513 != nil:
    section.add "X-Amz-Security-Token", valid_618513
  var valid_618514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618514 = validateParameter(valid_618514, JString, required = false,
                                 default = nil)
  if valid_618514 != nil:
    section.add "X-Amz-Content-Sha256", valid_618514
  var valid_618515 = header.getOrDefault("X-Amz-Algorithm")
  valid_618515 = validateParameter(valid_618515, JString, required = false,
                                 default = nil)
  if valid_618515 != nil:
    section.add "X-Amz-Algorithm", valid_618515
  var valid_618516 = header.getOrDefault("X-Amz-Signature")
  valid_618516 = validateParameter(valid_618516, JString, required = false,
                                 default = nil)
  if valid_618516 != nil:
    section.add "X-Amz-Signature", valid_618516
  var valid_618517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618517 = validateParameter(valid_618517, JString, required = false,
                                 default = nil)
  if valid_618517 != nil:
    section.add "X-Amz-SignedHeaders", valid_618517
  var valid_618518 = header.getOrDefault("X-Amz-Credential")
  valid_618518 = validateParameter(valid_618518, JString, required = false,
                                 default = nil)
  if valid_618518 != nil:
    section.add "X-Amz-Credential", valid_618518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618519: Call_DeleteSegment_618507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_618519.validator(path, query, header, formData, body, _)
  let scheme = call_618519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618519.url(scheme.get, call_618519.host, call_618519.base,
                         call_618519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618519, url, valid, _)

proc call*(call_618520: Call_DeleteSegment_618507; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_618521 = newJObject()
  add(path_618521, "application-id", newJString(applicationId))
  add(path_618521, "segment-id", newJString(segmentId))
  result = call_618520.call(path_618521, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_618507(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_618508, base: "/", url: url_DeleteSegment_618509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_618536 = ref object of OpenApiRestCall_616850
proc url_UpdateSmsChannel_618538(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_618537(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618539 = path.getOrDefault("application-id")
  valid_618539 = validateParameter(valid_618539, JString, required = true,
                                 default = nil)
  if valid_618539 != nil:
    section.add "application-id", valid_618539
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
  var valid_618540 = header.getOrDefault("X-Amz-Date")
  valid_618540 = validateParameter(valid_618540, JString, required = false,
                                 default = nil)
  if valid_618540 != nil:
    section.add "X-Amz-Date", valid_618540
  var valid_618541 = header.getOrDefault("X-Amz-Security-Token")
  valid_618541 = validateParameter(valid_618541, JString, required = false,
                                 default = nil)
  if valid_618541 != nil:
    section.add "X-Amz-Security-Token", valid_618541
  var valid_618542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618542 = validateParameter(valid_618542, JString, required = false,
                                 default = nil)
  if valid_618542 != nil:
    section.add "X-Amz-Content-Sha256", valid_618542
  var valid_618543 = header.getOrDefault("X-Amz-Algorithm")
  valid_618543 = validateParameter(valid_618543, JString, required = false,
                                 default = nil)
  if valid_618543 != nil:
    section.add "X-Amz-Algorithm", valid_618543
  var valid_618544 = header.getOrDefault("X-Amz-Signature")
  valid_618544 = validateParameter(valid_618544, JString, required = false,
                                 default = nil)
  if valid_618544 != nil:
    section.add "X-Amz-Signature", valid_618544
  var valid_618545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618545 = validateParameter(valid_618545, JString, required = false,
                                 default = nil)
  if valid_618545 != nil:
    section.add "X-Amz-SignedHeaders", valid_618545
  var valid_618546 = header.getOrDefault("X-Amz-Credential")
  valid_618546 = validateParameter(valid_618546, JString, required = false,
                                 default = nil)
  if valid_618546 != nil:
    section.add "X-Amz-Credential", valid_618546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618548: Call_UpdateSmsChannel_618536; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_618548.validator(path, query, header, formData, body, _)
  let scheme = call_618548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618548.url(scheme.get, call_618548.host, call_618548.base,
                         call_618548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618548, url, valid, _)

proc call*(call_618549: Call_UpdateSmsChannel_618536; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618550 = newJObject()
  var body_618551 = newJObject()
  add(path_618550, "application-id", newJString(applicationId))
  if body != nil:
    body_618551 = body
  result = call_618549.call(path_618550, nil, nil, nil, body_618551)

var updateSmsChannel* = Call_UpdateSmsChannel_618536(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_618537, base: "/",
    url: url_UpdateSmsChannel_618538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_618522 = ref object of OpenApiRestCall_616850
proc url_GetSmsChannel_618524(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_618523(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618525 = path.getOrDefault("application-id")
  valid_618525 = validateParameter(valid_618525, JString, required = true,
                                 default = nil)
  if valid_618525 != nil:
    section.add "application-id", valid_618525
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
  var valid_618526 = header.getOrDefault("X-Amz-Date")
  valid_618526 = validateParameter(valid_618526, JString, required = false,
                                 default = nil)
  if valid_618526 != nil:
    section.add "X-Amz-Date", valid_618526
  var valid_618527 = header.getOrDefault("X-Amz-Security-Token")
  valid_618527 = validateParameter(valid_618527, JString, required = false,
                                 default = nil)
  if valid_618527 != nil:
    section.add "X-Amz-Security-Token", valid_618527
  var valid_618528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618528 = validateParameter(valid_618528, JString, required = false,
                                 default = nil)
  if valid_618528 != nil:
    section.add "X-Amz-Content-Sha256", valid_618528
  var valid_618529 = header.getOrDefault("X-Amz-Algorithm")
  valid_618529 = validateParameter(valid_618529, JString, required = false,
                                 default = nil)
  if valid_618529 != nil:
    section.add "X-Amz-Algorithm", valid_618529
  var valid_618530 = header.getOrDefault("X-Amz-Signature")
  valid_618530 = validateParameter(valid_618530, JString, required = false,
                                 default = nil)
  if valid_618530 != nil:
    section.add "X-Amz-Signature", valid_618530
  var valid_618531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618531 = validateParameter(valid_618531, JString, required = false,
                                 default = nil)
  if valid_618531 != nil:
    section.add "X-Amz-SignedHeaders", valid_618531
  var valid_618532 = header.getOrDefault("X-Amz-Credential")
  valid_618532 = validateParameter(valid_618532, JString, required = false,
                                 default = nil)
  if valid_618532 != nil:
    section.add "X-Amz-Credential", valid_618532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618533: Call_GetSmsChannel_618522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_618533.validator(path, query, header, formData, body, _)
  let scheme = call_618533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618533.url(scheme.get, call_618533.host, call_618533.base,
                         call_618533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618533, url, valid, _)

proc call*(call_618534: Call_GetSmsChannel_618522; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618535 = newJObject()
  add(path_618535, "application-id", newJString(applicationId))
  result = call_618534.call(path_618535, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_618522(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_618523, base: "/", url: url_GetSmsChannel_618524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_618552 = ref object of OpenApiRestCall_616850
proc url_DeleteSmsChannel_618554(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_618553(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618555 = path.getOrDefault("application-id")
  valid_618555 = validateParameter(valid_618555, JString, required = true,
                                 default = nil)
  if valid_618555 != nil:
    section.add "application-id", valid_618555
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
  var valid_618556 = header.getOrDefault("X-Amz-Date")
  valid_618556 = validateParameter(valid_618556, JString, required = false,
                                 default = nil)
  if valid_618556 != nil:
    section.add "X-Amz-Date", valid_618556
  var valid_618557 = header.getOrDefault("X-Amz-Security-Token")
  valid_618557 = validateParameter(valid_618557, JString, required = false,
                                 default = nil)
  if valid_618557 != nil:
    section.add "X-Amz-Security-Token", valid_618557
  var valid_618558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618558 = validateParameter(valid_618558, JString, required = false,
                                 default = nil)
  if valid_618558 != nil:
    section.add "X-Amz-Content-Sha256", valid_618558
  var valid_618559 = header.getOrDefault("X-Amz-Algorithm")
  valid_618559 = validateParameter(valid_618559, JString, required = false,
                                 default = nil)
  if valid_618559 != nil:
    section.add "X-Amz-Algorithm", valid_618559
  var valid_618560 = header.getOrDefault("X-Amz-Signature")
  valid_618560 = validateParameter(valid_618560, JString, required = false,
                                 default = nil)
  if valid_618560 != nil:
    section.add "X-Amz-Signature", valid_618560
  var valid_618561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618561 = validateParameter(valid_618561, JString, required = false,
                                 default = nil)
  if valid_618561 != nil:
    section.add "X-Amz-SignedHeaders", valid_618561
  var valid_618562 = header.getOrDefault("X-Amz-Credential")
  valid_618562 = validateParameter(valid_618562, JString, required = false,
                                 default = nil)
  if valid_618562 != nil:
    section.add "X-Amz-Credential", valid_618562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618563: Call_DeleteSmsChannel_618552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618563.validator(path, query, header, formData, body, _)
  let scheme = call_618563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618563.url(scheme.get, call_618563.host, call_618563.base,
                         call_618563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618563, url, valid, _)

proc call*(call_618564: Call_DeleteSmsChannel_618552; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618565 = newJObject()
  add(path_618565, "application-id", newJString(applicationId))
  result = call_618564.call(path_618565, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_618552(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_618553, base: "/",
    url: url_DeleteSmsChannel_618554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_618566 = ref object of OpenApiRestCall_616850
proc url_GetUserEndpoints_618568(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_618567(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618569 = path.getOrDefault("user-id")
  valid_618569 = validateParameter(valid_618569, JString, required = true,
                                 default = nil)
  if valid_618569 != nil:
    section.add "user-id", valid_618569
  var valid_618570 = path.getOrDefault("application-id")
  valid_618570 = validateParameter(valid_618570, JString, required = true,
                                 default = nil)
  if valid_618570 != nil:
    section.add "application-id", valid_618570
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
  var valid_618571 = header.getOrDefault("X-Amz-Date")
  valid_618571 = validateParameter(valid_618571, JString, required = false,
                                 default = nil)
  if valid_618571 != nil:
    section.add "X-Amz-Date", valid_618571
  var valid_618572 = header.getOrDefault("X-Amz-Security-Token")
  valid_618572 = validateParameter(valid_618572, JString, required = false,
                                 default = nil)
  if valid_618572 != nil:
    section.add "X-Amz-Security-Token", valid_618572
  var valid_618573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618573 = validateParameter(valid_618573, JString, required = false,
                                 default = nil)
  if valid_618573 != nil:
    section.add "X-Amz-Content-Sha256", valid_618573
  var valid_618574 = header.getOrDefault("X-Amz-Algorithm")
  valid_618574 = validateParameter(valid_618574, JString, required = false,
                                 default = nil)
  if valid_618574 != nil:
    section.add "X-Amz-Algorithm", valid_618574
  var valid_618575 = header.getOrDefault("X-Amz-Signature")
  valid_618575 = validateParameter(valid_618575, JString, required = false,
                                 default = nil)
  if valid_618575 != nil:
    section.add "X-Amz-Signature", valid_618575
  var valid_618576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618576 = validateParameter(valid_618576, JString, required = false,
                                 default = nil)
  if valid_618576 != nil:
    section.add "X-Amz-SignedHeaders", valid_618576
  var valid_618577 = header.getOrDefault("X-Amz-Credential")
  valid_618577 = validateParameter(valid_618577, JString, required = false,
                                 default = nil)
  if valid_618577 != nil:
    section.add "X-Amz-Credential", valid_618577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618578: Call_GetUserEndpoints_618566; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_618578.validator(path, query, header, formData, body, _)
  let scheme = call_618578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618578.url(scheme.get, call_618578.host, call_618578.base,
                         call_618578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618578, url, valid, _)

proc call*(call_618579: Call_GetUserEndpoints_618566; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618580 = newJObject()
  add(path_618580, "user-id", newJString(userId))
  add(path_618580, "application-id", newJString(applicationId))
  result = call_618579.call(path_618580, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_618566(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_618567, base: "/",
    url: url_GetUserEndpoints_618568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_618581 = ref object of OpenApiRestCall_616850
proc url_DeleteUserEndpoints_618583(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_618582(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618584 = path.getOrDefault("user-id")
  valid_618584 = validateParameter(valid_618584, JString, required = true,
                                 default = nil)
  if valid_618584 != nil:
    section.add "user-id", valid_618584
  var valid_618585 = path.getOrDefault("application-id")
  valid_618585 = validateParameter(valid_618585, JString, required = true,
                                 default = nil)
  if valid_618585 != nil:
    section.add "application-id", valid_618585
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
  var valid_618586 = header.getOrDefault("X-Amz-Date")
  valid_618586 = validateParameter(valid_618586, JString, required = false,
                                 default = nil)
  if valid_618586 != nil:
    section.add "X-Amz-Date", valid_618586
  var valid_618587 = header.getOrDefault("X-Amz-Security-Token")
  valid_618587 = validateParameter(valid_618587, JString, required = false,
                                 default = nil)
  if valid_618587 != nil:
    section.add "X-Amz-Security-Token", valid_618587
  var valid_618588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618588 = validateParameter(valid_618588, JString, required = false,
                                 default = nil)
  if valid_618588 != nil:
    section.add "X-Amz-Content-Sha256", valid_618588
  var valid_618589 = header.getOrDefault("X-Amz-Algorithm")
  valid_618589 = validateParameter(valid_618589, JString, required = false,
                                 default = nil)
  if valid_618589 != nil:
    section.add "X-Amz-Algorithm", valid_618589
  var valid_618590 = header.getOrDefault("X-Amz-Signature")
  valid_618590 = validateParameter(valid_618590, JString, required = false,
                                 default = nil)
  if valid_618590 != nil:
    section.add "X-Amz-Signature", valid_618590
  var valid_618591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618591 = validateParameter(valid_618591, JString, required = false,
                                 default = nil)
  if valid_618591 != nil:
    section.add "X-Amz-SignedHeaders", valid_618591
  var valid_618592 = header.getOrDefault("X-Amz-Credential")
  valid_618592 = validateParameter(valid_618592, JString, required = false,
                                 default = nil)
  if valid_618592 != nil:
    section.add "X-Amz-Credential", valid_618592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618593: Call_DeleteUserEndpoints_618581; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_618593.validator(path, query, header, formData, body, _)
  let scheme = call_618593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618593.url(scheme.get, call_618593.host, call_618593.base,
                         call_618593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618593, url, valid, _)

proc call*(call_618594: Call_DeleteUserEndpoints_618581; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618595 = newJObject()
  add(path_618595, "user-id", newJString(userId))
  add(path_618595, "application-id", newJString(applicationId))
  result = call_618594.call(path_618595, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_618581(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_618582, base: "/",
    url: url_DeleteUserEndpoints_618583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_618610 = ref object of OpenApiRestCall_616850
proc url_UpdateVoiceChannel_618612(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_618611(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618613 = path.getOrDefault("application-id")
  valid_618613 = validateParameter(valid_618613, JString, required = true,
                                 default = nil)
  if valid_618613 != nil:
    section.add "application-id", valid_618613
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
  var valid_618614 = header.getOrDefault("X-Amz-Date")
  valid_618614 = validateParameter(valid_618614, JString, required = false,
                                 default = nil)
  if valid_618614 != nil:
    section.add "X-Amz-Date", valid_618614
  var valid_618615 = header.getOrDefault("X-Amz-Security-Token")
  valid_618615 = validateParameter(valid_618615, JString, required = false,
                                 default = nil)
  if valid_618615 != nil:
    section.add "X-Amz-Security-Token", valid_618615
  var valid_618616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618616 = validateParameter(valid_618616, JString, required = false,
                                 default = nil)
  if valid_618616 != nil:
    section.add "X-Amz-Content-Sha256", valid_618616
  var valid_618617 = header.getOrDefault("X-Amz-Algorithm")
  valid_618617 = validateParameter(valid_618617, JString, required = false,
                                 default = nil)
  if valid_618617 != nil:
    section.add "X-Amz-Algorithm", valid_618617
  var valid_618618 = header.getOrDefault("X-Amz-Signature")
  valid_618618 = validateParameter(valid_618618, JString, required = false,
                                 default = nil)
  if valid_618618 != nil:
    section.add "X-Amz-Signature", valid_618618
  var valid_618619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618619 = validateParameter(valid_618619, JString, required = false,
                                 default = nil)
  if valid_618619 != nil:
    section.add "X-Amz-SignedHeaders", valid_618619
  var valid_618620 = header.getOrDefault("X-Amz-Credential")
  valid_618620 = validateParameter(valid_618620, JString, required = false,
                                 default = nil)
  if valid_618620 != nil:
    section.add "X-Amz-Credential", valid_618620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618622: Call_UpdateVoiceChannel_618610; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_618622.validator(path, query, header, formData, body, _)
  let scheme = call_618622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618622.url(scheme.get, call_618622.host, call_618622.base,
                         call_618622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618622, url, valid, _)

proc call*(call_618623: Call_UpdateVoiceChannel_618610; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618624 = newJObject()
  var body_618625 = newJObject()
  add(path_618624, "application-id", newJString(applicationId))
  if body != nil:
    body_618625 = body
  result = call_618623.call(path_618624, nil, nil, nil, body_618625)

var updateVoiceChannel* = Call_UpdateVoiceChannel_618610(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_618611, base: "/",
    url: url_UpdateVoiceChannel_618612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_618596 = ref object of OpenApiRestCall_616850
proc url_GetVoiceChannel_618598(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_618597(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618599 = path.getOrDefault("application-id")
  valid_618599 = validateParameter(valid_618599, JString, required = true,
                                 default = nil)
  if valid_618599 != nil:
    section.add "application-id", valid_618599
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
  var valid_618600 = header.getOrDefault("X-Amz-Date")
  valid_618600 = validateParameter(valid_618600, JString, required = false,
                                 default = nil)
  if valid_618600 != nil:
    section.add "X-Amz-Date", valid_618600
  var valid_618601 = header.getOrDefault("X-Amz-Security-Token")
  valid_618601 = validateParameter(valid_618601, JString, required = false,
                                 default = nil)
  if valid_618601 != nil:
    section.add "X-Amz-Security-Token", valid_618601
  var valid_618602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618602 = validateParameter(valid_618602, JString, required = false,
                                 default = nil)
  if valid_618602 != nil:
    section.add "X-Amz-Content-Sha256", valid_618602
  var valid_618603 = header.getOrDefault("X-Amz-Algorithm")
  valid_618603 = validateParameter(valid_618603, JString, required = false,
                                 default = nil)
  if valid_618603 != nil:
    section.add "X-Amz-Algorithm", valid_618603
  var valid_618604 = header.getOrDefault("X-Amz-Signature")
  valid_618604 = validateParameter(valid_618604, JString, required = false,
                                 default = nil)
  if valid_618604 != nil:
    section.add "X-Amz-Signature", valid_618604
  var valid_618605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618605 = validateParameter(valid_618605, JString, required = false,
                                 default = nil)
  if valid_618605 != nil:
    section.add "X-Amz-SignedHeaders", valid_618605
  var valid_618606 = header.getOrDefault("X-Amz-Credential")
  valid_618606 = validateParameter(valid_618606, JString, required = false,
                                 default = nil)
  if valid_618606 != nil:
    section.add "X-Amz-Credential", valid_618606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618607: Call_GetVoiceChannel_618596; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_618607.validator(path, query, header, formData, body, _)
  let scheme = call_618607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618607.url(scheme.get, call_618607.host, call_618607.base,
                         call_618607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618607, url, valid, _)

proc call*(call_618608: Call_GetVoiceChannel_618596; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618609 = newJObject()
  add(path_618609, "application-id", newJString(applicationId))
  result = call_618608.call(path_618609, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_618596(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_618597, base: "/", url: url_GetVoiceChannel_618598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_618626 = ref object of OpenApiRestCall_616850
proc url_DeleteVoiceChannel_618628(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_618627(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618629 = path.getOrDefault("application-id")
  valid_618629 = validateParameter(valid_618629, JString, required = true,
                                 default = nil)
  if valid_618629 != nil:
    section.add "application-id", valid_618629
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
  var valid_618630 = header.getOrDefault("X-Amz-Date")
  valid_618630 = validateParameter(valid_618630, JString, required = false,
                                 default = nil)
  if valid_618630 != nil:
    section.add "X-Amz-Date", valid_618630
  var valid_618631 = header.getOrDefault("X-Amz-Security-Token")
  valid_618631 = validateParameter(valid_618631, JString, required = false,
                                 default = nil)
  if valid_618631 != nil:
    section.add "X-Amz-Security-Token", valid_618631
  var valid_618632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618632 = validateParameter(valid_618632, JString, required = false,
                                 default = nil)
  if valid_618632 != nil:
    section.add "X-Amz-Content-Sha256", valid_618632
  var valid_618633 = header.getOrDefault("X-Amz-Algorithm")
  valid_618633 = validateParameter(valid_618633, JString, required = false,
                                 default = nil)
  if valid_618633 != nil:
    section.add "X-Amz-Algorithm", valid_618633
  var valid_618634 = header.getOrDefault("X-Amz-Signature")
  valid_618634 = validateParameter(valid_618634, JString, required = false,
                                 default = nil)
  if valid_618634 != nil:
    section.add "X-Amz-Signature", valid_618634
  var valid_618635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618635 = validateParameter(valid_618635, JString, required = false,
                                 default = nil)
  if valid_618635 != nil:
    section.add "X-Amz-SignedHeaders", valid_618635
  var valid_618636 = header.getOrDefault("X-Amz-Credential")
  valid_618636 = validateParameter(valid_618636, JString, required = false,
                                 default = nil)
  if valid_618636 != nil:
    section.add "X-Amz-Credential", valid_618636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618637: Call_DeleteVoiceChannel_618626; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_618637.validator(path, query, header, formData, body, _)
  let scheme = call_618637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618637.url(scheme.get, call_618637.host, call_618637.base,
                         call_618637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618637, url, valid, _)

proc call*(call_618638: Call_DeleteVoiceChannel_618626; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618639 = newJObject()
  add(path_618639, "application-id", newJString(applicationId))
  result = call_618638.call(path_618639, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_618626(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_618627, base: "/",
    url: url_DeleteVoiceChannel_618628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_618640 = ref object of OpenApiRestCall_616850
proc url_GetApplicationDateRangeKpi_618642(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_618641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618643 = path.getOrDefault("application-id")
  valid_618643 = validateParameter(valid_618643, JString, required = true,
                                 default = nil)
  if valid_618643 != nil:
    section.add "application-id", valid_618643
  var valid_618644 = path.getOrDefault("kpi-name")
  valid_618644 = validateParameter(valid_618644, JString, required = true,
                                 default = nil)
  if valid_618644 != nil:
    section.add "kpi-name", valid_618644
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
  var valid_618645 = query.getOrDefault("end-time")
  valid_618645 = validateParameter(valid_618645, JString, required = false,
                                 default = nil)
  if valid_618645 != nil:
    section.add "end-time", valid_618645
  var valid_618646 = query.getOrDefault("start-time")
  valid_618646 = validateParameter(valid_618646, JString, required = false,
                                 default = nil)
  if valid_618646 != nil:
    section.add "start-time", valid_618646
  var valid_618647 = query.getOrDefault("next-token")
  valid_618647 = validateParameter(valid_618647, JString, required = false,
                                 default = nil)
  if valid_618647 != nil:
    section.add "next-token", valid_618647
  var valid_618648 = query.getOrDefault("page-size")
  valid_618648 = validateParameter(valid_618648, JString, required = false,
                                 default = nil)
  if valid_618648 != nil:
    section.add "page-size", valid_618648
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
  var valid_618649 = header.getOrDefault("X-Amz-Date")
  valid_618649 = validateParameter(valid_618649, JString, required = false,
                                 default = nil)
  if valid_618649 != nil:
    section.add "X-Amz-Date", valid_618649
  var valid_618650 = header.getOrDefault("X-Amz-Security-Token")
  valid_618650 = validateParameter(valid_618650, JString, required = false,
                                 default = nil)
  if valid_618650 != nil:
    section.add "X-Amz-Security-Token", valid_618650
  var valid_618651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618651 = validateParameter(valid_618651, JString, required = false,
                                 default = nil)
  if valid_618651 != nil:
    section.add "X-Amz-Content-Sha256", valid_618651
  var valid_618652 = header.getOrDefault("X-Amz-Algorithm")
  valid_618652 = validateParameter(valid_618652, JString, required = false,
                                 default = nil)
  if valid_618652 != nil:
    section.add "X-Amz-Algorithm", valid_618652
  var valid_618653 = header.getOrDefault("X-Amz-Signature")
  valid_618653 = validateParameter(valid_618653, JString, required = false,
                                 default = nil)
  if valid_618653 != nil:
    section.add "X-Amz-Signature", valid_618653
  var valid_618654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618654 = validateParameter(valid_618654, JString, required = false,
                                 default = nil)
  if valid_618654 != nil:
    section.add "X-Amz-SignedHeaders", valid_618654
  var valid_618655 = header.getOrDefault("X-Amz-Credential")
  valid_618655 = validateParameter(valid_618655, JString, required = false,
                                 default = nil)
  if valid_618655 != nil:
    section.add "X-Amz-Credential", valid_618655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618656: Call_GetApplicationDateRangeKpi_618640;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_618656.validator(path, query, header, formData, body, _)
  let scheme = call_618656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618656.url(scheme.get, call_618656.host, call_618656.base,
                         call_618656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618656, url, valid, _)

proc call*(call_618657: Call_GetApplicationDateRangeKpi_618640;
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
  var path_618658 = newJObject()
  var query_618659 = newJObject()
  add(query_618659, "end-time", newJString(endTime))
  add(path_618658, "application-id", newJString(applicationId))
  add(path_618658, "kpi-name", newJString(kpiName))
  add(query_618659, "start-time", newJString(startTime))
  add(query_618659, "next-token", newJString(nextToken))
  add(query_618659, "page-size", newJString(pageSize))
  result = call_618657.call(path_618658, query_618659, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_618640(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_618641, base: "/",
    url: url_GetApplicationDateRangeKpi_618642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_618674 = ref object of OpenApiRestCall_616850
proc url_UpdateApplicationSettings_618676(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_618675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618677 = path.getOrDefault("application-id")
  valid_618677 = validateParameter(valid_618677, JString, required = true,
                                 default = nil)
  if valid_618677 != nil:
    section.add "application-id", valid_618677
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
  var valid_618678 = header.getOrDefault("X-Amz-Date")
  valid_618678 = validateParameter(valid_618678, JString, required = false,
                                 default = nil)
  if valid_618678 != nil:
    section.add "X-Amz-Date", valid_618678
  var valid_618679 = header.getOrDefault("X-Amz-Security-Token")
  valid_618679 = validateParameter(valid_618679, JString, required = false,
                                 default = nil)
  if valid_618679 != nil:
    section.add "X-Amz-Security-Token", valid_618679
  var valid_618680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618680 = validateParameter(valid_618680, JString, required = false,
                                 default = nil)
  if valid_618680 != nil:
    section.add "X-Amz-Content-Sha256", valid_618680
  var valid_618681 = header.getOrDefault("X-Amz-Algorithm")
  valid_618681 = validateParameter(valid_618681, JString, required = false,
                                 default = nil)
  if valid_618681 != nil:
    section.add "X-Amz-Algorithm", valid_618681
  var valid_618682 = header.getOrDefault("X-Amz-Signature")
  valid_618682 = validateParameter(valid_618682, JString, required = false,
                                 default = nil)
  if valid_618682 != nil:
    section.add "X-Amz-Signature", valid_618682
  var valid_618683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618683 = validateParameter(valid_618683, JString, required = false,
                                 default = nil)
  if valid_618683 != nil:
    section.add "X-Amz-SignedHeaders", valid_618683
  var valid_618684 = header.getOrDefault("X-Amz-Credential")
  valid_618684 = validateParameter(valid_618684, JString, required = false,
                                 default = nil)
  if valid_618684 != nil:
    section.add "X-Amz-Credential", valid_618684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618686: Call_UpdateApplicationSettings_618674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_618686.validator(path, query, header, formData, body, _)
  let scheme = call_618686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618686.url(scheme.get, call_618686.host, call_618686.base,
                         call_618686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618686, url, valid, _)

proc call*(call_618687: Call_UpdateApplicationSettings_618674;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_618688 = newJObject()
  var body_618689 = newJObject()
  add(path_618688, "application-id", newJString(applicationId))
  if body != nil:
    body_618689 = body
  result = call_618687.call(path_618688, nil, nil, nil, body_618689)

var updateApplicationSettings* = Call_UpdateApplicationSettings_618674(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_618675, base: "/",
    url: url_UpdateApplicationSettings_618676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_618660 = ref object of OpenApiRestCall_616850
proc url_GetApplicationSettings_618662(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetApplicationSettings_618661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618663 = path.getOrDefault("application-id")
  valid_618663 = validateParameter(valid_618663, JString, required = true,
                                 default = nil)
  if valid_618663 != nil:
    section.add "application-id", valid_618663
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
  var valid_618664 = header.getOrDefault("X-Amz-Date")
  valid_618664 = validateParameter(valid_618664, JString, required = false,
                                 default = nil)
  if valid_618664 != nil:
    section.add "X-Amz-Date", valid_618664
  var valid_618665 = header.getOrDefault("X-Amz-Security-Token")
  valid_618665 = validateParameter(valid_618665, JString, required = false,
                                 default = nil)
  if valid_618665 != nil:
    section.add "X-Amz-Security-Token", valid_618665
  var valid_618666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618666 = validateParameter(valid_618666, JString, required = false,
                                 default = nil)
  if valid_618666 != nil:
    section.add "X-Amz-Content-Sha256", valid_618666
  var valid_618667 = header.getOrDefault("X-Amz-Algorithm")
  valid_618667 = validateParameter(valid_618667, JString, required = false,
                                 default = nil)
  if valid_618667 != nil:
    section.add "X-Amz-Algorithm", valid_618667
  var valid_618668 = header.getOrDefault("X-Amz-Signature")
  valid_618668 = validateParameter(valid_618668, JString, required = false,
                                 default = nil)
  if valid_618668 != nil:
    section.add "X-Amz-Signature", valid_618668
  var valid_618669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618669 = validateParameter(valid_618669, JString, required = false,
                                 default = nil)
  if valid_618669 != nil:
    section.add "X-Amz-SignedHeaders", valid_618669
  var valid_618670 = header.getOrDefault("X-Amz-Credential")
  valid_618670 = validateParameter(valid_618670, JString, required = false,
                                 default = nil)
  if valid_618670 != nil:
    section.add "X-Amz-Credential", valid_618670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618671: Call_GetApplicationSettings_618660; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_618671.validator(path, query, header, formData, body, _)
  let scheme = call_618671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618671.url(scheme.get, call_618671.host, call_618671.base,
                         call_618671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618671, url, valid, _)

proc call*(call_618672: Call_GetApplicationSettings_618660; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618673 = newJObject()
  add(path_618673, "application-id", newJString(applicationId))
  result = call_618672.call(path_618673, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_618660(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_618661, base: "/",
    url: url_GetApplicationSettings_618662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_618690 = ref object of OpenApiRestCall_616850
proc url_GetCampaignActivities_618692(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/activities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignActivities_618691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618693 = path.getOrDefault("application-id")
  valid_618693 = validateParameter(valid_618693, JString, required = true,
                                 default = nil)
  if valid_618693 != nil:
    section.add "application-id", valid_618693
  var valid_618694 = path.getOrDefault("campaign-id")
  valid_618694 = validateParameter(valid_618694, JString, required = true,
                                 default = nil)
  if valid_618694 != nil:
    section.add "campaign-id", valid_618694
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618695 = query.getOrDefault("token")
  valid_618695 = validateParameter(valid_618695, JString, required = false,
                                 default = nil)
  if valid_618695 != nil:
    section.add "token", valid_618695
  var valid_618696 = query.getOrDefault("page-size")
  valid_618696 = validateParameter(valid_618696, JString, required = false,
                                 default = nil)
  if valid_618696 != nil:
    section.add "page-size", valid_618696
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
  var valid_618697 = header.getOrDefault("X-Amz-Date")
  valid_618697 = validateParameter(valid_618697, JString, required = false,
                                 default = nil)
  if valid_618697 != nil:
    section.add "X-Amz-Date", valid_618697
  var valid_618698 = header.getOrDefault("X-Amz-Security-Token")
  valid_618698 = validateParameter(valid_618698, JString, required = false,
                                 default = nil)
  if valid_618698 != nil:
    section.add "X-Amz-Security-Token", valid_618698
  var valid_618699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618699 = validateParameter(valid_618699, JString, required = false,
                                 default = nil)
  if valid_618699 != nil:
    section.add "X-Amz-Content-Sha256", valid_618699
  var valid_618700 = header.getOrDefault("X-Amz-Algorithm")
  valid_618700 = validateParameter(valid_618700, JString, required = false,
                                 default = nil)
  if valid_618700 != nil:
    section.add "X-Amz-Algorithm", valid_618700
  var valid_618701 = header.getOrDefault("X-Amz-Signature")
  valid_618701 = validateParameter(valid_618701, JString, required = false,
                                 default = nil)
  if valid_618701 != nil:
    section.add "X-Amz-Signature", valid_618701
  var valid_618702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618702 = validateParameter(valid_618702, JString, required = false,
                                 default = nil)
  if valid_618702 != nil:
    section.add "X-Amz-SignedHeaders", valid_618702
  var valid_618703 = header.getOrDefault("X-Amz-Credential")
  valid_618703 = validateParameter(valid_618703, JString, required = false,
                                 default = nil)
  if valid_618703 != nil:
    section.add "X-Amz-Credential", valid_618703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618704: Call_GetCampaignActivities_618690; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_618704.validator(path, query, header, formData, body, _)
  let scheme = call_618704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618704.url(scheme.get, call_618704.host, call_618704.base,
                         call_618704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618704, url, valid, _)

proc call*(call_618705: Call_GetCampaignActivities_618690; applicationId: string;
          campaignId: string; token: string = ""; pageSize: string = ""): Recallable =
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
  var path_618706 = newJObject()
  var query_618707 = newJObject()
  add(query_618707, "token", newJString(token))
  add(path_618706, "application-id", newJString(applicationId))
  add(path_618706, "campaign-id", newJString(campaignId))
  add(query_618707, "page-size", newJString(pageSize))
  result = call_618705.call(path_618706, query_618707, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_618690(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_618691, base: "/",
    url: url_GetCampaignActivities_618692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_618708 = ref object of OpenApiRestCall_616850
proc url_GetCampaignDateRangeKpi_618710(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_GetCampaignDateRangeKpi_618709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618711 = path.getOrDefault("application-id")
  valid_618711 = validateParameter(valid_618711, JString, required = true,
                                 default = nil)
  if valid_618711 != nil:
    section.add "application-id", valid_618711
  var valid_618712 = path.getOrDefault("kpi-name")
  valid_618712 = validateParameter(valid_618712, JString, required = true,
                                 default = nil)
  if valid_618712 != nil:
    section.add "kpi-name", valid_618712
  var valid_618713 = path.getOrDefault("campaign-id")
  valid_618713 = validateParameter(valid_618713, JString, required = true,
                                 default = nil)
  if valid_618713 != nil:
    section.add "campaign-id", valid_618713
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
  var valid_618714 = query.getOrDefault("end-time")
  valid_618714 = validateParameter(valid_618714, JString, required = false,
                                 default = nil)
  if valid_618714 != nil:
    section.add "end-time", valid_618714
  var valid_618715 = query.getOrDefault("start-time")
  valid_618715 = validateParameter(valid_618715, JString, required = false,
                                 default = nil)
  if valid_618715 != nil:
    section.add "start-time", valid_618715
  var valid_618716 = query.getOrDefault("next-token")
  valid_618716 = validateParameter(valid_618716, JString, required = false,
                                 default = nil)
  if valid_618716 != nil:
    section.add "next-token", valid_618716
  var valid_618717 = query.getOrDefault("page-size")
  valid_618717 = validateParameter(valid_618717, JString, required = false,
                                 default = nil)
  if valid_618717 != nil:
    section.add "page-size", valid_618717
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
  var valid_618718 = header.getOrDefault("X-Amz-Date")
  valid_618718 = validateParameter(valid_618718, JString, required = false,
                                 default = nil)
  if valid_618718 != nil:
    section.add "X-Amz-Date", valid_618718
  var valid_618719 = header.getOrDefault("X-Amz-Security-Token")
  valid_618719 = validateParameter(valid_618719, JString, required = false,
                                 default = nil)
  if valid_618719 != nil:
    section.add "X-Amz-Security-Token", valid_618719
  var valid_618720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618720 = validateParameter(valid_618720, JString, required = false,
                                 default = nil)
  if valid_618720 != nil:
    section.add "X-Amz-Content-Sha256", valid_618720
  var valid_618721 = header.getOrDefault("X-Amz-Algorithm")
  valid_618721 = validateParameter(valid_618721, JString, required = false,
                                 default = nil)
  if valid_618721 != nil:
    section.add "X-Amz-Algorithm", valid_618721
  var valid_618722 = header.getOrDefault("X-Amz-Signature")
  valid_618722 = validateParameter(valid_618722, JString, required = false,
                                 default = nil)
  if valid_618722 != nil:
    section.add "X-Amz-Signature", valid_618722
  var valid_618723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618723 = validateParameter(valid_618723, JString, required = false,
                                 default = nil)
  if valid_618723 != nil:
    section.add "X-Amz-SignedHeaders", valid_618723
  var valid_618724 = header.getOrDefault("X-Amz-Credential")
  valid_618724 = validateParameter(valid_618724, JString, required = false,
                                 default = nil)
  if valid_618724 != nil:
    section.add "X-Amz-Credential", valid_618724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618725: Call_GetCampaignDateRangeKpi_618708; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_618725.validator(path, query, header, formData, body, _)
  let scheme = call_618725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618725.url(scheme.get, call_618725.host, call_618725.base,
                         call_618725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618725, url, valid, _)

proc call*(call_618726: Call_GetCampaignDateRangeKpi_618708; applicationId: string;
          kpiName: string; campaignId: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
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
  var path_618727 = newJObject()
  var query_618728 = newJObject()
  add(query_618728, "end-time", newJString(endTime))
  add(path_618727, "application-id", newJString(applicationId))
  add(path_618727, "kpi-name", newJString(kpiName))
  add(query_618728, "start-time", newJString(startTime))
  add(query_618728, "next-token", newJString(nextToken))
  add(path_618727, "campaign-id", newJString(campaignId))
  add(query_618728, "page-size", newJString(pageSize))
  result = call_618726.call(path_618727, query_618728, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_618708(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_618709, base: "/",
    url: url_GetCampaignDateRangeKpi_618710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_618729 = ref object of OpenApiRestCall_616850
proc url_GetCampaignVersion_618731(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_618730(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   version: JString (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618732 = path.getOrDefault("application-id")
  valid_618732 = validateParameter(valid_618732, JString, required = true,
                                 default = nil)
  if valid_618732 != nil:
    section.add "application-id", valid_618732
  var valid_618733 = path.getOrDefault("version")
  valid_618733 = validateParameter(valid_618733, JString, required = true,
                                 default = nil)
  if valid_618733 != nil:
    section.add "version", valid_618733
  var valid_618734 = path.getOrDefault("campaign-id")
  valid_618734 = validateParameter(valid_618734, JString, required = true,
                                 default = nil)
  if valid_618734 != nil:
    section.add "campaign-id", valid_618734
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
  var valid_618735 = header.getOrDefault("X-Amz-Date")
  valid_618735 = validateParameter(valid_618735, JString, required = false,
                                 default = nil)
  if valid_618735 != nil:
    section.add "X-Amz-Date", valid_618735
  var valid_618736 = header.getOrDefault("X-Amz-Security-Token")
  valid_618736 = validateParameter(valid_618736, JString, required = false,
                                 default = nil)
  if valid_618736 != nil:
    section.add "X-Amz-Security-Token", valid_618736
  var valid_618737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618737 = validateParameter(valid_618737, JString, required = false,
                                 default = nil)
  if valid_618737 != nil:
    section.add "X-Amz-Content-Sha256", valid_618737
  var valid_618738 = header.getOrDefault("X-Amz-Algorithm")
  valid_618738 = validateParameter(valid_618738, JString, required = false,
                                 default = nil)
  if valid_618738 != nil:
    section.add "X-Amz-Algorithm", valid_618738
  var valid_618739 = header.getOrDefault("X-Amz-Signature")
  valid_618739 = validateParameter(valid_618739, JString, required = false,
                                 default = nil)
  if valid_618739 != nil:
    section.add "X-Amz-Signature", valid_618739
  var valid_618740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618740 = validateParameter(valid_618740, JString, required = false,
                                 default = nil)
  if valid_618740 != nil:
    section.add "X-Amz-SignedHeaders", valid_618740
  var valid_618741 = header.getOrDefault("X-Amz-Credential")
  valid_618741 = validateParameter(valid_618741, JString, required = false,
                                 default = nil)
  if valid_618741 != nil:
    section.add "X-Amz-Credential", valid_618741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618742: Call_GetCampaignVersion_618729; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_618742.validator(path, query, header, formData, body, _)
  let scheme = call_618742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618742.url(scheme.get, call_618742.host, call_618742.base,
                         call_618742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618742, url, valid, _)

proc call*(call_618743: Call_GetCampaignVersion_618729; applicationId: string;
          version: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_618744 = newJObject()
  add(path_618744, "application-id", newJString(applicationId))
  add(path_618744, "version", newJString(version))
  add(path_618744, "campaign-id", newJString(campaignId))
  result = call_618743.call(path_618744, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_618729(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_618730, base: "/",
    url: url_GetCampaignVersion_618731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_618745 = ref object of OpenApiRestCall_616850
proc url_GetCampaignVersions_618747(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_618746(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618748 = path.getOrDefault("application-id")
  valid_618748 = validateParameter(valid_618748, JString, required = true,
                                 default = nil)
  if valid_618748 != nil:
    section.add "application-id", valid_618748
  var valid_618749 = path.getOrDefault("campaign-id")
  valid_618749 = validateParameter(valid_618749, JString, required = true,
                                 default = nil)
  if valid_618749 != nil:
    section.add "campaign-id", valid_618749
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618750 = query.getOrDefault("token")
  valid_618750 = validateParameter(valid_618750, JString, required = false,
                                 default = nil)
  if valid_618750 != nil:
    section.add "token", valid_618750
  var valid_618751 = query.getOrDefault("page-size")
  valid_618751 = validateParameter(valid_618751, JString, required = false,
                                 default = nil)
  if valid_618751 != nil:
    section.add "page-size", valid_618751
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
  var valid_618752 = header.getOrDefault("X-Amz-Date")
  valid_618752 = validateParameter(valid_618752, JString, required = false,
                                 default = nil)
  if valid_618752 != nil:
    section.add "X-Amz-Date", valid_618752
  var valid_618753 = header.getOrDefault("X-Amz-Security-Token")
  valid_618753 = validateParameter(valid_618753, JString, required = false,
                                 default = nil)
  if valid_618753 != nil:
    section.add "X-Amz-Security-Token", valid_618753
  var valid_618754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618754 = validateParameter(valid_618754, JString, required = false,
                                 default = nil)
  if valid_618754 != nil:
    section.add "X-Amz-Content-Sha256", valid_618754
  var valid_618755 = header.getOrDefault("X-Amz-Algorithm")
  valid_618755 = validateParameter(valid_618755, JString, required = false,
                                 default = nil)
  if valid_618755 != nil:
    section.add "X-Amz-Algorithm", valid_618755
  var valid_618756 = header.getOrDefault("X-Amz-Signature")
  valid_618756 = validateParameter(valid_618756, JString, required = false,
                                 default = nil)
  if valid_618756 != nil:
    section.add "X-Amz-Signature", valid_618756
  var valid_618757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618757 = validateParameter(valid_618757, JString, required = false,
                                 default = nil)
  if valid_618757 != nil:
    section.add "X-Amz-SignedHeaders", valid_618757
  var valid_618758 = header.getOrDefault("X-Amz-Credential")
  valid_618758 = validateParameter(valid_618758, JString, required = false,
                                 default = nil)
  if valid_618758 != nil:
    section.add "X-Amz-Credential", valid_618758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618759: Call_GetCampaignVersions_618745; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_618759.validator(path, query, header, formData, body, _)
  let scheme = call_618759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618759.url(scheme.get, call_618759.host, call_618759.base,
                         call_618759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618759, url, valid, _)

proc call*(call_618760: Call_GetCampaignVersions_618745; applicationId: string;
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
  var path_618761 = newJObject()
  var query_618762 = newJObject()
  add(query_618762, "token", newJString(token))
  add(path_618761, "application-id", newJString(applicationId))
  add(path_618761, "campaign-id", newJString(campaignId))
  add(query_618762, "page-size", newJString(pageSize))
  result = call_618760.call(path_618761, query_618762, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_618745(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_618746, base: "/",
    url: url_GetCampaignVersions_618747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_618763 = ref object of OpenApiRestCall_616850
proc url_GetChannels_618765(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_618764(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618766 = path.getOrDefault("application-id")
  valid_618766 = validateParameter(valid_618766, JString, required = true,
                                 default = nil)
  if valid_618766 != nil:
    section.add "application-id", valid_618766
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
  var valid_618767 = header.getOrDefault("X-Amz-Date")
  valid_618767 = validateParameter(valid_618767, JString, required = false,
                                 default = nil)
  if valid_618767 != nil:
    section.add "X-Amz-Date", valid_618767
  var valid_618768 = header.getOrDefault("X-Amz-Security-Token")
  valid_618768 = validateParameter(valid_618768, JString, required = false,
                                 default = nil)
  if valid_618768 != nil:
    section.add "X-Amz-Security-Token", valid_618768
  var valid_618769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618769 = validateParameter(valid_618769, JString, required = false,
                                 default = nil)
  if valid_618769 != nil:
    section.add "X-Amz-Content-Sha256", valid_618769
  var valid_618770 = header.getOrDefault("X-Amz-Algorithm")
  valid_618770 = validateParameter(valid_618770, JString, required = false,
                                 default = nil)
  if valid_618770 != nil:
    section.add "X-Amz-Algorithm", valid_618770
  var valid_618771 = header.getOrDefault("X-Amz-Signature")
  valid_618771 = validateParameter(valid_618771, JString, required = false,
                                 default = nil)
  if valid_618771 != nil:
    section.add "X-Amz-Signature", valid_618771
  var valid_618772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618772 = validateParameter(valid_618772, JString, required = false,
                                 default = nil)
  if valid_618772 != nil:
    section.add "X-Amz-SignedHeaders", valid_618772
  var valid_618773 = header.getOrDefault("X-Amz-Credential")
  valid_618773 = validateParameter(valid_618773, JString, required = false,
                                 default = nil)
  if valid_618773 != nil:
    section.add "X-Amz-Credential", valid_618773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618774: Call_GetChannels_618763; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_618774.validator(path, query, header, formData, body, _)
  let scheme = call_618774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618774.url(scheme.get, call_618774.host, call_618774.base,
                         call_618774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618774, url, valid, _)

proc call*(call_618775: Call_GetChannels_618763; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_618776 = newJObject()
  add(path_618776, "application-id", newJString(applicationId))
  result = call_618775.call(path_618776, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_618763(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_618764,
                                        base: "/", url: url_GetChannels_618765,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_618777 = ref object of OpenApiRestCall_616850
proc url_GetExportJob_618779(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_618778(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618780 = path.getOrDefault("application-id")
  valid_618780 = validateParameter(valid_618780, JString, required = true,
                                 default = nil)
  if valid_618780 != nil:
    section.add "application-id", valid_618780
  var valid_618781 = path.getOrDefault("job-id")
  valid_618781 = validateParameter(valid_618781, JString, required = true,
                                 default = nil)
  if valid_618781 != nil:
    section.add "job-id", valid_618781
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
  var valid_618782 = header.getOrDefault("X-Amz-Date")
  valid_618782 = validateParameter(valid_618782, JString, required = false,
                                 default = nil)
  if valid_618782 != nil:
    section.add "X-Amz-Date", valid_618782
  var valid_618783 = header.getOrDefault("X-Amz-Security-Token")
  valid_618783 = validateParameter(valid_618783, JString, required = false,
                                 default = nil)
  if valid_618783 != nil:
    section.add "X-Amz-Security-Token", valid_618783
  var valid_618784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618784 = validateParameter(valid_618784, JString, required = false,
                                 default = nil)
  if valid_618784 != nil:
    section.add "X-Amz-Content-Sha256", valid_618784
  var valid_618785 = header.getOrDefault("X-Amz-Algorithm")
  valid_618785 = validateParameter(valid_618785, JString, required = false,
                                 default = nil)
  if valid_618785 != nil:
    section.add "X-Amz-Algorithm", valid_618785
  var valid_618786 = header.getOrDefault("X-Amz-Signature")
  valid_618786 = validateParameter(valid_618786, JString, required = false,
                                 default = nil)
  if valid_618786 != nil:
    section.add "X-Amz-Signature", valid_618786
  var valid_618787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618787 = validateParameter(valid_618787, JString, required = false,
                                 default = nil)
  if valid_618787 != nil:
    section.add "X-Amz-SignedHeaders", valid_618787
  var valid_618788 = header.getOrDefault("X-Amz-Credential")
  valid_618788 = validateParameter(valid_618788, JString, required = false,
                                 default = nil)
  if valid_618788 != nil:
    section.add "X-Amz-Credential", valid_618788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618789: Call_GetExportJob_618777; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_618789.validator(path, query, header, formData, body, _)
  let scheme = call_618789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618789.url(scheme.get, call_618789.host, call_618789.base,
                         call_618789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618789, url, valid, _)

proc call*(call_618790: Call_GetExportJob_618777; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_618791 = newJObject()
  add(path_618791, "application-id", newJString(applicationId))
  add(path_618791, "job-id", newJString(jobId))
  result = call_618790.call(path_618791, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_618777(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_618778, base: "/", url: url_GetExportJob_618779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_618792 = ref object of OpenApiRestCall_616850
proc url_GetImportJob_618794(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_618793(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618795 = path.getOrDefault("application-id")
  valid_618795 = validateParameter(valid_618795, JString, required = true,
                                 default = nil)
  if valid_618795 != nil:
    section.add "application-id", valid_618795
  var valid_618796 = path.getOrDefault("job-id")
  valid_618796 = validateParameter(valid_618796, JString, required = true,
                                 default = nil)
  if valid_618796 != nil:
    section.add "job-id", valid_618796
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
  var valid_618797 = header.getOrDefault("X-Amz-Date")
  valid_618797 = validateParameter(valid_618797, JString, required = false,
                                 default = nil)
  if valid_618797 != nil:
    section.add "X-Amz-Date", valid_618797
  var valid_618798 = header.getOrDefault("X-Amz-Security-Token")
  valid_618798 = validateParameter(valid_618798, JString, required = false,
                                 default = nil)
  if valid_618798 != nil:
    section.add "X-Amz-Security-Token", valid_618798
  var valid_618799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618799 = validateParameter(valid_618799, JString, required = false,
                                 default = nil)
  if valid_618799 != nil:
    section.add "X-Amz-Content-Sha256", valid_618799
  var valid_618800 = header.getOrDefault("X-Amz-Algorithm")
  valid_618800 = validateParameter(valid_618800, JString, required = false,
                                 default = nil)
  if valid_618800 != nil:
    section.add "X-Amz-Algorithm", valid_618800
  var valid_618801 = header.getOrDefault("X-Amz-Signature")
  valid_618801 = validateParameter(valid_618801, JString, required = false,
                                 default = nil)
  if valid_618801 != nil:
    section.add "X-Amz-Signature", valid_618801
  var valid_618802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618802 = validateParameter(valid_618802, JString, required = false,
                                 default = nil)
  if valid_618802 != nil:
    section.add "X-Amz-SignedHeaders", valid_618802
  var valid_618803 = header.getOrDefault("X-Amz-Credential")
  valid_618803 = validateParameter(valid_618803, JString, required = false,
                                 default = nil)
  if valid_618803 != nil:
    section.add "X-Amz-Credential", valid_618803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618804: Call_GetImportJob_618792; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_618804.validator(path, query, header, formData, body, _)
  let scheme = call_618804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618804.url(scheme.get, call_618804.host, call_618804.base,
                         call_618804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618804, url, valid, _)

proc call*(call_618805: Call_GetImportJob_618792; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_618806 = newJObject()
  add(path_618806, "application-id", newJString(applicationId))
  add(path_618806, "job-id", newJString(jobId))
  result = call_618805.call(path_618806, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_618792(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_618793, base: "/", url: url_GetImportJob_618794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_618807 = ref object of OpenApiRestCall_616850
proc url_GetJourneyDateRangeKpi_618809(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetJourneyDateRangeKpi_618808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618810 = path.getOrDefault("journey-id")
  valid_618810 = validateParameter(valid_618810, JString, required = true,
                                 default = nil)
  if valid_618810 != nil:
    section.add "journey-id", valid_618810
  var valid_618811 = path.getOrDefault("application-id")
  valid_618811 = validateParameter(valid_618811, JString, required = true,
                                 default = nil)
  if valid_618811 != nil:
    section.add "application-id", valid_618811
  var valid_618812 = path.getOrDefault("kpi-name")
  valid_618812 = validateParameter(valid_618812, JString, required = true,
                                 default = nil)
  if valid_618812 != nil:
    section.add "kpi-name", valid_618812
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
  var valid_618813 = query.getOrDefault("end-time")
  valid_618813 = validateParameter(valid_618813, JString, required = false,
                                 default = nil)
  if valid_618813 != nil:
    section.add "end-time", valid_618813
  var valid_618814 = query.getOrDefault("start-time")
  valid_618814 = validateParameter(valid_618814, JString, required = false,
                                 default = nil)
  if valid_618814 != nil:
    section.add "start-time", valid_618814
  var valid_618815 = query.getOrDefault("next-token")
  valid_618815 = validateParameter(valid_618815, JString, required = false,
                                 default = nil)
  if valid_618815 != nil:
    section.add "next-token", valid_618815
  var valid_618816 = query.getOrDefault("page-size")
  valid_618816 = validateParameter(valid_618816, JString, required = false,
                                 default = nil)
  if valid_618816 != nil:
    section.add "page-size", valid_618816
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
  var valid_618817 = header.getOrDefault("X-Amz-Date")
  valid_618817 = validateParameter(valid_618817, JString, required = false,
                                 default = nil)
  if valid_618817 != nil:
    section.add "X-Amz-Date", valid_618817
  var valid_618818 = header.getOrDefault("X-Amz-Security-Token")
  valid_618818 = validateParameter(valid_618818, JString, required = false,
                                 default = nil)
  if valid_618818 != nil:
    section.add "X-Amz-Security-Token", valid_618818
  var valid_618819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618819 = validateParameter(valid_618819, JString, required = false,
                                 default = nil)
  if valid_618819 != nil:
    section.add "X-Amz-Content-Sha256", valid_618819
  var valid_618820 = header.getOrDefault("X-Amz-Algorithm")
  valid_618820 = validateParameter(valid_618820, JString, required = false,
                                 default = nil)
  if valid_618820 != nil:
    section.add "X-Amz-Algorithm", valid_618820
  var valid_618821 = header.getOrDefault("X-Amz-Signature")
  valid_618821 = validateParameter(valid_618821, JString, required = false,
                                 default = nil)
  if valid_618821 != nil:
    section.add "X-Amz-Signature", valid_618821
  var valid_618822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618822 = validateParameter(valid_618822, JString, required = false,
                                 default = nil)
  if valid_618822 != nil:
    section.add "X-Amz-SignedHeaders", valid_618822
  var valid_618823 = header.getOrDefault("X-Amz-Credential")
  valid_618823 = validateParameter(valid_618823, JString, required = false,
                                 default = nil)
  if valid_618823 != nil:
    section.add "X-Amz-Credential", valid_618823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618824: Call_GetJourneyDateRangeKpi_618807; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_618824.validator(path, query, header, formData, body, _)
  let scheme = call_618824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618824.url(scheme.get, call_618824.host, call_618824.base,
                         call_618824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618824, url, valid, _)

proc call*(call_618825: Call_GetJourneyDateRangeKpi_618807; journeyId: string;
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
  var path_618826 = newJObject()
  var query_618827 = newJObject()
  add(path_618826, "journey-id", newJString(journeyId))
  add(query_618827, "end-time", newJString(endTime))
  add(path_618826, "application-id", newJString(applicationId))
  add(path_618826, "kpi-name", newJString(kpiName))
  add(query_618827, "start-time", newJString(startTime))
  add(query_618827, "next-token", newJString(nextToken))
  add(query_618827, "page-size", newJString(pageSize))
  result = call_618825.call(path_618826, query_618827, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_618807(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_618808, base: "/",
    url: url_GetJourneyDateRangeKpi_618809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_618828 = ref object of OpenApiRestCall_616850
proc url_GetJourneyExecutionActivityMetrics_618830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetJourneyExecutionActivityMetrics_618829(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618831 = path.getOrDefault("journey-id")
  valid_618831 = validateParameter(valid_618831, JString, required = true,
                                 default = nil)
  if valid_618831 != nil:
    section.add "journey-id", valid_618831
  var valid_618832 = path.getOrDefault("application-id")
  valid_618832 = validateParameter(valid_618832, JString, required = true,
                                 default = nil)
  if valid_618832 != nil:
    section.add "application-id", valid_618832
  var valid_618833 = path.getOrDefault("journey-activity-id")
  valid_618833 = validateParameter(valid_618833, JString, required = true,
                                 default = nil)
  if valid_618833 != nil:
    section.add "journey-activity-id", valid_618833
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618834 = query.getOrDefault("next-token")
  valid_618834 = validateParameter(valid_618834, JString, required = false,
                                 default = nil)
  if valid_618834 != nil:
    section.add "next-token", valid_618834
  var valid_618835 = query.getOrDefault("page-size")
  valid_618835 = validateParameter(valid_618835, JString, required = false,
                                 default = nil)
  if valid_618835 != nil:
    section.add "page-size", valid_618835
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
  var valid_618836 = header.getOrDefault("X-Amz-Date")
  valid_618836 = validateParameter(valid_618836, JString, required = false,
                                 default = nil)
  if valid_618836 != nil:
    section.add "X-Amz-Date", valid_618836
  var valid_618837 = header.getOrDefault("X-Amz-Security-Token")
  valid_618837 = validateParameter(valid_618837, JString, required = false,
                                 default = nil)
  if valid_618837 != nil:
    section.add "X-Amz-Security-Token", valid_618837
  var valid_618838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618838 = validateParameter(valid_618838, JString, required = false,
                                 default = nil)
  if valid_618838 != nil:
    section.add "X-Amz-Content-Sha256", valid_618838
  var valid_618839 = header.getOrDefault("X-Amz-Algorithm")
  valid_618839 = validateParameter(valid_618839, JString, required = false,
                                 default = nil)
  if valid_618839 != nil:
    section.add "X-Amz-Algorithm", valid_618839
  var valid_618840 = header.getOrDefault("X-Amz-Signature")
  valid_618840 = validateParameter(valid_618840, JString, required = false,
                                 default = nil)
  if valid_618840 != nil:
    section.add "X-Amz-Signature", valid_618840
  var valid_618841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618841 = validateParameter(valid_618841, JString, required = false,
                                 default = nil)
  if valid_618841 != nil:
    section.add "X-Amz-SignedHeaders", valid_618841
  var valid_618842 = header.getOrDefault("X-Amz-Credential")
  valid_618842 = validateParameter(valid_618842, JString, required = false,
                                 default = nil)
  if valid_618842 != nil:
    section.add "X-Amz-Credential", valid_618842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618843: Call_GetJourneyExecutionActivityMetrics_618828;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_618843.validator(path, query, header, formData, body, _)
  let scheme = call_618843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618843.url(scheme.get, call_618843.host, call_618843.base,
                         call_618843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618843, url, valid, _)

proc call*(call_618844: Call_GetJourneyExecutionActivityMetrics_618828;
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
  var path_618845 = newJObject()
  var query_618846 = newJObject()
  add(path_618845, "journey-id", newJString(journeyId))
  add(path_618845, "application-id", newJString(applicationId))
  add(path_618845, "journey-activity-id", newJString(journeyActivityId))
  add(query_618846, "next-token", newJString(nextToken))
  add(query_618846, "page-size", newJString(pageSize))
  result = call_618844.call(path_618845, query_618846, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_618828(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_618829, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_618830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_618847 = ref object of OpenApiRestCall_616850
proc url_GetJourneyExecutionMetrics_618849(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_618848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618850 = path.getOrDefault("journey-id")
  valid_618850 = validateParameter(valid_618850, JString, required = true,
                                 default = nil)
  if valid_618850 != nil:
    section.add "journey-id", valid_618850
  var valid_618851 = path.getOrDefault("application-id")
  valid_618851 = validateParameter(valid_618851, JString, required = true,
                                 default = nil)
  if valid_618851 != nil:
    section.add "application-id", valid_618851
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618852 = query.getOrDefault("next-token")
  valid_618852 = validateParameter(valid_618852, JString, required = false,
                                 default = nil)
  if valid_618852 != nil:
    section.add "next-token", valid_618852
  var valid_618853 = query.getOrDefault("page-size")
  valid_618853 = validateParameter(valid_618853, JString, required = false,
                                 default = nil)
  if valid_618853 != nil:
    section.add "page-size", valid_618853
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
  var valid_618854 = header.getOrDefault("X-Amz-Date")
  valid_618854 = validateParameter(valid_618854, JString, required = false,
                                 default = nil)
  if valid_618854 != nil:
    section.add "X-Amz-Date", valid_618854
  var valid_618855 = header.getOrDefault("X-Amz-Security-Token")
  valid_618855 = validateParameter(valid_618855, JString, required = false,
                                 default = nil)
  if valid_618855 != nil:
    section.add "X-Amz-Security-Token", valid_618855
  var valid_618856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618856 = validateParameter(valid_618856, JString, required = false,
                                 default = nil)
  if valid_618856 != nil:
    section.add "X-Amz-Content-Sha256", valid_618856
  var valid_618857 = header.getOrDefault("X-Amz-Algorithm")
  valid_618857 = validateParameter(valid_618857, JString, required = false,
                                 default = nil)
  if valid_618857 != nil:
    section.add "X-Amz-Algorithm", valid_618857
  var valid_618858 = header.getOrDefault("X-Amz-Signature")
  valid_618858 = validateParameter(valid_618858, JString, required = false,
                                 default = nil)
  if valid_618858 != nil:
    section.add "X-Amz-Signature", valid_618858
  var valid_618859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618859 = validateParameter(valid_618859, JString, required = false,
                                 default = nil)
  if valid_618859 != nil:
    section.add "X-Amz-SignedHeaders", valid_618859
  var valid_618860 = header.getOrDefault("X-Amz-Credential")
  valid_618860 = validateParameter(valid_618860, JString, required = false,
                                 default = nil)
  if valid_618860 != nil:
    section.add "X-Amz-Credential", valid_618860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618861: Call_GetJourneyExecutionMetrics_618847;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_618861.validator(path, query, header, formData, body, _)
  let scheme = call_618861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618861.url(scheme.get, call_618861.host, call_618861.base,
                         call_618861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618861, url, valid, _)

proc call*(call_618862: Call_GetJourneyExecutionMetrics_618847; journeyId: string;
          applicationId: string; nextToken: string = ""; pageSize: string = ""): Recallable =
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
  var path_618863 = newJObject()
  var query_618864 = newJObject()
  add(path_618863, "journey-id", newJString(journeyId))
  add(path_618863, "application-id", newJString(applicationId))
  add(query_618864, "next-token", newJString(nextToken))
  add(query_618864, "page-size", newJString(pageSize))
  result = call_618862.call(path_618863, query_618864, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_618847(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_618848, base: "/",
    url: url_GetJourneyExecutionMetrics_618849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_618865 = ref object of OpenApiRestCall_616850
proc url_GetSegmentExportJobs_618867(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_618866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618868 = path.getOrDefault("application-id")
  valid_618868 = validateParameter(valid_618868, JString, required = true,
                                 default = nil)
  if valid_618868 != nil:
    section.add "application-id", valid_618868
  var valid_618869 = path.getOrDefault("segment-id")
  valid_618869 = validateParameter(valid_618869, JString, required = true,
                                 default = nil)
  if valid_618869 != nil:
    section.add "segment-id", valid_618869
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618870 = query.getOrDefault("token")
  valid_618870 = validateParameter(valid_618870, JString, required = false,
                                 default = nil)
  if valid_618870 != nil:
    section.add "token", valid_618870
  var valid_618871 = query.getOrDefault("page-size")
  valid_618871 = validateParameter(valid_618871, JString, required = false,
                                 default = nil)
  if valid_618871 != nil:
    section.add "page-size", valid_618871
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
  var valid_618872 = header.getOrDefault("X-Amz-Date")
  valid_618872 = validateParameter(valid_618872, JString, required = false,
                                 default = nil)
  if valid_618872 != nil:
    section.add "X-Amz-Date", valid_618872
  var valid_618873 = header.getOrDefault("X-Amz-Security-Token")
  valid_618873 = validateParameter(valid_618873, JString, required = false,
                                 default = nil)
  if valid_618873 != nil:
    section.add "X-Amz-Security-Token", valid_618873
  var valid_618874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618874 = validateParameter(valid_618874, JString, required = false,
                                 default = nil)
  if valid_618874 != nil:
    section.add "X-Amz-Content-Sha256", valid_618874
  var valid_618875 = header.getOrDefault("X-Amz-Algorithm")
  valid_618875 = validateParameter(valid_618875, JString, required = false,
                                 default = nil)
  if valid_618875 != nil:
    section.add "X-Amz-Algorithm", valid_618875
  var valid_618876 = header.getOrDefault("X-Amz-Signature")
  valid_618876 = validateParameter(valid_618876, JString, required = false,
                                 default = nil)
  if valid_618876 != nil:
    section.add "X-Amz-Signature", valid_618876
  var valid_618877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618877 = validateParameter(valid_618877, JString, required = false,
                                 default = nil)
  if valid_618877 != nil:
    section.add "X-Amz-SignedHeaders", valid_618877
  var valid_618878 = header.getOrDefault("X-Amz-Credential")
  valid_618878 = validateParameter(valid_618878, JString, required = false,
                                 default = nil)
  if valid_618878 != nil:
    section.add "X-Amz-Credential", valid_618878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618879: Call_GetSegmentExportJobs_618865; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_618879.validator(path, query, header, formData, body, _)
  let scheme = call_618879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618879.url(scheme.get, call_618879.host, call_618879.base,
                         call_618879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618879, url, valid, _)

proc call*(call_618880: Call_GetSegmentExportJobs_618865; applicationId: string;
          segmentId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentExportJobs
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_618881 = newJObject()
  var query_618882 = newJObject()
  add(query_618882, "token", newJString(token))
  add(path_618881, "application-id", newJString(applicationId))
  add(path_618881, "segment-id", newJString(segmentId))
  add(query_618882, "page-size", newJString(pageSize))
  result = call_618880.call(path_618881, query_618882, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_618865(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_618866, base: "/",
    url: url_GetSegmentExportJobs_618867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_618883 = ref object of OpenApiRestCall_616850
proc url_GetSegmentImportJobs_618885(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_618884(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618886 = path.getOrDefault("application-id")
  valid_618886 = validateParameter(valid_618886, JString, required = true,
                                 default = nil)
  if valid_618886 != nil:
    section.add "application-id", valid_618886
  var valid_618887 = path.getOrDefault("segment-id")
  valid_618887 = validateParameter(valid_618887, JString, required = true,
                                 default = nil)
  if valid_618887 != nil:
    section.add "segment-id", valid_618887
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618888 = query.getOrDefault("token")
  valid_618888 = validateParameter(valid_618888, JString, required = false,
                                 default = nil)
  if valid_618888 != nil:
    section.add "token", valid_618888
  var valid_618889 = query.getOrDefault("page-size")
  valid_618889 = validateParameter(valid_618889, JString, required = false,
                                 default = nil)
  if valid_618889 != nil:
    section.add "page-size", valid_618889
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
  var valid_618890 = header.getOrDefault("X-Amz-Date")
  valid_618890 = validateParameter(valid_618890, JString, required = false,
                                 default = nil)
  if valid_618890 != nil:
    section.add "X-Amz-Date", valid_618890
  var valid_618891 = header.getOrDefault("X-Amz-Security-Token")
  valid_618891 = validateParameter(valid_618891, JString, required = false,
                                 default = nil)
  if valid_618891 != nil:
    section.add "X-Amz-Security-Token", valid_618891
  var valid_618892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618892 = validateParameter(valid_618892, JString, required = false,
                                 default = nil)
  if valid_618892 != nil:
    section.add "X-Amz-Content-Sha256", valid_618892
  var valid_618893 = header.getOrDefault("X-Amz-Algorithm")
  valid_618893 = validateParameter(valid_618893, JString, required = false,
                                 default = nil)
  if valid_618893 != nil:
    section.add "X-Amz-Algorithm", valid_618893
  var valid_618894 = header.getOrDefault("X-Amz-Signature")
  valid_618894 = validateParameter(valid_618894, JString, required = false,
                                 default = nil)
  if valid_618894 != nil:
    section.add "X-Amz-Signature", valid_618894
  var valid_618895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618895 = validateParameter(valid_618895, JString, required = false,
                                 default = nil)
  if valid_618895 != nil:
    section.add "X-Amz-SignedHeaders", valid_618895
  var valid_618896 = header.getOrDefault("X-Amz-Credential")
  valid_618896 = validateParameter(valid_618896, JString, required = false,
                                 default = nil)
  if valid_618896 != nil:
    section.add "X-Amz-Credential", valid_618896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618897: Call_GetSegmentImportJobs_618883; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_618897.validator(path, query, header, formData, body, _)
  let scheme = call_618897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618897.url(scheme.get, call_618897.host, call_618897.base,
                         call_618897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618897, url, valid, _)

proc call*(call_618898: Call_GetSegmentImportJobs_618883; applicationId: string;
          segmentId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentImportJobs
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_618899 = newJObject()
  var query_618900 = newJObject()
  add(query_618900, "token", newJString(token))
  add(path_618899, "application-id", newJString(applicationId))
  add(path_618899, "segment-id", newJString(segmentId))
  add(query_618900, "page-size", newJString(pageSize))
  result = call_618898.call(path_618899, query_618900, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_618883(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_618884, base: "/",
    url: url_GetSegmentImportJobs_618885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_618901 = ref object of OpenApiRestCall_616850
proc url_GetSegmentVersion_618903(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_618902(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   version: JString (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618904 = path.getOrDefault("application-id")
  valid_618904 = validateParameter(valid_618904, JString, required = true,
                                 default = nil)
  if valid_618904 != nil:
    section.add "application-id", valid_618904
  var valid_618905 = path.getOrDefault("version")
  valid_618905 = validateParameter(valid_618905, JString, required = true,
                                 default = nil)
  if valid_618905 != nil:
    section.add "version", valid_618905
  var valid_618906 = path.getOrDefault("segment-id")
  valid_618906 = validateParameter(valid_618906, JString, required = true,
                                 default = nil)
  if valid_618906 != nil:
    section.add "segment-id", valid_618906
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
  var valid_618907 = header.getOrDefault("X-Amz-Date")
  valid_618907 = validateParameter(valid_618907, JString, required = false,
                                 default = nil)
  if valid_618907 != nil:
    section.add "X-Amz-Date", valid_618907
  var valid_618908 = header.getOrDefault("X-Amz-Security-Token")
  valid_618908 = validateParameter(valid_618908, JString, required = false,
                                 default = nil)
  if valid_618908 != nil:
    section.add "X-Amz-Security-Token", valid_618908
  var valid_618909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618909 = validateParameter(valid_618909, JString, required = false,
                                 default = nil)
  if valid_618909 != nil:
    section.add "X-Amz-Content-Sha256", valid_618909
  var valid_618910 = header.getOrDefault("X-Amz-Algorithm")
  valid_618910 = validateParameter(valid_618910, JString, required = false,
                                 default = nil)
  if valid_618910 != nil:
    section.add "X-Amz-Algorithm", valid_618910
  var valid_618911 = header.getOrDefault("X-Amz-Signature")
  valid_618911 = validateParameter(valid_618911, JString, required = false,
                                 default = nil)
  if valid_618911 != nil:
    section.add "X-Amz-Signature", valid_618911
  var valid_618912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618912 = validateParameter(valid_618912, JString, required = false,
                                 default = nil)
  if valid_618912 != nil:
    section.add "X-Amz-SignedHeaders", valid_618912
  var valid_618913 = header.getOrDefault("X-Amz-Credential")
  valid_618913 = validateParameter(valid_618913, JString, required = false,
                                 default = nil)
  if valid_618913 != nil:
    section.add "X-Amz-Credential", valid_618913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618914: Call_GetSegmentVersion_618901; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_618914.validator(path, query, header, formData, body, _)
  let scheme = call_618914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618914.url(scheme.get, call_618914.host, call_618914.base,
                         call_618914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618914, url, valid, _)

proc call*(call_618915: Call_GetSegmentVersion_618901; applicationId: string;
          version: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_618916 = newJObject()
  add(path_618916, "application-id", newJString(applicationId))
  add(path_618916, "version", newJString(version))
  add(path_618916, "segment-id", newJString(segmentId))
  result = call_618915.call(path_618916, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_618901(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_618902, base: "/",
    url: url_GetSegmentVersion_618903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_618917 = ref object of OpenApiRestCall_616850
proc url_GetSegmentVersions_618919(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_618918(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_618920 = path.getOrDefault("application-id")
  valid_618920 = validateParameter(valid_618920, JString, required = true,
                                 default = nil)
  if valid_618920 != nil:
    section.add "application-id", valid_618920
  var valid_618921 = path.getOrDefault("segment-id")
  valid_618921 = validateParameter(valid_618921, JString, required = true,
                                 default = nil)
  if valid_618921 != nil:
    section.add "segment-id", valid_618921
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618922 = query.getOrDefault("token")
  valid_618922 = validateParameter(valid_618922, JString, required = false,
                                 default = nil)
  if valid_618922 != nil:
    section.add "token", valid_618922
  var valid_618923 = query.getOrDefault("page-size")
  valid_618923 = validateParameter(valid_618923, JString, required = false,
                                 default = nil)
  if valid_618923 != nil:
    section.add "page-size", valid_618923
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
  var valid_618924 = header.getOrDefault("X-Amz-Date")
  valid_618924 = validateParameter(valid_618924, JString, required = false,
                                 default = nil)
  if valid_618924 != nil:
    section.add "X-Amz-Date", valid_618924
  var valid_618925 = header.getOrDefault("X-Amz-Security-Token")
  valid_618925 = validateParameter(valid_618925, JString, required = false,
                                 default = nil)
  if valid_618925 != nil:
    section.add "X-Amz-Security-Token", valid_618925
  var valid_618926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618926 = validateParameter(valid_618926, JString, required = false,
                                 default = nil)
  if valid_618926 != nil:
    section.add "X-Amz-Content-Sha256", valid_618926
  var valid_618927 = header.getOrDefault("X-Amz-Algorithm")
  valid_618927 = validateParameter(valid_618927, JString, required = false,
                                 default = nil)
  if valid_618927 != nil:
    section.add "X-Amz-Algorithm", valid_618927
  var valid_618928 = header.getOrDefault("X-Amz-Signature")
  valid_618928 = validateParameter(valid_618928, JString, required = false,
                                 default = nil)
  if valid_618928 != nil:
    section.add "X-Amz-Signature", valid_618928
  var valid_618929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618929 = validateParameter(valid_618929, JString, required = false,
                                 default = nil)
  if valid_618929 != nil:
    section.add "X-Amz-SignedHeaders", valid_618929
  var valid_618930 = header.getOrDefault("X-Amz-Credential")
  valid_618930 = validateParameter(valid_618930, JString, required = false,
                                 default = nil)
  if valid_618930 != nil:
    section.add "X-Amz-Credential", valid_618930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618931: Call_GetSegmentVersions_618917; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_618931.validator(path, query, header, formData, body, _)
  let scheme = call_618931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618931.url(scheme.get, call_618931.host, call_618931.base,
                         call_618931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618931, url, valid, _)

proc call*(call_618932: Call_GetSegmentVersions_618917; applicationId: string;
          segmentId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_618933 = newJObject()
  var query_618934 = newJObject()
  add(query_618934, "token", newJString(token))
  add(path_618933, "application-id", newJString(applicationId))
  add(path_618933, "segment-id", newJString(segmentId))
  add(query_618934, "page-size", newJString(pageSize))
  result = call_618932.call(path_618933, query_618934, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_618917(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_618918, base: "/",
    url: url_GetSegmentVersions_618919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_618949 = ref object of OpenApiRestCall_616850
proc url_TagResource_618951(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_618950(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618952 = path.getOrDefault("resource-arn")
  valid_618952 = validateParameter(valid_618952, JString, required = true,
                                 default = nil)
  if valid_618952 != nil:
    section.add "resource-arn", valid_618952
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
  var valid_618953 = header.getOrDefault("X-Amz-Date")
  valid_618953 = validateParameter(valid_618953, JString, required = false,
                                 default = nil)
  if valid_618953 != nil:
    section.add "X-Amz-Date", valid_618953
  var valid_618954 = header.getOrDefault("X-Amz-Security-Token")
  valid_618954 = validateParameter(valid_618954, JString, required = false,
                                 default = nil)
  if valid_618954 != nil:
    section.add "X-Amz-Security-Token", valid_618954
  var valid_618955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618955 = validateParameter(valid_618955, JString, required = false,
                                 default = nil)
  if valid_618955 != nil:
    section.add "X-Amz-Content-Sha256", valid_618955
  var valid_618956 = header.getOrDefault("X-Amz-Algorithm")
  valid_618956 = validateParameter(valid_618956, JString, required = false,
                                 default = nil)
  if valid_618956 != nil:
    section.add "X-Amz-Algorithm", valid_618956
  var valid_618957 = header.getOrDefault("X-Amz-Signature")
  valid_618957 = validateParameter(valid_618957, JString, required = false,
                                 default = nil)
  if valid_618957 != nil:
    section.add "X-Amz-Signature", valid_618957
  var valid_618958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618958 = validateParameter(valid_618958, JString, required = false,
                                 default = nil)
  if valid_618958 != nil:
    section.add "X-Amz-SignedHeaders", valid_618958
  var valid_618959 = header.getOrDefault("X-Amz-Credential")
  valid_618959 = validateParameter(valid_618959, JString, required = false,
                                 default = nil)
  if valid_618959 != nil:
    section.add "X-Amz-Credential", valid_618959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618961: Call_TagResource_618949; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_618961.validator(path, query, header, formData, body, _)
  let scheme = call_618961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618961.url(scheme.get, call_618961.host, call_618961.base,
                         call_618961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618961, url, valid, _)

proc call*(call_618962: Call_TagResource_618949; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_618963 = newJObject()
  var body_618964 = newJObject()
  add(path_618963, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_618964 = body
  result = call_618962.call(path_618963, nil, nil, nil, body_618964)

var tagResource* = Call_TagResource_618949(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_618950,
                                        base: "/", url: url_TagResource_618951,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_618935 = ref object of OpenApiRestCall_616850
proc url_ListTagsForResource_618937(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_618936(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618938 = path.getOrDefault("resource-arn")
  valid_618938 = validateParameter(valid_618938, JString, required = true,
                                 default = nil)
  if valid_618938 != nil:
    section.add "resource-arn", valid_618938
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
  var valid_618939 = header.getOrDefault("X-Amz-Date")
  valid_618939 = validateParameter(valid_618939, JString, required = false,
                                 default = nil)
  if valid_618939 != nil:
    section.add "X-Amz-Date", valid_618939
  var valid_618940 = header.getOrDefault("X-Amz-Security-Token")
  valid_618940 = validateParameter(valid_618940, JString, required = false,
                                 default = nil)
  if valid_618940 != nil:
    section.add "X-Amz-Security-Token", valid_618940
  var valid_618941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618941 = validateParameter(valid_618941, JString, required = false,
                                 default = nil)
  if valid_618941 != nil:
    section.add "X-Amz-Content-Sha256", valid_618941
  var valid_618942 = header.getOrDefault("X-Amz-Algorithm")
  valid_618942 = validateParameter(valid_618942, JString, required = false,
                                 default = nil)
  if valid_618942 != nil:
    section.add "X-Amz-Algorithm", valid_618942
  var valid_618943 = header.getOrDefault("X-Amz-Signature")
  valid_618943 = validateParameter(valid_618943, JString, required = false,
                                 default = nil)
  if valid_618943 != nil:
    section.add "X-Amz-Signature", valid_618943
  var valid_618944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618944 = validateParameter(valid_618944, JString, required = false,
                                 default = nil)
  if valid_618944 != nil:
    section.add "X-Amz-SignedHeaders", valid_618944
  var valid_618945 = header.getOrDefault("X-Amz-Credential")
  valid_618945 = validateParameter(valid_618945, JString, required = false,
                                 default = nil)
  if valid_618945 != nil:
    section.add "X-Amz-Credential", valid_618945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618946: Call_ListTagsForResource_618935; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_618946.validator(path, query, header, formData, body, _)
  let scheme = call_618946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618946.url(scheme.get, call_618946.host, call_618946.base,
                         call_618946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618946, url, valid, _)

proc call*(call_618947: Call_ListTagsForResource_618935; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_618948 = newJObject()
  add(path_618948, "resource-arn", newJString(resourceArn))
  result = call_618947.call(path_618948, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_618935(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_618936, base: "/",
    url: url_ListTagsForResource_618937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_618965 = ref object of OpenApiRestCall_616850
proc url_ListTemplateVersions_618967(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_618966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618968 = path.getOrDefault("template-type")
  valid_618968 = validateParameter(valid_618968, JString, required = true,
                                 default = nil)
  if valid_618968 != nil:
    section.add "template-type", valid_618968
  var valid_618969 = path.getOrDefault("template-name")
  valid_618969 = validateParameter(valid_618969, JString, required = true,
                                 default = nil)
  if valid_618969 != nil:
    section.add "template-name", valid_618969
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618970 = query.getOrDefault("next-token")
  valid_618970 = validateParameter(valid_618970, JString, required = false,
                                 default = nil)
  if valid_618970 != nil:
    section.add "next-token", valid_618970
  var valid_618971 = query.getOrDefault("page-size")
  valid_618971 = validateParameter(valid_618971, JString, required = false,
                                 default = nil)
  if valid_618971 != nil:
    section.add "page-size", valid_618971
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
  var valid_618972 = header.getOrDefault("X-Amz-Date")
  valid_618972 = validateParameter(valid_618972, JString, required = false,
                                 default = nil)
  if valid_618972 != nil:
    section.add "X-Amz-Date", valid_618972
  var valid_618973 = header.getOrDefault("X-Amz-Security-Token")
  valid_618973 = validateParameter(valid_618973, JString, required = false,
                                 default = nil)
  if valid_618973 != nil:
    section.add "X-Amz-Security-Token", valid_618973
  var valid_618974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618974 = validateParameter(valid_618974, JString, required = false,
                                 default = nil)
  if valid_618974 != nil:
    section.add "X-Amz-Content-Sha256", valid_618974
  var valid_618975 = header.getOrDefault("X-Amz-Algorithm")
  valid_618975 = validateParameter(valid_618975, JString, required = false,
                                 default = nil)
  if valid_618975 != nil:
    section.add "X-Amz-Algorithm", valid_618975
  var valid_618976 = header.getOrDefault("X-Amz-Signature")
  valid_618976 = validateParameter(valid_618976, JString, required = false,
                                 default = nil)
  if valid_618976 != nil:
    section.add "X-Amz-Signature", valid_618976
  var valid_618977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618977 = validateParameter(valid_618977, JString, required = false,
                                 default = nil)
  if valid_618977 != nil:
    section.add "X-Amz-SignedHeaders", valid_618977
  var valid_618978 = header.getOrDefault("X-Amz-Credential")
  valid_618978 = validateParameter(valid_618978, JString, required = false,
                                 default = nil)
  if valid_618978 != nil:
    section.add "X-Amz-Credential", valid_618978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618979: Call_ListTemplateVersions_618965; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_618979.validator(path, query, header, formData, body, _)
  let scheme = call_618979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618979.url(scheme.get, call_618979.host, call_618979.base,
                         call_618979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618979, url, valid, _)

proc call*(call_618980: Call_ListTemplateVersions_618965; templateType: string;
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
  var path_618981 = newJObject()
  var query_618982 = newJObject()
  add(path_618981, "template-type", newJString(templateType))
  add(path_618981, "template-name", newJString(templateName))
  add(query_618982, "next-token", newJString(nextToken))
  add(query_618982, "page-size", newJString(pageSize))
  result = call_618980.call(path_618981, query_618982, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_618965(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_618966, base: "/",
    url: url_ListTemplateVersions_618967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_618983 = ref object of OpenApiRestCall_616850
proc url_ListTemplates_618985(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTemplates_618984(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   template-type: JString
  ##                : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   prefix: JString
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_618986 = query.getOrDefault("next-token")
  valid_618986 = validateParameter(valid_618986, JString, required = false,
                                 default = nil)
  if valid_618986 != nil:
    section.add "next-token", valid_618986
  var valid_618987 = query.getOrDefault("template-type")
  valid_618987 = validateParameter(valid_618987, JString, required = false,
                                 default = nil)
  if valid_618987 != nil:
    section.add "template-type", valid_618987
  var valid_618988 = query.getOrDefault("prefix")
  valid_618988 = validateParameter(valid_618988, JString, required = false,
                                 default = nil)
  if valid_618988 != nil:
    section.add "prefix", valid_618988
  var valid_618989 = query.getOrDefault("page-size")
  valid_618989 = validateParameter(valid_618989, JString, required = false,
                                 default = nil)
  if valid_618989 != nil:
    section.add "page-size", valid_618989
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
  var valid_618990 = header.getOrDefault("X-Amz-Date")
  valid_618990 = validateParameter(valid_618990, JString, required = false,
                                 default = nil)
  if valid_618990 != nil:
    section.add "X-Amz-Date", valid_618990
  var valid_618991 = header.getOrDefault("X-Amz-Security-Token")
  valid_618991 = validateParameter(valid_618991, JString, required = false,
                                 default = nil)
  if valid_618991 != nil:
    section.add "X-Amz-Security-Token", valid_618991
  var valid_618992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618992 = validateParameter(valid_618992, JString, required = false,
                                 default = nil)
  if valid_618992 != nil:
    section.add "X-Amz-Content-Sha256", valid_618992
  var valid_618993 = header.getOrDefault("X-Amz-Algorithm")
  valid_618993 = validateParameter(valid_618993, JString, required = false,
                                 default = nil)
  if valid_618993 != nil:
    section.add "X-Amz-Algorithm", valid_618993
  var valid_618994 = header.getOrDefault("X-Amz-Signature")
  valid_618994 = validateParameter(valid_618994, JString, required = false,
                                 default = nil)
  if valid_618994 != nil:
    section.add "X-Amz-Signature", valid_618994
  var valid_618995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618995 = validateParameter(valid_618995, JString, required = false,
                                 default = nil)
  if valid_618995 != nil:
    section.add "X-Amz-SignedHeaders", valid_618995
  var valid_618996 = header.getOrDefault("X-Amz-Credential")
  valid_618996 = validateParameter(valid_618996, JString, required = false,
                                 default = nil)
  if valid_618996 != nil:
    section.add "X-Amz-Credential", valid_618996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618997: Call_ListTemplates_618983; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_618997.validator(path, query, header, formData, body, _)
  let scheme = call_618997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618997.url(scheme.get, call_618997.host, call_618997.base,
                         call_618997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618997, url, valid, _)

proc call*(call_618998: Call_ListTemplates_618983; nextToken: string = "";
          templateType: string = ""; prefix: string = ""; pageSize: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_618999 = newJObject()
  add(query_618999, "next-token", newJString(nextToken))
  add(query_618999, "template-type", newJString(templateType))
  add(query_618999, "prefix", newJString(prefix))
  add(query_618999, "page-size", newJString(pageSize))
  result = call_618998.call(nil, query_618999, nil, nil, nil)

var listTemplates* = Call_ListTemplates_618983(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_618984, base: "/",
    url: url_ListTemplates_618985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_619000 = ref object of OpenApiRestCall_616850
proc url_PhoneNumberValidate_619002(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PhoneNumberValidate_619001(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619003 = header.getOrDefault("X-Amz-Date")
  valid_619003 = validateParameter(valid_619003, JString, required = false,
                                 default = nil)
  if valid_619003 != nil:
    section.add "X-Amz-Date", valid_619003
  var valid_619004 = header.getOrDefault("X-Amz-Security-Token")
  valid_619004 = validateParameter(valid_619004, JString, required = false,
                                 default = nil)
  if valid_619004 != nil:
    section.add "X-Amz-Security-Token", valid_619004
  var valid_619005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619005 = validateParameter(valid_619005, JString, required = false,
                                 default = nil)
  if valid_619005 != nil:
    section.add "X-Amz-Content-Sha256", valid_619005
  var valid_619006 = header.getOrDefault("X-Amz-Algorithm")
  valid_619006 = validateParameter(valid_619006, JString, required = false,
                                 default = nil)
  if valid_619006 != nil:
    section.add "X-Amz-Algorithm", valid_619006
  var valid_619007 = header.getOrDefault("X-Amz-Signature")
  valid_619007 = validateParameter(valid_619007, JString, required = false,
                                 default = nil)
  if valid_619007 != nil:
    section.add "X-Amz-Signature", valid_619007
  var valid_619008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619008 = validateParameter(valid_619008, JString, required = false,
                                 default = nil)
  if valid_619008 != nil:
    section.add "X-Amz-SignedHeaders", valid_619008
  var valid_619009 = header.getOrDefault("X-Amz-Credential")
  valid_619009 = validateParameter(valid_619009, JString, required = false,
                                 default = nil)
  if valid_619009 != nil:
    section.add "X-Amz-Credential", valid_619009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619011: Call_PhoneNumberValidate_619000; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_619011.validator(path, query, header, formData, body, _)
  let scheme = call_619011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619011.url(scheme.get, call_619011.host, call_619011.base,
                         call_619011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619011, url, valid, _)

proc call*(call_619012: Call_PhoneNumberValidate_619000; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_619013 = newJObject()
  if body != nil:
    body_619013 = body
  result = call_619012.call(nil, nil, nil, nil, body_619013)

var phoneNumberValidate* = Call_PhoneNumberValidate_619000(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_619001, base: "/",
    url: url_PhoneNumberValidate_619002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_619014 = ref object of OpenApiRestCall_616850
proc url_PutEvents_619016(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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

proc validate_PutEvents_619015(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619017 = path.getOrDefault("application-id")
  valid_619017 = validateParameter(valid_619017, JString, required = true,
                                 default = nil)
  if valid_619017 != nil:
    section.add "application-id", valid_619017
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
  var valid_619018 = header.getOrDefault("X-Amz-Date")
  valid_619018 = validateParameter(valid_619018, JString, required = false,
                                 default = nil)
  if valid_619018 != nil:
    section.add "X-Amz-Date", valid_619018
  var valid_619019 = header.getOrDefault("X-Amz-Security-Token")
  valid_619019 = validateParameter(valid_619019, JString, required = false,
                                 default = nil)
  if valid_619019 != nil:
    section.add "X-Amz-Security-Token", valid_619019
  var valid_619020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619020 = validateParameter(valid_619020, JString, required = false,
                                 default = nil)
  if valid_619020 != nil:
    section.add "X-Amz-Content-Sha256", valid_619020
  var valid_619021 = header.getOrDefault("X-Amz-Algorithm")
  valid_619021 = validateParameter(valid_619021, JString, required = false,
                                 default = nil)
  if valid_619021 != nil:
    section.add "X-Amz-Algorithm", valid_619021
  var valid_619022 = header.getOrDefault("X-Amz-Signature")
  valid_619022 = validateParameter(valid_619022, JString, required = false,
                                 default = nil)
  if valid_619022 != nil:
    section.add "X-Amz-Signature", valid_619022
  var valid_619023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619023 = validateParameter(valid_619023, JString, required = false,
                                 default = nil)
  if valid_619023 != nil:
    section.add "X-Amz-SignedHeaders", valid_619023
  var valid_619024 = header.getOrDefault("X-Amz-Credential")
  valid_619024 = validateParameter(valid_619024, JString, required = false,
                                 default = nil)
  if valid_619024 != nil:
    section.add "X-Amz-Credential", valid_619024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619026: Call_PutEvents_619014; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_619026.validator(path, query, header, formData, body, _)
  let scheme = call_619026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619026.url(scheme.get, call_619026.host, call_619026.base,
                         call_619026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619026, url, valid, _)

proc call*(call_619027: Call_PutEvents_619014; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_619028 = newJObject()
  var body_619029 = newJObject()
  add(path_619028, "application-id", newJString(applicationId))
  if body != nil:
    body_619029 = body
  result = call_619027.call(path_619028, nil, nil, nil, body_619029)

var putEvents* = Call_PutEvents_619014(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_619015,
                                    base: "/", url: url_PutEvents_619016,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_619030 = ref object of OpenApiRestCall_616850
proc url_RemoveAttributes_619032(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_619031(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   attribute-type: JString (required)
  ##                 :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_619033 = path.getOrDefault("application-id")
  valid_619033 = validateParameter(valid_619033, JString, required = true,
                                 default = nil)
  if valid_619033 != nil:
    section.add "application-id", valid_619033
  var valid_619034 = path.getOrDefault("attribute-type")
  valid_619034 = validateParameter(valid_619034, JString, required = true,
                                 default = nil)
  if valid_619034 != nil:
    section.add "attribute-type", valid_619034
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
  var valid_619035 = header.getOrDefault("X-Amz-Date")
  valid_619035 = validateParameter(valid_619035, JString, required = false,
                                 default = nil)
  if valid_619035 != nil:
    section.add "X-Amz-Date", valid_619035
  var valid_619036 = header.getOrDefault("X-Amz-Security-Token")
  valid_619036 = validateParameter(valid_619036, JString, required = false,
                                 default = nil)
  if valid_619036 != nil:
    section.add "X-Amz-Security-Token", valid_619036
  var valid_619037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619037 = validateParameter(valid_619037, JString, required = false,
                                 default = nil)
  if valid_619037 != nil:
    section.add "X-Amz-Content-Sha256", valid_619037
  var valid_619038 = header.getOrDefault("X-Amz-Algorithm")
  valid_619038 = validateParameter(valid_619038, JString, required = false,
                                 default = nil)
  if valid_619038 != nil:
    section.add "X-Amz-Algorithm", valid_619038
  var valid_619039 = header.getOrDefault("X-Amz-Signature")
  valid_619039 = validateParameter(valid_619039, JString, required = false,
                                 default = nil)
  if valid_619039 != nil:
    section.add "X-Amz-Signature", valid_619039
  var valid_619040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619040 = validateParameter(valid_619040, JString, required = false,
                                 default = nil)
  if valid_619040 != nil:
    section.add "X-Amz-SignedHeaders", valid_619040
  var valid_619041 = header.getOrDefault("X-Amz-Credential")
  valid_619041 = validateParameter(valid_619041, JString, required = false,
                                 default = nil)
  if valid_619041 != nil:
    section.add "X-Amz-Credential", valid_619041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619043: Call_RemoveAttributes_619030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_619043.validator(path, query, header, formData, body, _)
  let scheme = call_619043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619043.url(scheme.get, call_619043.host, call_619043.base,
                         call_619043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619043, url, valid, _)

proc call*(call_619044: Call_RemoveAttributes_619030; applicationId: string;
          attributeType: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   body: JObject (required)
  var path_619045 = newJObject()
  var body_619046 = newJObject()
  add(path_619045, "application-id", newJString(applicationId))
  add(path_619045, "attribute-type", newJString(attributeType))
  if body != nil:
    body_619046 = body
  result = call_619044.call(path_619045, nil, nil, nil, body_619046)

var removeAttributes* = Call_RemoveAttributes_619030(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_619031, base: "/",
    url: url_RemoveAttributes_619032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_619047 = ref object of OpenApiRestCall_616850
proc url_SendMessages_619049(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_619048(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619050 = path.getOrDefault("application-id")
  valid_619050 = validateParameter(valid_619050, JString, required = true,
                                 default = nil)
  if valid_619050 != nil:
    section.add "application-id", valid_619050
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
  var valid_619051 = header.getOrDefault("X-Amz-Date")
  valid_619051 = validateParameter(valid_619051, JString, required = false,
                                 default = nil)
  if valid_619051 != nil:
    section.add "X-Amz-Date", valid_619051
  var valid_619052 = header.getOrDefault("X-Amz-Security-Token")
  valid_619052 = validateParameter(valid_619052, JString, required = false,
                                 default = nil)
  if valid_619052 != nil:
    section.add "X-Amz-Security-Token", valid_619052
  var valid_619053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619053 = validateParameter(valid_619053, JString, required = false,
                                 default = nil)
  if valid_619053 != nil:
    section.add "X-Amz-Content-Sha256", valid_619053
  var valid_619054 = header.getOrDefault("X-Amz-Algorithm")
  valid_619054 = validateParameter(valid_619054, JString, required = false,
                                 default = nil)
  if valid_619054 != nil:
    section.add "X-Amz-Algorithm", valid_619054
  var valid_619055 = header.getOrDefault("X-Amz-Signature")
  valid_619055 = validateParameter(valid_619055, JString, required = false,
                                 default = nil)
  if valid_619055 != nil:
    section.add "X-Amz-Signature", valid_619055
  var valid_619056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619056 = validateParameter(valid_619056, JString, required = false,
                                 default = nil)
  if valid_619056 != nil:
    section.add "X-Amz-SignedHeaders", valid_619056
  var valid_619057 = header.getOrDefault("X-Amz-Credential")
  valid_619057 = validateParameter(valid_619057, JString, required = false,
                                 default = nil)
  if valid_619057 != nil:
    section.add "X-Amz-Credential", valid_619057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619059: Call_SendMessages_619047; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_619059.validator(path, query, header, formData, body, _)
  let scheme = call_619059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619059.url(scheme.get, call_619059.host, call_619059.base,
                         call_619059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619059, url, valid, _)

proc call*(call_619060: Call_SendMessages_619047; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_619061 = newJObject()
  var body_619062 = newJObject()
  add(path_619061, "application-id", newJString(applicationId))
  if body != nil:
    body_619062 = body
  result = call_619060.call(path_619061, nil, nil, nil, body_619062)

var sendMessages* = Call_SendMessages_619047(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_619048,
    base: "/", url: url_SendMessages_619049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_619063 = ref object of OpenApiRestCall_616850
proc url_SendUsersMessages_619065(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_619064(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619066 = path.getOrDefault("application-id")
  valid_619066 = validateParameter(valid_619066, JString, required = true,
                                 default = nil)
  if valid_619066 != nil:
    section.add "application-id", valid_619066
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
  var valid_619067 = header.getOrDefault("X-Amz-Date")
  valid_619067 = validateParameter(valid_619067, JString, required = false,
                                 default = nil)
  if valid_619067 != nil:
    section.add "X-Amz-Date", valid_619067
  var valid_619068 = header.getOrDefault("X-Amz-Security-Token")
  valid_619068 = validateParameter(valid_619068, JString, required = false,
                                 default = nil)
  if valid_619068 != nil:
    section.add "X-Amz-Security-Token", valid_619068
  var valid_619069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619069 = validateParameter(valid_619069, JString, required = false,
                                 default = nil)
  if valid_619069 != nil:
    section.add "X-Amz-Content-Sha256", valid_619069
  var valid_619070 = header.getOrDefault("X-Amz-Algorithm")
  valid_619070 = validateParameter(valid_619070, JString, required = false,
                                 default = nil)
  if valid_619070 != nil:
    section.add "X-Amz-Algorithm", valid_619070
  var valid_619071 = header.getOrDefault("X-Amz-Signature")
  valid_619071 = validateParameter(valid_619071, JString, required = false,
                                 default = nil)
  if valid_619071 != nil:
    section.add "X-Amz-Signature", valid_619071
  var valid_619072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619072 = validateParameter(valid_619072, JString, required = false,
                                 default = nil)
  if valid_619072 != nil:
    section.add "X-Amz-SignedHeaders", valid_619072
  var valid_619073 = header.getOrDefault("X-Amz-Credential")
  valid_619073 = validateParameter(valid_619073, JString, required = false,
                                 default = nil)
  if valid_619073 != nil:
    section.add "X-Amz-Credential", valid_619073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619075: Call_SendUsersMessages_619063; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_619075.validator(path, query, header, formData, body, _)
  let scheme = call_619075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619075.url(scheme.get, call_619075.host, call_619075.base,
                         call_619075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619075, url, valid, _)

proc call*(call_619076: Call_SendUsersMessages_619063; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_619077 = newJObject()
  var body_619078 = newJObject()
  add(path_619077, "application-id", newJString(applicationId))
  if body != nil:
    body_619078 = body
  result = call_619076.call(path_619077, nil, nil, nil, body_619078)

var sendUsersMessages* = Call_SendUsersMessages_619063(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_619064, base: "/",
    url: url_SendUsersMessages_619065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_619079 = ref object of OpenApiRestCall_616850
proc url_UntagResource_619081(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_619080(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619082 = path.getOrDefault("resource-arn")
  valid_619082 = validateParameter(valid_619082, JString, required = true,
                                 default = nil)
  if valid_619082 != nil:
    section.add "resource-arn", valid_619082
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_619083 = query.getOrDefault("tagKeys")
  valid_619083 = validateParameter(valid_619083, JArray, required = true, default = nil)
  if valid_619083 != nil:
    section.add "tagKeys", valid_619083
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
  var valid_619084 = header.getOrDefault("X-Amz-Date")
  valid_619084 = validateParameter(valid_619084, JString, required = false,
                                 default = nil)
  if valid_619084 != nil:
    section.add "X-Amz-Date", valid_619084
  var valid_619085 = header.getOrDefault("X-Amz-Security-Token")
  valid_619085 = validateParameter(valid_619085, JString, required = false,
                                 default = nil)
  if valid_619085 != nil:
    section.add "X-Amz-Security-Token", valid_619085
  var valid_619086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619086 = validateParameter(valid_619086, JString, required = false,
                                 default = nil)
  if valid_619086 != nil:
    section.add "X-Amz-Content-Sha256", valid_619086
  var valid_619087 = header.getOrDefault("X-Amz-Algorithm")
  valid_619087 = validateParameter(valid_619087, JString, required = false,
                                 default = nil)
  if valid_619087 != nil:
    section.add "X-Amz-Algorithm", valid_619087
  var valid_619088 = header.getOrDefault("X-Amz-Signature")
  valid_619088 = validateParameter(valid_619088, JString, required = false,
                                 default = nil)
  if valid_619088 != nil:
    section.add "X-Amz-Signature", valid_619088
  var valid_619089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619089 = validateParameter(valid_619089, JString, required = false,
                                 default = nil)
  if valid_619089 != nil:
    section.add "X-Amz-SignedHeaders", valid_619089
  var valid_619090 = header.getOrDefault("X-Amz-Credential")
  valid_619090 = validateParameter(valid_619090, JString, required = false,
                                 default = nil)
  if valid_619090 != nil:
    section.add "X-Amz-Credential", valid_619090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619091: Call_UntagResource_619079; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_619091.validator(path, query, header, formData, body, _)
  let scheme = call_619091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619091.url(scheme.get, call_619091.host, call_619091.base,
                         call_619091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619091, url, valid, _)

proc call*(call_619092: Call_UntagResource_619079; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_619093 = newJObject()
  var query_619094 = newJObject()
  if tagKeys != nil:
    query_619094.add "tagKeys", tagKeys
  add(path_619093, "resource-arn", newJString(resourceArn))
  result = call_619092.call(path_619093, query_619094, nil, nil, nil)

var untagResource* = Call_UntagResource_619079(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_619080,
    base: "/", url: url_UntagResource_619081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_619095 = ref object of OpenApiRestCall_616850
proc url_UpdateEndpointsBatch_619097(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_619096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619098 = path.getOrDefault("application-id")
  valid_619098 = validateParameter(valid_619098, JString, required = true,
                                 default = nil)
  if valid_619098 != nil:
    section.add "application-id", valid_619098
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
  var valid_619099 = header.getOrDefault("X-Amz-Date")
  valid_619099 = validateParameter(valid_619099, JString, required = false,
                                 default = nil)
  if valid_619099 != nil:
    section.add "X-Amz-Date", valid_619099
  var valid_619100 = header.getOrDefault("X-Amz-Security-Token")
  valid_619100 = validateParameter(valid_619100, JString, required = false,
                                 default = nil)
  if valid_619100 != nil:
    section.add "X-Amz-Security-Token", valid_619100
  var valid_619101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619101 = validateParameter(valid_619101, JString, required = false,
                                 default = nil)
  if valid_619101 != nil:
    section.add "X-Amz-Content-Sha256", valid_619101
  var valid_619102 = header.getOrDefault("X-Amz-Algorithm")
  valid_619102 = validateParameter(valid_619102, JString, required = false,
                                 default = nil)
  if valid_619102 != nil:
    section.add "X-Amz-Algorithm", valid_619102
  var valid_619103 = header.getOrDefault("X-Amz-Signature")
  valid_619103 = validateParameter(valid_619103, JString, required = false,
                                 default = nil)
  if valid_619103 != nil:
    section.add "X-Amz-Signature", valid_619103
  var valid_619104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619104 = validateParameter(valid_619104, JString, required = false,
                                 default = nil)
  if valid_619104 != nil:
    section.add "X-Amz-SignedHeaders", valid_619104
  var valid_619105 = header.getOrDefault("X-Amz-Credential")
  valid_619105 = validateParameter(valid_619105, JString, required = false,
                                 default = nil)
  if valid_619105 != nil:
    section.add "X-Amz-Credential", valid_619105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619107: Call_UpdateEndpointsBatch_619095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_619107.validator(path, query, header, formData, body, _)
  let scheme = call_619107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619107.url(scheme.get, call_619107.host, call_619107.base,
                         call_619107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619107, url, valid, _)

proc call*(call_619108: Call_UpdateEndpointsBatch_619095; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_619109 = newJObject()
  var body_619110 = newJObject()
  add(path_619109, "application-id", newJString(applicationId))
  if body != nil:
    body_619110 = body
  result = call_619108.call(path_619109, nil, nil, nil, body_619110)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_619095(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_619096, base: "/",
    url: url_UpdateEndpointsBatch_619097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_619111 = ref object of OpenApiRestCall_616850
proc url_UpdateJourneyState_619113(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_619112(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619114 = path.getOrDefault("journey-id")
  valid_619114 = validateParameter(valid_619114, JString, required = true,
                                 default = nil)
  if valid_619114 != nil:
    section.add "journey-id", valid_619114
  var valid_619115 = path.getOrDefault("application-id")
  valid_619115 = validateParameter(valid_619115, JString, required = true,
                                 default = nil)
  if valid_619115 != nil:
    section.add "application-id", valid_619115
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
  var valid_619116 = header.getOrDefault("X-Amz-Date")
  valid_619116 = validateParameter(valid_619116, JString, required = false,
                                 default = nil)
  if valid_619116 != nil:
    section.add "X-Amz-Date", valid_619116
  var valid_619117 = header.getOrDefault("X-Amz-Security-Token")
  valid_619117 = validateParameter(valid_619117, JString, required = false,
                                 default = nil)
  if valid_619117 != nil:
    section.add "X-Amz-Security-Token", valid_619117
  var valid_619118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619118 = validateParameter(valid_619118, JString, required = false,
                                 default = nil)
  if valid_619118 != nil:
    section.add "X-Amz-Content-Sha256", valid_619118
  var valid_619119 = header.getOrDefault("X-Amz-Algorithm")
  valid_619119 = validateParameter(valid_619119, JString, required = false,
                                 default = nil)
  if valid_619119 != nil:
    section.add "X-Amz-Algorithm", valid_619119
  var valid_619120 = header.getOrDefault("X-Amz-Signature")
  valid_619120 = validateParameter(valid_619120, JString, required = false,
                                 default = nil)
  if valid_619120 != nil:
    section.add "X-Amz-Signature", valid_619120
  var valid_619121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619121 = validateParameter(valid_619121, JString, required = false,
                                 default = nil)
  if valid_619121 != nil:
    section.add "X-Amz-SignedHeaders", valid_619121
  var valid_619122 = header.getOrDefault("X-Amz-Credential")
  valid_619122 = validateParameter(valid_619122, JString, required = false,
                                 default = nil)
  if valid_619122 != nil:
    section.add "X-Amz-Credential", valid_619122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619124: Call_UpdateJourneyState_619111; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_619124.validator(path, query, header, formData, body, _)
  let scheme = call_619124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619124.url(scheme.get, call_619124.host, call_619124.base,
                         call_619124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619124, url, valid, _)

proc call*(call_619125: Call_UpdateJourneyState_619111; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_619126 = newJObject()
  var body_619127 = newJObject()
  add(path_619126, "journey-id", newJString(journeyId))
  add(path_619126, "application-id", newJString(applicationId))
  if body != nil:
    body_619127 = body
  result = call_619125.call(path_619126, nil, nil, nil, body_619127)

var updateJourneyState* = Call_UpdateJourneyState_619111(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_619112, base: "/",
    url: url_UpdateJourneyState_619113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_619128 = ref object of OpenApiRestCall_616850
proc url_UpdateTemplateActiveVersion_619130(protocol: Scheme; host: string;
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

proc validate_UpdateTemplateActiveVersion_619129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619131 = path.getOrDefault("template-type")
  valid_619131 = validateParameter(valid_619131, JString, required = true,
                                 default = nil)
  if valid_619131 != nil:
    section.add "template-type", valid_619131
  var valid_619132 = path.getOrDefault("template-name")
  valid_619132 = validateParameter(valid_619132, JString, required = true,
                                 default = nil)
  if valid_619132 != nil:
    section.add "template-name", valid_619132
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
  var valid_619133 = header.getOrDefault("X-Amz-Date")
  valid_619133 = validateParameter(valid_619133, JString, required = false,
                                 default = nil)
  if valid_619133 != nil:
    section.add "X-Amz-Date", valid_619133
  var valid_619134 = header.getOrDefault("X-Amz-Security-Token")
  valid_619134 = validateParameter(valid_619134, JString, required = false,
                                 default = nil)
  if valid_619134 != nil:
    section.add "X-Amz-Security-Token", valid_619134
  var valid_619135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619135 = validateParameter(valid_619135, JString, required = false,
                                 default = nil)
  if valid_619135 != nil:
    section.add "X-Amz-Content-Sha256", valid_619135
  var valid_619136 = header.getOrDefault("X-Amz-Algorithm")
  valid_619136 = validateParameter(valid_619136, JString, required = false,
                                 default = nil)
  if valid_619136 != nil:
    section.add "X-Amz-Algorithm", valid_619136
  var valid_619137 = header.getOrDefault("X-Amz-Signature")
  valid_619137 = validateParameter(valid_619137, JString, required = false,
                                 default = nil)
  if valid_619137 != nil:
    section.add "X-Amz-Signature", valid_619137
  var valid_619138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619138 = validateParameter(valid_619138, JString, required = false,
                                 default = nil)
  if valid_619138 != nil:
    section.add "X-Amz-SignedHeaders", valid_619138
  var valid_619139 = header.getOrDefault("X-Amz-Credential")
  valid_619139 = validateParameter(valid_619139, JString, required = false,
                                 default = nil)
  if valid_619139 != nil:
    section.add "X-Amz-Credential", valid_619139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_619141: Call_UpdateTemplateActiveVersion_619128;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_619141.validator(path, query, header, formData, body, _)
  let scheme = call_619141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619141.url(scheme.get, call_619141.host, call_619141.base,
                         call_619141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619141, url, valid, _)

proc call*(call_619142: Call_UpdateTemplateActiveVersion_619128;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_619143 = newJObject()
  var body_619144 = newJObject()
  add(path_619143, "template-type", newJString(templateType))
  add(path_619143, "template-name", newJString(templateName))
  if body != nil:
    body_619144 = body
  result = call_619142.call(path_619143, nil, nil, nil, body_619144)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_619128(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_619129, base: "/",
    url: url_UpdateTemplateActiveVersion_619130,
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
