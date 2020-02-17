
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_611237 = ref object of OpenApiRestCall_610642
proc url_CreateApp_611239(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_611238(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  <p>Creates an application.</p>
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
  var valid_611240 = header.getOrDefault("X-Amz-Signature")
  valid_611240 = validateParameter(valid_611240, JString, required = false,
                                 default = nil)
  if valid_611240 != nil:
    section.add "X-Amz-Signature", valid_611240
  var valid_611241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611241 = validateParameter(valid_611241, JString, required = false,
                                 default = nil)
  if valid_611241 != nil:
    section.add "X-Amz-Content-Sha256", valid_611241
  var valid_611242 = header.getOrDefault("X-Amz-Date")
  valid_611242 = validateParameter(valid_611242, JString, required = false,
                                 default = nil)
  if valid_611242 != nil:
    section.add "X-Amz-Date", valid_611242
  var valid_611243 = header.getOrDefault("X-Amz-Credential")
  valid_611243 = validateParameter(valid_611243, JString, required = false,
                                 default = nil)
  if valid_611243 != nil:
    section.add "X-Amz-Credential", valid_611243
  var valid_611244 = header.getOrDefault("X-Amz-Security-Token")
  valid_611244 = validateParameter(valid_611244, JString, required = false,
                                 default = nil)
  if valid_611244 != nil:
    section.add "X-Amz-Security-Token", valid_611244
  var valid_611245 = header.getOrDefault("X-Amz-Algorithm")
  valid_611245 = validateParameter(valid_611245, JString, required = false,
                                 default = nil)
  if valid_611245 != nil:
    section.add "X-Amz-Algorithm", valid_611245
  var valid_611246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611246 = validateParameter(valid_611246, JString, required = false,
                                 default = nil)
  if valid_611246 != nil:
    section.add "X-Amz-SignedHeaders", valid_611246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611248: Call_CreateApp_611237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_611248.validator(path, query, header, formData, body)
  let scheme = call_611248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611248.url(scheme.get, call_611248.host, call_611248.base,
                         call_611248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611248, url, valid)

proc call*(call_611249: Call_CreateApp_611237; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_611250 = newJObject()
  if body != nil:
    body_611250 = body
  result = call_611249.call(nil, nil, nil, nil, body_611250)

var createApp* = Call_CreateApp_611237(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_611238,
                                    base: "/", url: url_CreateApp_611239,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_610980 = ref object of OpenApiRestCall_610642
proc url_GetApps_610982(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApps_610981(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611094 = query.getOrDefault("page-size")
  valid_611094 = validateParameter(valid_611094, JString, required = false,
                                 default = nil)
  if valid_611094 != nil:
    section.add "page-size", valid_611094
  var valid_611095 = query.getOrDefault("token")
  valid_611095 = validateParameter(valid_611095, JString, required = false,
                                 default = nil)
  if valid_611095 != nil:
    section.add "token", valid_611095
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
  var valid_611096 = header.getOrDefault("X-Amz-Signature")
  valid_611096 = validateParameter(valid_611096, JString, required = false,
                                 default = nil)
  if valid_611096 != nil:
    section.add "X-Amz-Signature", valid_611096
  var valid_611097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611097 = validateParameter(valid_611097, JString, required = false,
                                 default = nil)
  if valid_611097 != nil:
    section.add "X-Amz-Content-Sha256", valid_611097
  var valid_611098 = header.getOrDefault("X-Amz-Date")
  valid_611098 = validateParameter(valid_611098, JString, required = false,
                                 default = nil)
  if valid_611098 != nil:
    section.add "X-Amz-Date", valid_611098
  var valid_611099 = header.getOrDefault("X-Amz-Credential")
  valid_611099 = validateParameter(valid_611099, JString, required = false,
                                 default = nil)
  if valid_611099 != nil:
    section.add "X-Amz-Credential", valid_611099
  var valid_611100 = header.getOrDefault("X-Amz-Security-Token")
  valid_611100 = validateParameter(valid_611100, JString, required = false,
                                 default = nil)
  if valid_611100 != nil:
    section.add "X-Amz-Security-Token", valid_611100
  var valid_611101 = header.getOrDefault("X-Amz-Algorithm")
  valid_611101 = validateParameter(valid_611101, JString, required = false,
                                 default = nil)
  if valid_611101 != nil:
    section.add "X-Amz-Algorithm", valid_611101
  var valid_611102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "X-Amz-SignedHeaders", valid_611102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611125: Call_GetApps_610980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_611125.validator(path, query, header, formData, body)
  let scheme = call_611125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611125.url(scheme.get, call_611125.host, call_611125.base,
                         call_611125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611125, url, valid)

proc call*(call_611196: Call_GetApps_610980; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_611197 = newJObject()
  add(query_611197, "page-size", newJString(pageSize))
  add(query_611197, "token", newJString(token))
  result = call_611196.call(nil, query_611197, nil, nil, nil)

var getApps* = Call_GetApps_610980(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_610981, base: "/",
                                url: url_GetApps_610982,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_611282 = ref object of OpenApiRestCall_610642
proc url_CreateCampaign_611284(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_611283(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_611285 = path.getOrDefault("application-id")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "application-id", valid_611285
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
  var valid_611286 = header.getOrDefault("X-Amz-Signature")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Signature", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Content-Sha256", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Date")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Date", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Credential")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Credential", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Security-Token")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Security-Token", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Algorithm")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Algorithm", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-SignedHeaders", valid_611292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611294: Call_CreateCampaign_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_611294.validator(path, query, header, formData, body)
  let scheme = call_611294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611294.url(scheme.get, call_611294.host, call_611294.base,
                         call_611294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611294, url, valid)

proc call*(call_611295: Call_CreateCampaign_611282; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611296 = newJObject()
  var body_611297 = newJObject()
  add(path_611296, "application-id", newJString(applicationId))
  if body != nil:
    body_611297 = body
  result = call_611295.call(path_611296, nil, nil, nil, body_611297)

var createCampaign* = Call_CreateCampaign_611282(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_611283, base: "/", url: url_CreateCampaign_611284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_611251 = ref object of OpenApiRestCall_610642
proc url_GetCampaigns_611253(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_611252(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611268 = path.getOrDefault("application-id")
  valid_611268 = validateParameter(valid_611268, JString, required = true,
                                 default = nil)
  if valid_611268 != nil:
    section.add "application-id", valid_611268
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611269 = query.getOrDefault("page-size")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "page-size", valid_611269
  var valid_611270 = query.getOrDefault("token")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "token", valid_611270
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
  var valid_611271 = header.getOrDefault("X-Amz-Signature")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Signature", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Content-Sha256", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Date")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Date", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Credential")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Credential", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Security-Token")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Security-Token", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Algorithm")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Algorithm", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-SignedHeaders", valid_611277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611278: Call_GetCampaigns_611251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_611278.validator(path, query, header, formData, body)
  let scheme = call_611278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611278.url(scheme.get, call_611278.host, call_611278.base,
                         call_611278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611278, url, valid)

proc call*(call_611279: Call_GetCampaigns_611251; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_611280 = newJObject()
  var query_611281 = newJObject()
  add(path_611280, "application-id", newJString(applicationId))
  add(query_611281, "page-size", newJString(pageSize))
  add(query_611281, "token", newJString(token))
  result = call_611279.call(path_611280, query_611281, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_611251(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_611252, base: "/", url: url_GetCampaigns_611253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_611314 = ref object of OpenApiRestCall_610642
proc url_UpdateEmailTemplate_611316(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_611315(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611317 = path.getOrDefault("template-name")
  valid_611317 = validateParameter(valid_611317, JString, required = true,
                                 default = nil)
  if valid_611317 != nil:
    section.add "template-name", valid_611317
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_611318 = query.getOrDefault("version")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "version", valid_611318
  var valid_611319 = query.getOrDefault("create-new-version")
  valid_611319 = validateParameter(valid_611319, JBool, required = false, default = nil)
  if valid_611319 != nil:
    section.add "create-new-version", valid_611319
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
  var valid_611320 = header.getOrDefault("X-Amz-Signature")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Signature", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Content-Sha256", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Date")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Date", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Credential")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Credential", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Security-Token")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Security-Token", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Algorithm")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Algorithm", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-SignedHeaders", valid_611326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611328: Call_UpdateEmailTemplate_611314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_611328.validator(path, query, header, formData, body)
  let scheme = call_611328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611328.url(scheme.get, call_611328.host, call_611328.base,
                         call_611328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611328, url, valid)

proc call*(call_611329: Call_UpdateEmailTemplate_611314; templateName: string;
          body: JsonNode; version: string = ""; createNewVersion: bool = false): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   body: JObject (required)
  var path_611330 = newJObject()
  var query_611331 = newJObject()
  var body_611332 = newJObject()
  add(path_611330, "template-name", newJString(templateName))
  add(query_611331, "version", newJString(version))
  add(query_611331, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_611332 = body
  result = call_611329.call(path_611330, query_611331, nil, nil, body_611332)

var updateEmailTemplate* = Call_UpdateEmailTemplate_611314(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_611315, base: "/",
    url: url_UpdateEmailTemplate_611316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_611333 = ref object of OpenApiRestCall_610642
proc url_CreateEmailTemplate_611335(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_611334(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611336 = path.getOrDefault("template-name")
  valid_611336 = validateParameter(valid_611336, JString, required = true,
                                 default = nil)
  if valid_611336 != nil:
    section.add "template-name", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_CreateEmailTemplate_611333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_CreateEmailTemplate_611333; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_611347 = newJObject()
  var body_611348 = newJObject()
  add(path_611347, "template-name", newJString(templateName))
  if body != nil:
    body_611348 = body
  result = call_611346.call(path_611347, nil, nil, nil, body_611348)

var createEmailTemplate* = Call_CreateEmailTemplate_611333(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_611334, base: "/",
    url: url_CreateEmailTemplate_611335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_611298 = ref object of OpenApiRestCall_610642
proc url_GetEmailTemplate_611300(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_611299(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_611301 = path.getOrDefault("template-name")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = nil)
  if valid_611301 != nil:
    section.add "template-name", valid_611301
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611302 = query.getOrDefault("version")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "version", valid_611302
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
  var valid_611303 = header.getOrDefault("X-Amz-Signature")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Signature", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Content-Sha256", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Date")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Date", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Credential")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Credential", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Security-Token")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Security-Token", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Algorithm")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Algorithm", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-SignedHeaders", valid_611309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611310: Call_GetEmailTemplate_611298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_611310.validator(path, query, header, formData, body)
  let scheme = call_611310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611310.url(scheme.get, call_611310.host, call_611310.base,
                         call_611310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611310, url, valid)

proc call*(call_611311: Call_GetEmailTemplate_611298; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611312 = newJObject()
  var query_611313 = newJObject()
  add(path_611312, "template-name", newJString(templateName))
  add(query_611313, "version", newJString(version))
  result = call_611311.call(path_611312, query_611313, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_611298(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_611299, base: "/",
    url: url_GetEmailTemplate_611300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_611349 = ref object of OpenApiRestCall_610642
proc url_DeleteEmailTemplate_611351(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_611350(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611352 = path.getOrDefault("template-name")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "template-name", valid_611352
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611353 = query.getOrDefault("version")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "version", valid_611353
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
  var valid_611354 = header.getOrDefault("X-Amz-Signature")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Signature", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Content-Sha256", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Date")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Date", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Credential")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Credential", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Security-Token")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Security-Token", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Algorithm")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Algorithm", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-SignedHeaders", valid_611360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_DeleteEmailTemplate_611349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_DeleteEmailTemplate_611349; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611363 = newJObject()
  var query_611364 = newJObject()
  add(path_611363, "template-name", newJString(templateName))
  add(query_611364, "version", newJString(version))
  result = call_611362.call(path_611363, query_611364, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_611349(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_611350, base: "/",
    url: url_DeleteEmailTemplate_611351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_611382 = ref object of OpenApiRestCall_610642
proc url_CreateExportJob_611384(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_611383(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_611385 = path.getOrDefault("application-id")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = nil)
  if valid_611385 != nil:
    section.add "application-id", valid_611385
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
  var valid_611386 = header.getOrDefault("X-Amz-Signature")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Signature", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Content-Sha256", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Date")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Date", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Credential")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Credential", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Security-Token")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Security-Token", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Algorithm")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Algorithm", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-SignedHeaders", valid_611392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611394: Call_CreateExportJob_611382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_611394.validator(path, query, header, formData, body)
  let scheme = call_611394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611394.url(scheme.get, call_611394.host, call_611394.base,
                         call_611394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611394, url, valid)

proc call*(call_611395: Call_CreateExportJob_611382; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611396 = newJObject()
  var body_611397 = newJObject()
  add(path_611396, "application-id", newJString(applicationId))
  if body != nil:
    body_611397 = body
  result = call_611395.call(path_611396, nil, nil, nil, body_611397)

var createExportJob* = Call_CreateExportJob_611382(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_611383, base: "/", url: url_CreateExportJob_611384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_611365 = ref object of OpenApiRestCall_610642
proc url_GetExportJobs_611367(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_611366(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611368 = path.getOrDefault("application-id")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = nil)
  if valid_611368 != nil:
    section.add "application-id", valid_611368
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611369 = query.getOrDefault("page-size")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "page-size", valid_611369
  var valid_611370 = query.getOrDefault("token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "token", valid_611370
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
  var valid_611371 = header.getOrDefault("X-Amz-Signature")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Signature", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Content-Sha256", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Date")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Date", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Credential")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Credential", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Security-Token")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Security-Token", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Algorithm")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Algorithm", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-SignedHeaders", valid_611377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611378: Call_GetExportJobs_611365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_611378.validator(path, query, header, formData, body)
  let scheme = call_611378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611378.url(scheme.get, call_611378.host, call_611378.base,
                         call_611378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611378, url, valid)

proc call*(call_611379: Call_GetExportJobs_611365; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_611380 = newJObject()
  var query_611381 = newJObject()
  add(path_611380, "application-id", newJString(applicationId))
  add(query_611381, "page-size", newJString(pageSize))
  add(query_611381, "token", newJString(token))
  result = call_611379.call(path_611380, query_611381, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_611365(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_611366, base: "/", url: url_GetExportJobs_611367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_611415 = ref object of OpenApiRestCall_610642
proc url_CreateImportJob_611417(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_611416(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_611418 = path.getOrDefault("application-id")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = nil)
  if valid_611418 != nil:
    section.add "application-id", valid_611418
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
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_CreateImportJob_611415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_CreateImportJob_611415; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611429 = newJObject()
  var body_611430 = newJObject()
  add(path_611429, "application-id", newJString(applicationId))
  if body != nil:
    body_611430 = body
  result = call_611428.call(path_611429, nil, nil, nil, body_611430)

var createImportJob* = Call_CreateImportJob_611415(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_611416, base: "/", url: url_CreateImportJob_611417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_611398 = ref object of OpenApiRestCall_610642
proc url_GetImportJobs_611400(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_611399(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611401 = path.getOrDefault("application-id")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "application-id", valid_611401
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611402 = query.getOrDefault("page-size")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "page-size", valid_611402
  var valid_611403 = query.getOrDefault("token")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "token", valid_611403
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
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611411: Call_GetImportJobs_611398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_611411.validator(path, query, header, formData, body)
  let scheme = call_611411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611411.url(scheme.get, call_611411.host, call_611411.base,
                         call_611411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611411, url, valid)

proc call*(call_611412: Call_GetImportJobs_611398; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_611413 = newJObject()
  var query_611414 = newJObject()
  add(path_611413, "application-id", newJString(applicationId))
  add(query_611414, "page-size", newJString(pageSize))
  add(query_611414, "token", newJString(token))
  result = call_611412.call(path_611413, query_611414, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_611398(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_611399, base: "/", url: url_GetImportJobs_611400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_611448 = ref object of OpenApiRestCall_610642
proc url_CreateJourney_611450(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_611449(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611451 = path.getOrDefault("application-id")
  valid_611451 = validateParameter(valid_611451, JString, required = true,
                                 default = nil)
  if valid_611451 != nil:
    section.add "application-id", valid_611451
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
  var valid_611452 = header.getOrDefault("X-Amz-Signature")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Signature", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Content-Sha256", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Date")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Date", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Credential")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Credential", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Security-Token")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Security-Token", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Algorithm")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Algorithm", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-SignedHeaders", valid_611458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611460: Call_CreateJourney_611448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_611460.validator(path, query, header, formData, body)
  let scheme = call_611460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611460.url(scheme.get, call_611460.host, call_611460.base,
                         call_611460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611460, url, valid)

proc call*(call_611461: Call_CreateJourney_611448; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611462 = newJObject()
  var body_611463 = newJObject()
  add(path_611462, "application-id", newJString(applicationId))
  if body != nil:
    body_611463 = body
  result = call_611461.call(path_611462, nil, nil, nil, body_611463)

var createJourney* = Call_CreateJourney_611448(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_611449, base: "/", url: url_CreateJourney_611450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_611431 = ref object of OpenApiRestCall_610642
proc url_ListJourneys_611433(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_611432(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611434 = path.getOrDefault("application-id")
  valid_611434 = validateParameter(valid_611434, JString, required = true,
                                 default = nil)
  if valid_611434 != nil:
    section.add "application-id", valid_611434
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611435 = query.getOrDefault("page-size")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "page-size", valid_611435
  var valid_611436 = query.getOrDefault("token")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "token", valid_611436
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
  var valid_611437 = header.getOrDefault("X-Amz-Signature")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Signature", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Content-Sha256", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Date")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Date", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Credential")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Credential", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Security-Token")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Security-Token", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Algorithm")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Algorithm", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-SignedHeaders", valid_611443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611444: Call_ListJourneys_611431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_611444.validator(path, query, header, formData, body)
  let scheme = call_611444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611444.url(scheme.get, call_611444.host, call_611444.base,
                         call_611444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611444, url, valid)

proc call*(call_611445: Call_ListJourneys_611431; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_611446 = newJObject()
  var query_611447 = newJObject()
  add(path_611446, "application-id", newJString(applicationId))
  add(query_611447, "page-size", newJString(pageSize))
  add(query_611447, "token", newJString(token))
  result = call_611445.call(path_611446, query_611447, nil, nil, nil)

var listJourneys* = Call_ListJourneys_611431(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_611432,
    base: "/", url: url_ListJourneys_611433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_611480 = ref object of OpenApiRestCall_610642
proc url_UpdatePushTemplate_611482(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_611481(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611483 = path.getOrDefault("template-name")
  valid_611483 = validateParameter(valid_611483, JString, required = true,
                                 default = nil)
  if valid_611483 != nil:
    section.add "template-name", valid_611483
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_611484 = query.getOrDefault("version")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "version", valid_611484
  var valid_611485 = query.getOrDefault("create-new-version")
  valid_611485 = validateParameter(valid_611485, JBool, required = false, default = nil)
  if valid_611485 != nil:
    section.add "create-new-version", valid_611485
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
  var valid_611486 = header.getOrDefault("X-Amz-Signature")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Signature", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Content-Sha256", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Date")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Date", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Credential")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Credential", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Security-Token")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Security-Token", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Algorithm")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Algorithm", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-SignedHeaders", valid_611492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611494: Call_UpdatePushTemplate_611480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_611494.validator(path, query, header, formData, body)
  let scheme = call_611494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611494.url(scheme.get, call_611494.host, call_611494.base,
                         call_611494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611494, url, valid)

proc call*(call_611495: Call_UpdatePushTemplate_611480; templateName: string;
          body: JsonNode; version: string = ""; createNewVersion: bool = false): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   body: JObject (required)
  var path_611496 = newJObject()
  var query_611497 = newJObject()
  var body_611498 = newJObject()
  add(path_611496, "template-name", newJString(templateName))
  add(query_611497, "version", newJString(version))
  add(query_611497, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_611498 = body
  result = call_611495.call(path_611496, query_611497, nil, nil, body_611498)

var updatePushTemplate* = Call_UpdatePushTemplate_611480(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_611481, base: "/",
    url: url_UpdatePushTemplate_611482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_611499 = ref object of OpenApiRestCall_610642
proc url_CreatePushTemplate_611501(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_611500(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611502 = path.getOrDefault("template-name")
  valid_611502 = validateParameter(valid_611502, JString, required = true,
                                 default = nil)
  if valid_611502 != nil:
    section.add "template-name", valid_611502
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
  var valid_611503 = header.getOrDefault("X-Amz-Signature")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Signature", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Content-Sha256", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Date")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Date", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Credential")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Credential", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Security-Token")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Security-Token", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Algorithm")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Algorithm", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-SignedHeaders", valid_611509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611511: Call_CreatePushTemplate_611499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_611511.validator(path, query, header, formData, body)
  let scheme = call_611511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611511.url(scheme.get, call_611511.host, call_611511.base,
                         call_611511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611511, url, valid)

proc call*(call_611512: Call_CreatePushTemplate_611499; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_611513 = newJObject()
  var body_611514 = newJObject()
  add(path_611513, "template-name", newJString(templateName))
  if body != nil:
    body_611514 = body
  result = call_611512.call(path_611513, nil, nil, nil, body_611514)

var createPushTemplate* = Call_CreatePushTemplate_611499(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_611500, base: "/",
    url: url_CreatePushTemplate_611501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_611464 = ref object of OpenApiRestCall_610642
proc url_GetPushTemplate_611466(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_611465(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_611467 = path.getOrDefault("template-name")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = nil)
  if valid_611467 != nil:
    section.add "template-name", valid_611467
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611468 = query.getOrDefault("version")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "version", valid_611468
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
  var valid_611469 = header.getOrDefault("X-Amz-Signature")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Signature", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Content-Sha256", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Date")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Date", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Credential")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Credential", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Security-Token")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Security-Token", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Algorithm")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Algorithm", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-SignedHeaders", valid_611475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_GetPushTemplate_611464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_GetPushTemplate_611464; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611478 = newJObject()
  var query_611479 = newJObject()
  add(path_611478, "template-name", newJString(templateName))
  add(query_611479, "version", newJString(version))
  result = call_611477.call(path_611478, query_611479, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_611464(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_611465, base: "/", url: url_GetPushTemplate_611466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_611515 = ref object of OpenApiRestCall_610642
proc url_DeletePushTemplate_611517(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_611516(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611518 = path.getOrDefault("template-name")
  valid_611518 = validateParameter(valid_611518, JString, required = true,
                                 default = nil)
  if valid_611518 != nil:
    section.add "template-name", valid_611518
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611519 = query.getOrDefault("version")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "version", valid_611519
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
  var valid_611520 = header.getOrDefault("X-Amz-Signature")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Signature", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Content-Sha256", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Date")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Date", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Credential")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Credential", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Security-Token")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Security-Token", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Algorithm")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Algorithm", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-SignedHeaders", valid_611526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611527: Call_DeletePushTemplate_611515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_611527.validator(path, query, header, formData, body)
  let scheme = call_611527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611527.url(scheme.get, call_611527.host, call_611527.base,
                         call_611527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611527, url, valid)

proc call*(call_611528: Call_DeletePushTemplate_611515; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611529 = newJObject()
  var query_611530 = newJObject()
  add(path_611529, "template-name", newJString(templateName))
  add(query_611530, "version", newJString(version))
  result = call_611528.call(path_611529, query_611530, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_611515(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_611516, base: "/",
    url: url_DeletePushTemplate_611517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_611548 = ref object of OpenApiRestCall_610642
proc url_CreateSegment_611550(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_611549(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611551 = path.getOrDefault("application-id")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = nil)
  if valid_611551 != nil:
    section.add "application-id", valid_611551
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
  var valid_611552 = header.getOrDefault("X-Amz-Signature")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Signature", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Content-Sha256", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Date")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Date", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Credential")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Credential", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Security-Token")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Security-Token", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Algorithm")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Algorithm", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-SignedHeaders", valid_611558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_CreateSegment_611548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_CreateSegment_611548; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611562 = newJObject()
  var body_611563 = newJObject()
  add(path_611562, "application-id", newJString(applicationId))
  if body != nil:
    body_611563 = body
  result = call_611561.call(path_611562, nil, nil, nil, body_611563)

var createSegment* = Call_CreateSegment_611548(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_611549, base: "/", url: url_CreateSegment_611550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_611531 = ref object of OpenApiRestCall_610642
proc url_GetSegments_611533(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_611532(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611534 = path.getOrDefault("application-id")
  valid_611534 = validateParameter(valid_611534, JString, required = true,
                                 default = nil)
  if valid_611534 != nil:
    section.add "application-id", valid_611534
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_611535 = query.getOrDefault("page-size")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "page-size", valid_611535
  var valid_611536 = query.getOrDefault("token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "token", valid_611536
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
  var valid_611537 = header.getOrDefault("X-Amz-Signature")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Signature", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Content-Sha256", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Date")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Date", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Credential")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Credential", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Security-Token")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Security-Token", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Algorithm")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Algorithm", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-SignedHeaders", valid_611543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611544: Call_GetSegments_611531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_611544.validator(path, query, header, formData, body)
  let scheme = call_611544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611544.url(scheme.get, call_611544.host, call_611544.base,
                         call_611544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611544, url, valid)

proc call*(call_611545: Call_GetSegments_611531; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_611546 = newJObject()
  var query_611547 = newJObject()
  add(path_611546, "application-id", newJString(applicationId))
  add(query_611547, "page-size", newJString(pageSize))
  add(query_611547, "token", newJString(token))
  result = call_611545.call(path_611546, query_611547, nil, nil, nil)

var getSegments* = Call_GetSegments_611531(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_611532,
                                        base: "/", url: url_GetSegments_611533,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_611580 = ref object of OpenApiRestCall_610642
proc url_UpdateSmsTemplate_611582(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_611581(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611583 = path.getOrDefault("template-name")
  valid_611583 = validateParameter(valid_611583, JString, required = true,
                                 default = nil)
  if valid_611583 != nil:
    section.add "template-name", valid_611583
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_611584 = query.getOrDefault("version")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "version", valid_611584
  var valid_611585 = query.getOrDefault("create-new-version")
  valid_611585 = validateParameter(valid_611585, JBool, required = false, default = nil)
  if valid_611585 != nil:
    section.add "create-new-version", valid_611585
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
  var valid_611586 = header.getOrDefault("X-Amz-Signature")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Signature", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Content-Sha256", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Date")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Date", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Credential")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Credential", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Security-Token")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Security-Token", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Algorithm")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Algorithm", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-SignedHeaders", valid_611592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611594: Call_UpdateSmsTemplate_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_611594.validator(path, query, header, formData, body)
  let scheme = call_611594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611594.url(scheme.get, call_611594.host, call_611594.base,
                         call_611594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611594, url, valid)

proc call*(call_611595: Call_UpdateSmsTemplate_611580; templateName: string;
          body: JsonNode; version: string = ""; createNewVersion: bool = false): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   body: JObject (required)
  var path_611596 = newJObject()
  var query_611597 = newJObject()
  var body_611598 = newJObject()
  add(path_611596, "template-name", newJString(templateName))
  add(query_611597, "version", newJString(version))
  add(query_611597, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_611598 = body
  result = call_611595.call(path_611596, query_611597, nil, nil, body_611598)

var updateSmsTemplate* = Call_UpdateSmsTemplate_611580(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_611581, base: "/",
    url: url_UpdateSmsTemplate_611582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_611599 = ref object of OpenApiRestCall_610642
proc url_CreateSmsTemplate_611601(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_611600(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611602 = path.getOrDefault("template-name")
  valid_611602 = validateParameter(valid_611602, JString, required = true,
                                 default = nil)
  if valid_611602 != nil:
    section.add "template-name", valid_611602
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
  var valid_611603 = header.getOrDefault("X-Amz-Signature")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Signature", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Content-Sha256", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Date")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Date", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Credential")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Credential", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Security-Token")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Security-Token", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Algorithm")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Algorithm", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-SignedHeaders", valid_611609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611611: Call_CreateSmsTemplate_611599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_611611.validator(path, query, header, formData, body)
  let scheme = call_611611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611611.url(scheme.get, call_611611.host, call_611611.base,
                         call_611611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611611, url, valid)

proc call*(call_611612: Call_CreateSmsTemplate_611599; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_611613 = newJObject()
  var body_611614 = newJObject()
  add(path_611613, "template-name", newJString(templateName))
  if body != nil:
    body_611614 = body
  result = call_611612.call(path_611613, nil, nil, nil, body_611614)

var createSmsTemplate* = Call_CreateSmsTemplate_611599(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_611600, base: "/",
    url: url_CreateSmsTemplate_611601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_611564 = ref object of OpenApiRestCall_610642
proc url_GetSmsTemplate_611566(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_611565(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_611567 = path.getOrDefault("template-name")
  valid_611567 = validateParameter(valid_611567, JString, required = true,
                                 default = nil)
  if valid_611567 != nil:
    section.add "template-name", valid_611567
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611568 = query.getOrDefault("version")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "version", valid_611568
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
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611576: Call_GetSmsTemplate_611564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_611576.validator(path, query, header, formData, body)
  let scheme = call_611576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611576.url(scheme.get, call_611576.host, call_611576.base,
                         call_611576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611576, url, valid)

proc call*(call_611577: Call_GetSmsTemplate_611564; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611578 = newJObject()
  var query_611579 = newJObject()
  add(path_611578, "template-name", newJString(templateName))
  add(query_611579, "version", newJString(version))
  result = call_611577.call(path_611578, query_611579, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_611564(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_611565, base: "/", url: url_GetSmsTemplate_611566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_611615 = ref object of OpenApiRestCall_610642
proc url_DeleteSmsTemplate_611617(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_611616(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611618 = path.getOrDefault("template-name")
  valid_611618 = validateParameter(valid_611618, JString, required = true,
                                 default = nil)
  if valid_611618 != nil:
    section.add "template-name", valid_611618
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611619 = query.getOrDefault("version")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "version", valid_611619
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
  var valid_611620 = header.getOrDefault("X-Amz-Signature")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Signature", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Content-Sha256", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Date")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Date", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Credential")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Credential", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Security-Token")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Security-Token", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Algorithm")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Algorithm", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-SignedHeaders", valid_611626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611627: Call_DeleteSmsTemplate_611615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_611627.validator(path, query, header, formData, body)
  let scheme = call_611627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611627.url(scheme.get, call_611627.host, call_611627.base,
                         call_611627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611627, url, valid)

proc call*(call_611628: Call_DeleteSmsTemplate_611615; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611629 = newJObject()
  var query_611630 = newJObject()
  add(path_611629, "template-name", newJString(templateName))
  add(query_611630, "version", newJString(version))
  result = call_611628.call(path_611629, query_611630, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_611615(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_611616, base: "/",
    url: url_DeleteSmsTemplate_611617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_611647 = ref object of OpenApiRestCall_610642
proc url_UpdateVoiceTemplate_611649(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceTemplate_611648(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611650 = path.getOrDefault("template-name")
  valid_611650 = validateParameter(valid_611650, JString, required = true,
                                 default = nil)
  if valid_611650 != nil:
    section.add "template-name", valid_611650
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_611651 = query.getOrDefault("version")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "version", valid_611651
  var valid_611652 = query.getOrDefault("create-new-version")
  valid_611652 = validateParameter(valid_611652, JBool, required = false, default = nil)
  if valid_611652 != nil:
    section.add "create-new-version", valid_611652
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
  var valid_611653 = header.getOrDefault("X-Amz-Signature")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Signature", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Content-Sha256", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Date")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Date", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Credential")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Credential", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Security-Token")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Security-Token", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Algorithm")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Algorithm", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-SignedHeaders", valid_611659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611661: Call_UpdateVoiceTemplate_611647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_611661.validator(path, query, header, formData, body)
  let scheme = call_611661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611661.url(scheme.get, call_611661.host, call_611661.base,
                         call_611661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611661, url, valid)

proc call*(call_611662: Call_UpdateVoiceTemplate_611647; templateName: string;
          body: JsonNode; version: string = ""; createNewVersion: bool = false): Recallable =
  ## updateVoiceTemplate
  ## Updates an existing message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   createNewVersion: bool
  ##                   : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  ##   body: JObject (required)
  var path_611663 = newJObject()
  var query_611664 = newJObject()
  var body_611665 = newJObject()
  add(path_611663, "template-name", newJString(templateName))
  add(query_611664, "version", newJString(version))
  add(query_611664, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_611665 = body
  result = call_611662.call(path_611663, query_611664, nil, nil, body_611665)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_611647(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_611648, base: "/",
    url: url_UpdateVoiceTemplate_611649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_611666 = ref object of OpenApiRestCall_610642
proc url_CreateVoiceTemplate_611668(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceTemplate_611667(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611669 = path.getOrDefault("template-name")
  valid_611669 = validateParameter(valid_611669, JString, required = true,
                                 default = nil)
  if valid_611669 != nil:
    section.add "template-name", valid_611669
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
  var valid_611670 = header.getOrDefault("X-Amz-Signature")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Signature", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Content-Sha256", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Date")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Date", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Credential")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Credential", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Security-Token")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Security-Token", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Algorithm")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Algorithm", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-SignedHeaders", valid_611676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611678: Call_CreateVoiceTemplate_611666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_611678.validator(path, query, header, formData, body)
  let scheme = call_611678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611678.url(scheme.get, call_611678.host, call_611678.base,
                         call_611678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611678, url, valid)

proc call*(call_611679: Call_CreateVoiceTemplate_611666; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_611680 = newJObject()
  var body_611681 = newJObject()
  add(path_611680, "template-name", newJString(templateName))
  if body != nil:
    body_611681 = body
  result = call_611679.call(path_611680, nil, nil, nil, body_611681)

var createVoiceTemplate* = Call_CreateVoiceTemplate_611666(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_611667, base: "/",
    url: url_CreateVoiceTemplate_611668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_611631 = ref object of OpenApiRestCall_610642
proc url_GetVoiceTemplate_611633(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceTemplate_611632(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_611634 = path.getOrDefault("template-name")
  valid_611634 = validateParameter(valid_611634, JString, required = true,
                                 default = nil)
  if valid_611634 != nil:
    section.add "template-name", valid_611634
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611635 = query.getOrDefault("version")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "version", valid_611635
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
  var valid_611636 = header.getOrDefault("X-Amz-Signature")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Signature", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Content-Sha256", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Date")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Date", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Credential")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Credential", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Security-Token")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Security-Token", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Algorithm")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Algorithm", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-SignedHeaders", valid_611642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611643: Call_GetVoiceTemplate_611631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_611643.validator(path, query, header, formData, body)
  let scheme = call_611643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611643.url(scheme.get, call_611643.host, call_611643.base,
                         call_611643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611643, url, valid)

proc call*(call_611644: Call_GetVoiceTemplate_611631; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611645 = newJObject()
  var query_611646 = newJObject()
  add(path_611645, "template-name", newJString(templateName))
  add(query_611646, "version", newJString(version))
  result = call_611644.call(path_611645, query_611646, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_611631(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_611632, base: "/",
    url: url_GetVoiceTemplate_611633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_611682 = ref object of OpenApiRestCall_610642
proc url_DeleteVoiceTemplate_611684(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceTemplate_611683(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611685 = path.getOrDefault("template-name")
  valid_611685 = validateParameter(valid_611685, JString, required = true,
                                 default = nil)
  if valid_611685 != nil:
    section.add "template-name", valid_611685
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_611686 = query.getOrDefault("version")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "version", valid_611686
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
  var valid_611687 = header.getOrDefault("X-Amz-Signature")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Signature", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Content-Sha256", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Date")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Date", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Credential")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Credential", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Security-Token")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Security-Token", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Algorithm")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Algorithm", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-SignedHeaders", valid_611693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611694: Call_DeleteVoiceTemplate_611682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_611694.validator(path, query, header, formData, body)
  let scheme = call_611694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611694.url(scheme.get, call_611694.host, call_611694.base,
                         call_611694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611694, url, valid)

proc call*(call_611695: Call_DeleteVoiceTemplate_611682; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_611696 = newJObject()
  var query_611697 = newJObject()
  add(path_611696, "template-name", newJString(templateName))
  add(query_611697, "version", newJString(version))
  result = call_611695.call(path_611696, query_611697, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_611682(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_611683, base: "/",
    url: url_DeleteVoiceTemplate_611684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_611712 = ref object of OpenApiRestCall_610642
proc url_UpdateAdmChannel_611714(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_611713(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_611715 = path.getOrDefault("application-id")
  valid_611715 = validateParameter(valid_611715, JString, required = true,
                                 default = nil)
  if valid_611715 != nil:
    section.add "application-id", valid_611715
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
  var valid_611716 = header.getOrDefault("X-Amz-Signature")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Signature", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Content-Sha256", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Date")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Date", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Credential")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Credential", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Security-Token")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Security-Token", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Algorithm")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Algorithm", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-SignedHeaders", valid_611722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611724: Call_UpdateAdmChannel_611712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_611724.validator(path, query, header, formData, body)
  let scheme = call_611724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611724.url(scheme.get, call_611724.host, call_611724.base,
                         call_611724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611724, url, valid)

proc call*(call_611725: Call_UpdateAdmChannel_611712; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611726 = newJObject()
  var body_611727 = newJObject()
  add(path_611726, "application-id", newJString(applicationId))
  if body != nil:
    body_611727 = body
  result = call_611725.call(path_611726, nil, nil, nil, body_611727)

var updateAdmChannel* = Call_UpdateAdmChannel_611712(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_611713, base: "/",
    url: url_UpdateAdmChannel_611714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_611698 = ref object of OpenApiRestCall_610642
proc url_GetAdmChannel_611700(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_611699(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611701 = path.getOrDefault("application-id")
  valid_611701 = validateParameter(valid_611701, JString, required = true,
                                 default = nil)
  if valid_611701 != nil:
    section.add "application-id", valid_611701
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
  var valid_611702 = header.getOrDefault("X-Amz-Signature")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Signature", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Content-Sha256", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Date")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Date", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Credential")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Credential", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Security-Token")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Security-Token", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Algorithm")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Algorithm", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-SignedHeaders", valid_611708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611709: Call_GetAdmChannel_611698; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_611709.validator(path, query, header, formData, body)
  let scheme = call_611709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611709.url(scheme.get, call_611709.host, call_611709.base,
                         call_611709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611709, url, valid)

proc call*(call_611710: Call_GetAdmChannel_611698; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611711 = newJObject()
  add(path_611711, "application-id", newJString(applicationId))
  result = call_611710.call(path_611711, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_611698(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_611699, base: "/", url: url_GetAdmChannel_611700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_611728 = ref object of OpenApiRestCall_610642
proc url_DeleteAdmChannel_611730(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_611729(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_611731 = path.getOrDefault("application-id")
  valid_611731 = validateParameter(valid_611731, JString, required = true,
                                 default = nil)
  if valid_611731 != nil:
    section.add "application-id", valid_611731
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
  var valid_611732 = header.getOrDefault("X-Amz-Signature")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Signature", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Content-Sha256", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Date")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Date", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Credential")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Credential", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Security-Token")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Security-Token", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Algorithm")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Algorithm", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-SignedHeaders", valid_611738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611739: Call_DeleteAdmChannel_611728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611739.validator(path, query, header, formData, body)
  let scheme = call_611739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611739.url(scheme.get, call_611739.host, call_611739.base,
                         call_611739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611739, url, valid)

proc call*(call_611740: Call_DeleteAdmChannel_611728; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611741 = newJObject()
  add(path_611741, "application-id", newJString(applicationId))
  result = call_611740.call(path_611741, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_611728(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_611729, base: "/",
    url: url_DeleteAdmChannel_611730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_611756 = ref object of OpenApiRestCall_610642
proc url_UpdateApnsChannel_611758(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_611757(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611759 = path.getOrDefault("application-id")
  valid_611759 = validateParameter(valid_611759, JString, required = true,
                                 default = nil)
  if valid_611759 != nil:
    section.add "application-id", valid_611759
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
  var valid_611760 = header.getOrDefault("X-Amz-Signature")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Signature", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Content-Sha256", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Date")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Date", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Credential")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Credential", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Security-Token")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Security-Token", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Algorithm")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Algorithm", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-SignedHeaders", valid_611766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611768: Call_UpdateApnsChannel_611756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_611768.validator(path, query, header, formData, body)
  let scheme = call_611768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611768.url(scheme.get, call_611768.host, call_611768.base,
                         call_611768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611768, url, valid)

proc call*(call_611769: Call_UpdateApnsChannel_611756; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611770 = newJObject()
  var body_611771 = newJObject()
  add(path_611770, "application-id", newJString(applicationId))
  if body != nil:
    body_611771 = body
  result = call_611769.call(path_611770, nil, nil, nil, body_611771)

var updateApnsChannel* = Call_UpdateApnsChannel_611756(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_611757, base: "/",
    url: url_UpdateApnsChannel_611758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_611742 = ref object of OpenApiRestCall_610642
proc url_GetApnsChannel_611744(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_611743(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_611745 = path.getOrDefault("application-id")
  valid_611745 = validateParameter(valid_611745, JString, required = true,
                                 default = nil)
  if valid_611745 != nil:
    section.add "application-id", valid_611745
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
  var valid_611746 = header.getOrDefault("X-Amz-Signature")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Signature", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Content-Sha256", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Date")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Date", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Credential")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Credential", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Security-Token")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Security-Token", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Algorithm")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Algorithm", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-SignedHeaders", valid_611752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611753: Call_GetApnsChannel_611742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_611753.validator(path, query, header, formData, body)
  let scheme = call_611753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611753.url(scheme.get, call_611753.host, call_611753.base,
                         call_611753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611753, url, valid)

proc call*(call_611754: Call_GetApnsChannel_611742; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611755 = newJObject()
  add(path_611755, "application-id", newJString(applicationId))
  result = call_611754.call(path_611755, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_611742(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_611743, base: "/", url: url_GetApnsChannel_611744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_611772 = ref object of OpenApiRestCall_610642
proc url_DeleteApnsChannel_611774(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_611773(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611775 = path.getOrDefault("application-id")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = nil)
  if valid_611775 != nil:
    section.add "application-id", valid_611775
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
  var valid_611776 = header.getOrDefault("X-Amz-Signature")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Signature", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Content-Sha256", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Date")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Date", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Credential")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Credential", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Security-Token")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Security-Token", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Algorithm")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Algorithm", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-SignedHeaders", valid_611782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611783: Call_DeleteApnsChannel_611772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611783.validator(path, query, header, formData, body)
  let scheme = call_611783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611783.url(scheme.get, call_611783.host, call_611783.base,
                         call_611783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611783, url, valid)

proc call*(call_611784: Call_DeleteApnsChannel_611772; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611785 = newJObject()
  add(path_611785, "application-id", newJString(applicationId))
  result = call_611784.call(path_611785, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_611772(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_611773, base: "/",
    url: url_DeleteApnsChannel_611774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_611800 = ref object of OpenApiRestCall_610642
proc url_UpdateApnsSandboxChannel_611802(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_611801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611803 = path.getOrDefault("application-id")
  valid_611803 = validateParameter(valid_611803, JString, required = true,
                                 default = nil)
  if valid_611803 != nil:
    section.add "application-id", valid_611803
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
  var valid_611804 = header.getOrDefault("X-Amz-Signature")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Signature", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Content-Sha256", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Date")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Date", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Credential")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Credential", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Security-Token")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Security-Token", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Algorithm")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Algorithm", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-SignedHeaders", valid_611810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611812: Call_UpdateApnsSandboxChannel_611800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_611812.validator(path, query, header, formData, body)
  let scheme = call_611812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611812.url(scheme.get, call_611812.host, call_611812.base,
                         call_611812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611812, url, valid)

proc call*(call_611813: Call_UpdateApnsSandboxChannel_611800;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611814 = newJObject()
  var body_611815 = newJObject()
  add(path_611814, "application-id", newJString(applicationId))
  if body != nil:
    body_611815 = body
  result = call_611813.call(path_611814, nil, nil, nil, body_611815)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_611800(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_611801, base: "/",
    url: url_UpdateApnsSandboxChannel_611802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_611786 = ref object of OpenApiRestCall_610642
proc url_GetApnsSandboxChannel_611788(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_611787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611789 = path.getOrDefault("application-id")
  valid_611789 = validateParameter(valid_611789, JString, required = true,
                                 default = nil)
  if valid_611789 != nil:
    section.add "application-id", valid_611789
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
  var valid_611790 = header.getOrDefault("X-Amz-Signature")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Signature", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Content-Sha256", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Date")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Date", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Credential")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Credential", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Security-Token")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Security-Token", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Algorithm")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Algorithm", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-SignedHeaders", valid_611796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611797: Call_GetApnsSandboxChannel_611786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_611797.validator(path, query, header, formData, body)
  let scheme = call_611797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611797.url(scheme.get, call_611797.host, call_611797.base,
                         call_611797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611797, url, valid)

proc call*(call_611798: Call_GetApnsSandboxChannel_611786; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611799 = newJObject()
  add(path_611799, "application-id", newJString(applicationId))
  result = call_611798.call(path_611799, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_611786(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_611787, base: "/",
    url: url_GetApnsSandboxChannel_611788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_611816 = ref object of OpenApiRestCall_610642
proc url_DeleteApnsSandboxChannel_611818(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_611817(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611819 = path.getOrDefault("application-id")
  valid_611819 = validateParameter(valid_611819, JString, required = true,
                                 default = nil)
  if valid_611819 != nil:
    section.add "application-id", valid_611819
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
  var valid_611820 = header.getOrDefault("X-Amz-Signature")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Signature", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Content-Sha256", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-Date")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Date", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Credential")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Credential", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Security-Token")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Security-Token", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Algorithm")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Algorithm", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-SignedHeaders", valid_611826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611827: Call_DeleteApnsSandboxChannel_611816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611827.validator(path, query, header, formData, body)
  let scheme = call_611827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611827.url(scheme.get, call_611827.host, call_611827.base,
                         call_611827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611827, url, valid)

proc call*(call_611828: Call_DeleteApnsSandboxChannel_611816; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611829 = newJObject()
  add(path_611829, "application-id", newJString(applicationId))
  result = call_611828.call(path_611829, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_611816(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_611817, base: "/",
    url: url_DeleteApnsSandboxChannel_611818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_611844 = ref object of OpenApiRestCall_610642
proc url_UpdateApnsVoipChannel_611846(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_611845(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611847 = path.getOrDefault("application-id")
  valid_611847 = validateParameter(valid_611847, JString, required = true,
                                 default = nil)
  if valid_611847 != nil:
    section.add "application-id", valid_611847
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
  var valid_611848 = header.getOrDefault("X-Amz-Signature")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Signature", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Content-Sha256", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Date")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Date", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Credential")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Credential", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Security-Token")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Security-Token", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Algorithm")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Algorithm", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-SignedHeaders", valid_611854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611856: Call_UpdateApnsVoipChannel_611844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_611856.validator(path, query, header, formData, body)
  let scheme = call_611856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611856.url(scheme.get, call_611856.host, call_611856.base,
                         call_611856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611856, url, valid)

proc call*(call_611857: Call_UpdateApnsVoipChannel_611844; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611858 = newJObject()
  var body_611859 = newJObject()
  add(path_611858, "application-id", newJString(applicationId))
  if body != nil:
    body_611859 = body
  result = call_611857.call(path_611858, nil, nil, nil, body_611859)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_611844(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_611845, base: "/",
    url: url_UpdateApnsVoipChannel_611846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_611830 = ref object of OpenApiRestCall_610642
proc url_GetApnsVoipChannel_611832(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_611831(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611833 = path.getOrDefault("application-id")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "application-id", valid_611833
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
  var valid_611834 = header.getOrDefault("X-Amz-Signature")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Signature", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Content-Sha256", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Date")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Date", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Credential")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Credential", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Security-Token")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Security-Token", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Algorithm")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Algorithm", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-SignedHeaders", valid_611840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611841: Call_GetApnsVoipChannel_611830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_611841.validator(path, query, header, formData, body)
  let scheme = call_611841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611841.url(scheme.get, call_611841.host, call_611841.base,
                         call_611841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611841, url, valid)

proc call*(call_611842: Call_GetApnsVoipChannel_611830; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611843 = newJObject()
  add(path_611843, "application-id", newJString(applicationId))
  result = call_611842.call(path_611843, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_611830(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_611831, base: "/",
    url: url_GetApnsVoipChannel_611832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_611860 = ref object of OpenApiRestCall_610642
proc url_DeleteApnsVoipChannel_611862(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_611861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611863 = path.getOrDefault("application-id")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = nil)
  if valid_611863 != nil:
    section.add "application-id", valid_611863
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
  var valid_611864 = header.getOrDefault("X-Amz-Signature")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Signature", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Content-Sha256", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Date")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Date", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Credential")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Credential", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Security-Token")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Security-Token", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Algorithm")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Algorithm", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-SignedHeaders", valid_611870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611871: Call_DeleteApnsVoipChannel_611860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611871.validator(path, query, header, formData, body)
  let scheme = call_611871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611871.url(scheme.get, call_611871.host, call_611871.base,
                         call_611871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611871, url, valid)

proc call*(call_611872: Call_DeleteApnsVoipChannel_611860; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611873 = newJObject()
  add(path_611873, "application-id", newJString(applicationId))
  result = call_611872.call(path_611873, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_611860(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_611861, base: "/",
    url: url_DeleteApnsVoipChannel_611862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_611888 = ref object of OpenApiRestCall_610642
proc url_UpdateApnsVoipSandboxChannel_611890(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_611889(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611891 = path.getOrDefault("application-id")
  valid_611891 = validateParameter(valid_611891, JString, required = true,
                                 default = nil)
  if valid_611891 != nil:
    section.add "application-id", valid_611891
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
  var valid_611892 = header.getOrDefault("X-Amz-Signature")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Signature", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Content-Sha256", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Date")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Date", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Credential")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Credential", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Security-Token")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Security-Token", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Algorithm")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Algorithm", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-SignedHeaders", valid_611898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611900: Call_UpdateApnsVoipSandboxChannel_611888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_611900.validator(path, query, header, formData, body)
  let scheme = call_611900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611900.url(scheme.get, call_611900.host, call_611900.base,
                         call_611900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611900, url, valid)

proc call*(call_611901: Call_UpdateApnsVoipSandboxChannel_611888;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611902 = newJObject()
  var body_611903 = newJObject()
  add(path_611902, "application-id", newJString(applicationId))
  if body != nil:
    body_611903 = body
  result = call_611901.call(path_611902, nil, nil, nil, body_611903)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_611888(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_611889, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_611890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_611874 = ref object of OpenApiRestCall_610642
proc url_GetApnsVoipSandboxChannel_611876(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_611875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611877 = path.getOrDefault("application-id")
  valid_611877 = validateParameter(valid_611877, JString, required = true,
                                 default = nil)
  if valid_611877 != nil:
    section.add "application-id", valid_611877
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
  var valid_611878 = header.getOrDefault("X-Amz-Signature")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Signature", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Content-Sha256", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Date")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Date", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Credential")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Credential", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Security-Token")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Security-Token", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Algorithm")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Algorithm", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-SignedHeaders", valid_611884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611885: Call_GetApnsVoipSandboxChannel_611874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_611885.validator(path, query, header, formData, body)
  let scheme = call_611885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611885.url(scheme.get, call_611885.host, call_611885.base,
                         call_611885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611885, url, valid)

proc call*(call_611886: Call_GetApnsVoipSandboxChannel_611874;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611887 = newJObject()
  add(path_611887, "application-id", newJString(applicationId))
  result = call_611886.call(path_611887, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_611874(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_611875, base: "/",
    url: url_GetApnsVoipSandboxChannel_611876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_611904 = ref object of OpenApiRestCall_610642
proc url_DeleteApnsVoipSandboxChannel_611906(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_611905(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611907 = path.getOrDefault("application-id")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "application-id", valid_611907
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
  var valid_611908 = header.getOrDefault("X-Amz-Signature")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Signature", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Content-Sha256", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Date")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Date", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Credential")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Credential", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Security-Token")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Security-Token", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Algorithm")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Algorithm", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-SignedHeaders", valid_611914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611915: Call_DeleteApnsVoipSandboxChannel_611904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611915.validator(path, query, header, formData, body)
  let scheme = call_611915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611915.url(scheme.get, call_611915.host, call_611915.base,
                         call_611915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611915, url, valid)

proc call*(call_611916: Call_DeleteApnsVoipSandboxChannel_611904;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611917 = newJObject()
  add(path_611917, "application-id", newJString(applicationId))
  result = call_611916.call(path_611917, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_611904(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_611905, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_611906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_611918 = ref object of OpenApiRestCall_610642
proc url_GetApp_611920(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_611919(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611921 = path.getOrDefault("application-id")
  valid_611921 = validateParameter(valid_611921, JString, required = true,
                                 default = nil)
  if valid_611921 != nil:
    section.add "application-id", valid_611921
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
  var valid_611922 = header.getOrDefault("X-Amz-Signature")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Signature", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Content-Sha256", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Date")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Date", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Credential")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Credential", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Security-Token")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Security-Token", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Algorithm")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Algorithm", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-SignedHeaders", valid_611928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611929: Call_GetApp_611918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_611929.validator(path, query, header, formData, body)
  let scheme = call_611929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611929.url(scheme.get, call_611929.host, call_611929.base,
                         call_611929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611929, url, valid)

proc call*(call_611930: Call_GetApp_611918; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611931 = newJObject()
  add(path_611931, "application-id", newJString(applicationId))
  result = call_611930.call(path_611931, nil, nil, nil, nil)

var getApp* = Call_GetApp_611918(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_611919, base: "/",
                              url: url_GetApp_611920,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_611932 = ref object of OpenApiRestCall_610642
proc url_DeleteApp_611934(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_611933(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611935 = path.getOrDefault("application-id")
  valid_611935 = validateParameter(valid_611935, JString, required = true,
                                 default = nil)
  if valid_611935 != nil:
    section.add "application-id", valid_611935
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
  var valid_611936 = header.getOrDefault("X-Amz-Signature")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Signature", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Content-Sha256", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Date")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Date", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Credential")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Credential", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611943: Call_DeleteApp_611932; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_611943.validator(path, query, header, formData, body)
  let scheme = call_611943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611943.url(scheme.get, call_611943.host, call_611943.base,
                         call_611943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611943, url, valid)

proc call*(call_611944: Call_DeleteApp_611932; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611945 = newJObject()
  add(path_611945, "application-id", newJString(applicationId))
  result = call_611944.call(path_611945, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_611932(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_611933,
                                    base: "/", url: url_DeleteApp_611934,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_611960 = ref object of OpenApiRestCall_610642
proc url_UpdateBaiduChannel_611962(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_611961(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611963 = path.getOrDefault("application-id")
  valid_611963 = validateParameter(valid_611963, JString, required = true,
                                 default = nil)
  if valid_611963 != nil:
    section.add "application-id", valid_611963
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
  var valid_611964 = header.getOrDefault("X-Amz-Signature")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Signature", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-Content-Sha256", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Date")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Date", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Credential")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Credential", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Security-Token")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Security-Token", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Algorithm")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Algorithm", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-SignedHeaders", valid_611970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611972: Call_UpdateBaiduChannel_611960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_611972.validator(path, query, header, formData, body)
  let scheme = call_611972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611972.url(scheme.get, call_611972.host, call_611972.base,
                         call_611972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611972, url, valid)

proc call*(call_611973: Call_UpdateBaiduChannel_611960; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_611974 = newJObject()
  var body_611975 = newJObject()
  add(path_611974, "application-id", newJString(applicationId))
  if body != nil:
    body_611975 = body
  result = call_611973.call(path_611974, nil, nil, nil, body_611975)

var updateBaiduChannel* = Call_UpdateBaiduChannel_611960(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_611961, base: "/",
    url: url_UpdateBaiduChannel_611962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_611946 = ref object of OpenApiRestCall_610642
proc url_GetBaiduChannel_611948(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_611947(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_611949 = path.getOrDefault("application-id")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = nil)
  if valid_611949 != nil:
    section.add "application-id", valid_611949
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
  var valid_611950 = header.getOrDefault("X-Amz-Signature")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Signature", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Content-Sha256", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Date")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Date", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Credential")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Credential", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611957: Call_GetBaiduChannel_611946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_611957.validator(path, query, header, formData, body)
  let scheme = call_611957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611957.url(scheme.get, call_611957.host, call_611957.base,
                         call_611957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611957, url, valid)

proc call*(call_611958: Call_GetBaiduChannel_611946; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611959 = newJObject()
  add(path_611959, "application-id", newJString(applicationId))
  result = call_611958.call(path_611959, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_611946(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_611947, base: "/", url: url_GetBaiduChannel_611948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_611976 = ref object of OpenApiRestCall_610642
proc url_DeleteBaiduChannel_611978(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_611977(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611979 = path.getOrDefault("application-id")
  valid_611979 = validateParameter(valid_611979, JString, required = true,
                                 default = nil)
  if valid_611979 != nil:
    section.add "application-id", valid_611979
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
  var valid_611980 = header.getOrDefault("X-Amz-Signature")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Signature", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Content-Sha256", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Date")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Date", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Credential")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Credential", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Security-Token")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Security-Token", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Algorithm")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Algorithm", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-SignedHeaders", valid_611986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611987: Call_DeleteBaiduChannel_611976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_611987.validator(path, query, header, formData, body)
  let scheme = call_611987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611987.url(scheme.get, call_611987.host, call_611987.base,
                         call_611987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611987, url, valid)

proc call*(call_611988: Call_DeleteBaiduChannel_611976; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_611989 = newJObject()
  add(path_611989, "application-id", newJString(applicationId))
  result = call_611988.call(path_611989, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_611976(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_611977, base: "/",
    url: url_DeleteBaiduChannel_611978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_612005 = ref object of OpenApiRestCall_610642
proc url_UpdateCampaign_612007(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_612006(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612008 = path.getOrDefault("application-id")
  valid_612008 = validateParameter(valid_612008, JString, required = true,
                                 default = nil)
  if valid_612008 != nil:
    section.add "application-id", valid_612008
  var valid_612009 = path.getOrDefault("campaign-id")
  valid_612009 = validateParameter(valid_612009, JString, required = true,
                                 default = nil)
  if valid_612009 != nil:
    section.add "campaign-id", valid_612009
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
  var valid_612010 = header.getOrDefault("X-Amz-Signature")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Signature", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Content-Sha256", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Date")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Date", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Credential")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Credential", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Security-Token")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Security-Token", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Algorithm")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Algorithm", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-SignedHeaders", valid_612016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612018: Call_UpdateCampaign_612005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_612018.validator(path, query, header, formData, body)
  let scheme = call_612018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612018.url(scheme.get, call_612018.host, call_612018.base,
                         call_612018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612018, url, valid)

proc call*(call_612019: Call_UpdateCampaign_612005; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_612020 = newJObject()
  var body_612021 = newJObject()
  add(path_612020, "application-id", newJString(applicationId))
  if body != nil:
    body_612021 = body
  add(path_612020, "campaign-id", newJString(campaignId))
  result = call_612019.call(path_612020, nil, nil, nil, body_612021)

var updateCampaign* = Call_UpdateCampaign_612005(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_612006, base: "/", url: url_UpdateCampaign_612007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_611990 = ref object of OpenApiRestCall_610642
proc url_GetCampaign_611992(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_611991(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611993 = path.getOrDefault("application-id")
  valid_611993 = validateParameter(valid_611993, JString, required = true,
                                 default = nil)
  if valid_611993 != nil:
    section.add "application-id", valid_611993
  var valid_611994 = path.getOrDefault("campaign-id")
  valid_611994 = validateParameter(valid_611994, JString, required = true,
                                 default = nil)
  if valid_611994 != nil:
    section.add "campaign-id", valid_611994
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
  var valid_611995 = header.getOrDefault("X-Amz-Signature")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Signature", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Content-Sha256", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Date")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Date", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Credential")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Credential", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Security-Token")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Security-Token", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Algorithm")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Algorithm", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-SignedHeaders", valid_612001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612002: Call_GetCampaign_611990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_612002.validator(path, query, header, formData, body)
  let scheme = call_612002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612002.url(scheme.get, call_612002.host, call_612002.base,
                         call_612002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612002, url, valid)

proc call*(call_612003: Call_GetCampaign_611990; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_612004 = newJObject()
  add(path_612004, "application-id", newJString(applicationId))
  add(path_612004, "campaign-id", newJString(campaignId))
  result = call_612003.call(path_612004, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_611990(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_611991,
                                        base: "/", url: url_GetCampaign_611992,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_612022 = ref object of OpenApiRestCall_610642
proc url_DeleteCampaign_612024(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_612023(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612025 = path.getOrDefault("application-id")
  valid_612025 = validateParameter(valid_612025, JString, required = true,
                                 default = nil)
  if valid_612025 != nil:
    section.add "application-id", valid_612025
  var valid_612026 = path.getOrDefault("campaign-id")
  valid_612026 = validateParameter(valid_612026, JString, required = true,
                                 default = nil)
  if valid_612026 != nil:
    section.add "campaign-id", valid_612026
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
  var valid_612027 = header.getOrDefault("X-Amz-Signature")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Signature", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Content-Sha256", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Date")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Date", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Credential")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Credential", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Security-Token")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Security-Token", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Algorithm")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Algorithm", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-SignedHeaders", valid_612033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612034: Call_DeleteCampaign_612022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_612034.validator(path, query, header, formData, body)
  let scheme = call_612034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612034.url(scheme.get, call_612034.host, call_612034.base,
                         call_612034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612034, url, valid)

proc call*(call_612035: Call_DeleteCampaign_612022; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_612036 = newJObject()
  add(path_612036, "application-id", newJString(applicationId))
  add(path_612036, "campaign-id", newJString(campaignId))
  result = call_612035.call(path_612036, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_612022(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_612023, base: "/", url: url_DeleteCampaign_612024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_612051 = ref object of OpenApiRestCall_610642
proc url_UpdateEmailChannel_612053(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_612052(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612054 = path.getOrDefault("application-id")
  valid_612054 = validateParameter(valid_612054, JString, required = true,
                                 default = nil)
  if valid_612054 != nil:
    section.add "application-id", valid_612054
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
  var valid_612055 = header.getOrDefault("X-Amz-Signature")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Signature", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Content-Sha256", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Date")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Date", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Credential")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Credential", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Security-Token")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Security-Token", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Algorithm")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Algorithm", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-SignedHeaders", valid_612061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612063: Call_UpdateEmailChannel_612051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_612063.validator(path, query, header, formData, body)
  let scheme = call_612063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612063.url(scheme.get, call_612063.host, call_612063.base,
                         call_612063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612063, url, valid)

proc call*(call_612064: Call_UpdateEmailChannel_612051; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612065 = newJObject()
  var body_612066 = newJObject()
  add(path_612065, "application-id", newJString(applicationId))
  if body != nil:
    body_612066 = body
  result = call_612064.call(path_612065, nil, nil, nil, body_612066)

var updateEmailChannel* = Call_UpdateEmailChannel_612051(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_612052, base: "/",
    url: url_UpdateEmailChannel_612053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_612037 = ref object of OpenApiRestCall_610642
proc url_GetEmailChannel_612039(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_612038(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_612040 = path.getOrDefault("application-id")
  valid_612040 = validateParameter(valid_612040, JString, required = true,
                                 default = nil)
  if valid_612040 != nil:
    section.add "application-id", valid_612040
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
  var valid_612041 = header.getOrDefault("X-Amz-Signature")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Signature", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Content-Sha256", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Date")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Date", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Credential")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Credential", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Security-Token")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Security-Token", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Algorithm")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Algorithm", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-SignedHeaders", valid_612047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612048: Call_GetEmailChannel_612037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_612048.validator(path, query, header, formData, body)
  let scheme = call_612048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612048.url(scheme.get, call_612048.host, call_612048.base,
                         call_612048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612048, url, valid)

proc call*(call_612049: Call_GetEmailChannel_612037; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612050 = newJObject()
  add(path_612050, "application-id", newJString(applicationId))
  result = call_612049.call(path_612050, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_612037(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_612038, base: "/", url: url_GetEmailChannel_612039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_612067 = ref object of OpenApiRestCall_610642
proc url_DeleteEmailChannel_612069(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_612068(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612070 = path.getOrDefault("application-id")
  valid_612070 = validateParameter(valid_612070, JString, required = true,
                                 default = nil)
  if valid_612070 != nil:
    section.add "application-id", valid_612070
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
  var valid_612071 = header.getOrDefault("X-Amz-Signature")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Signature", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Content-Sha256", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-Date")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-Date", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Credential")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Credential", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Security-Token")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Security-Token", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Algorithm")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Algorithm", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-SignedHeaders", valid_612077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612078: Call_DeleteEmailChannel_612067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_612078.validator(path, query, header, formData, body)
  let scheme = call_612078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612078.url(scheme.get, call_612078.host, call_612078.base,
                         call_612078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612078, url, valid)

proc call*(call_612079: Call_DeleteEmailChannel_612067; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612080 = newJObject()
  add(path_612080, "application-id", newJString(applicationId))
  result = call_612079.call(path_612080, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_612067(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_612068, base: "/",
    url: url_DeleteEmailChannel_612069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_612096 = ref object of OpenApiRestCall_610642
proc url_UpdateEndpoint_612098(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_612097(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612099 = path.getOrDefault("application-id")
  valid_612099 = validateParameter(valid_612099, JString, required = true,
                                 default = nil)
  if valid_612099 != nil:
    section.add "application-id", valid_612099
  var valid_612100 = path.getOrDefault("endpoint-id")
  valid_612100 = validateParameter(valid_612100, JString, required = true,
                                 default = nil)
  if valid_612100 != nil:
    section.add "endpoint-id", valid_612100
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
  var valid_612101 = header.getOrDefault("X-Amz-Signature")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Signature", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Content-Sha256", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Date")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Date", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Credential")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Credential", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Security-Token")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Security-Token", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Algorithm")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Algorithm", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-SignedHeaders", valid_612107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612109: Call_UpdateEndpoint_612096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_612109.validator(path, query, header, formData, body)
  let scheme = call_612109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612109.url(scheme.get, call_612109.host, call_612109.base,
                         call_612109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612109, url, valid)

proc call*(call_612110: Call_UpdateEndpoint_612096; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_612111 = newJObject()
  var body_612112 = newJObject()
  add(path_612111, "application-id", newJString(applicationId))
  if body != nil:
    body_612112 = body
  add(path_612111, "endpoint-id", newJString(endpointId))
  result = call_612110.call(path_612111, nil, nil, nil, body_612112)

var updateEndpoint* = Call_UpdateEndpoint_612096(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_612097, base: "/", url: url_UpdateEndpoint_612098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_612081 = ref object of OpenApiRestCall_610642
proc url_GetEndpoint_612083(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_612082(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612084 = path.getOrDefault("application-id")
  valid_612084 = validateParameter(valid_612084, JString, required = true,
                                 default = nil)
  if valid_612084 != nil:
    section.add "application-id", valid_612084
  var valid_612085 = path.getOrDefault("endpoint-id")
  valid_612085 = validateParameter(valid_612085, JString, required = true,
                                 default = nil)
  if valid_612085 != nil:
    section.add "endpoint-id", valid_612085
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
  var valid_612086 = header.getOrDefault("X-Amz-Signature")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "X-Amz-Signature", valid_612086
  var valid_612087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Content-Sha256", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Date")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Date", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Credential")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Credential", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Security-Token")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Security-Token", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Algorithm")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Algorithm", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-SignedHeaders", valid_612092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612093: Call_GetEndpoint_612081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_612093.validator(path, query, header, formData, body)
  let scheme = call_612093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612093.url(scheme.get, call_612093.host, call_612093.base,
                         call_612093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612093, url, valid)

proc call*(call_612094: Call_GetEndpoint_612081; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_612095 = newJObject()
  add(path_612095, "application-id", newJString(applicationId))
  add(path_612095, "endpoint-id", newJString(endpointId))
  result = call_612094.call(path_612095, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_612081(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_612082,
                                        base: "/", url: url_GetEndpoint_612083,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_612113 = ref object of OpenApiRestCall_610642
proc url_DeleteEndpoint_612115(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_612114(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612116 = path.getOrDefault("application-id")
  valid_612116 = validateParameter(valid_612116, JString, required = true,
                                 default = nil)
  if valid_612116 != nil:
    section.add "application-id", valid_612116
  var valid_612117 = path.getOrDefault("endpoint-id")
  valid_612117 = validateParameter(valid_612117, JString, required = true,
                                 default = nil)
  if valid_612117 != nil:
    section.add "endpoint-id", valid_612117
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
  var valid_612118 = header.getOrDefault("X-Amz-Signature")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Signature", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Content-Sha256", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Date")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Date", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Credential")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Credential", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-Security-Token")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-Security-Token", valid_612122
  var valid_612123 = header.getOrDefault("X-Amz-Algorithm")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "X-Amz-Algorithm", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-SignedHeaders", valid_612124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612125: Call_DeleteEndpoint_612113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_612125.validator(path, query, header, formData, body)
  let scheme = call_612125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612125.url(scheme.get, call_612125.host, call_612125.base,
                         call_612125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612125, url, valid)

proc call*(call_612126: Call_DeleteEndpoint_612113; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_612127 = newJObject()
  add(path_612127, "application-id", newJString(applicationId))
  add(path_612127, "endpoint-id", newJString(endpointId))
  result = call_612126.call(path_612127, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_612113(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_612114, base: "/", url: url_DeleteEndpoint_612115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_612142 = ref object of OpenApiRestCall_610642
proc url_PutEventStream_612144(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_612143(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612145 = path.getOrDefault("application-id")
  valid_612145 = validateParameter(valid_612145, JString, required = true,
                                 default = nil)
  if valid_612145 != nil:
    section.add "application-id", valid_612145
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
  var valid_612146 = header.getOrDefault("X-Amz-Signature")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Signature", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Content-Sha256", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Date")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Date", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Credential")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Credential", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Security-Token")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Security-Token", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Algorithm")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Algorithm", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-SignedHeaders", valid_612152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612154: Call_PutEventStream_612142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_612154.validator(path, query, header, formData, body)
  let scheme = call_612154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612154.url(scheme.get, call_612154.host, call_612154.base,
                         call_612154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612154, url, valid)

proc call*(call_612155: Call_PutEventStream_612142; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612156 = newJObject()
  var body_612157 = newJObject()
  add(path_612156, "application-id", newJString(applicationId))
  if body != nil:
    body_612157 = body
  result = call_612155.call(path_612156, nil, nil, nil, body_612157)

var putEventStream* = Call_PutEventStream_612142(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_612143, base: "/", url: url_PutEventStream_612144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_612128 = ref object of OpenApiRestCall_610642
proc url_GetEventStream_612130(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_612129(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_612131 = path.getOrDefault("application-id")
  valid_612131 = validateParameter(valid_612131, JString, required = true,
                                 default = nil)
  if valid_612131 != nil:
    section.add "application-id", valid_612131
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
  var valid_612132 = header.getOrDefault("X-Amz-Signature")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Signature", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Content-Sha256", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Date")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Date", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Credential")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Credential", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Security-Token")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Security-Token", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Algorithm")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Algorithm", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-SignedHeaders", valid_612138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612139: Call_GetEventStream_612128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_612139.validator(path, query, header, formData, body)
  let scheme = call_612139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612139.url(scheme.get, call_612139.host, call_612139.base,
                         call_612139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612139, url, valid)

proc call*(call_612140: Call_GetEventStream_612128; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612141 = newJObject()
  add(path_612141, "application-id", newJString(applicationId))
  result = call_612140.call(path_612141, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_612128(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_612129, base: "/", url: url_GetEventStream_612130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_612158 = ref object of OpenApiRestCall_610642
proc url_DeleteEventStream_612160(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_612159(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_612161 = path.getOrDefault("application-id")
  valid_612161 = validateParameter(valid_612161, JString, required = true,
                                 default = nil)
  if valid_612161 != nil:
    section.add "application-id", valid_612161
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
  var valid_612162 = header.getOrDefault("X-Amz-Signature")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Signature", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Content-Sha256", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Date")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Date", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Credential")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Credential", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Security-Token")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Security-Token", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Algorithm")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Algorithm", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-SignedHeaders", valid_612168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612169: Call_DeleteEventStream_612158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_612169.validator(path, query, header, formData, body)
  let scheme = call_612169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612169.url(scheme.get, call_612169.host, call_612169.base,
                         call_612169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612169, url, valid)

proc call*(call_612170: Call_DeleteEventStream_612158; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612171 = newJObject()
  add(path_612171, "application-id", newJString(applicationId))
  result = call_612170.call(path_612171, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_612158(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_612159, base: "/",
    url: url_DeleteEventStream_612160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_612186 = ref object of OpenApiRestCall_610642
proc url_UpdateGcmChannel_612188(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_612187(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_612189 = path.getOrDefault("application-id")
  valid_612189 = validateParameter(valid_612189, JString, required = true,
                                 default = nil)
  if valid_612189 != nil:
    section.add "application-id", valid_612189
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
  var valid_612190 = header.getOrDefault("X-Amz-Signature")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Signature", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Content-Sha256", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Date")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Date", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Credential")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Credential", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Security-Token")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Security-Token", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Algorithm")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Algorithm", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-SignedHeaders", valid_612196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612198: Call_UpdateGcmChannel_612186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_612198.validator(path, query, header, formData, body)
  let scheme = call_612198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612198.url(scheme.get, call_612198.host, call_612198.base,
                         call_612198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612198, url, valid)

proc call*(call_612199: Call_UpdateGcmChannel_612186; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612200 = newJObject()
  var body_612201 = newJObject()
  add(path_612200, "application-id", newJString(applicationId))
  if body != nil:
    body_612201 = body
  result = call_612199.call(path_612200, nil, nil, nil, body_612201)

var updateGcmChannel* = Call_UpdateGcmChannel_612186(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_612187, base: "/",
    url: url_UpdateGcmChannel_612188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_612172 = ref object of OpenApiRestCall_610642
proc url_GetGcmChannel_612174(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_612173(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612175 = path.getOrDefault("application-id")
  valid_612175 = validateParameter(valid_612175, JString, required = true,
                                 default = nil)
  if valid_612175 != nil:
    section.add "application-id", valid_612175
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
  var valid_612176 = header.getOrDefault("X-Amz-Signature")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Signature", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Content-Sha256", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Date")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Date", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Credential")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Credential", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Security-Token")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Security-Token", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Algorithm")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Algorithm", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-SignedHeaders", valid_612182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612183: Call_GetGcmChannel_612172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_612183.validator(path, query, header, formData, body)
  let scheme = call_612183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612183.url(scheme.get, call_612183.host, call_612183.base,
                         call_612183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612183, url, valid)

proc call*(call_612184: Call_GetGcmChannel_612172; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612185 = newJObject()
  add(path_612185, "application-id", newJString(applicationId))
  result = call_612184.call(path_612185, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_612172(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_612173, base: "/", url: url_GetGcmChannel_612174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_612202 = ref object of OpenApiRestCall_610642
proc url_DeleteGcmChannel_612204(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_612203(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_612205 = path.getOrDefault("application-id")
  valid_612205 = validateParameter(valid_612205, JString, required = true,
                                 default = nil)
  if valid_612205 != nil:
    section.add "application-id", valid_612205
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
  var valid_612206 = header.getOrDefault("X-Amz-Signature")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-Signature", valid_612206
  var valid_612207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Content-Sha256", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Date")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Date", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Credential")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Credential", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Security-Token")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Security-Token", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Algorithm")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Algorithm", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-SignedHeaders", valid_612212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612213: Call_DeleteGcmChannel_612202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_612213.validator(path, query, header, formData, body)
  let scheme = call_612213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612213.url(scheme.get, call_612213.host, call_612213.base,
                         call_612213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612213, url, valid)

proc call*(call_612214: Call_DeleteGcmChannel_612202; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612215 = newJObject()
  add(path_612215, "application-id", newJString(applicationId))
  result = call_612214.call(path_612215, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_612202(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_612203, base: "/",
    url: url_DeleteGcmChannel_612204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_612231 = ref object of OpenApiRestCall_610642
proc url_UpdateJourney_612233(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_612232(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the configuration and other settings for a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612234 = path.getOrDefault("application-id")
  valid_612234 = validateParameter(valid_612234, JString, required = true,
                                 default = nil)
  if valid_612234 != nil:
    section.add "application-id", valid_612234
  var valid_612235 = path.getOrDefault("journey-id")
  valid_612235 = validateParameter(valid_612235, JString, required = true,
                                 default = nil)
  if valid_612235 != nil:
    section.add "journey-id", valid_612235
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
  var valid_612236 = header.getOrDefault("X-Amz-Signature")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-Signature", valid_612236
  var valid_612237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "X-Amz-Content-Sha256", valid_612237
  var valid_612238 = header.getOrDefault("X-Amz-Date")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "X-Amz-Date", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Credential")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Credential", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-Security-Token")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-Security-Token", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Algorithm")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Algorithm", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-SignedHeaders", valid_612242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612244: Call_UpdateJourney_612231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_612244.validator(path, query, header, formData, body)
  let scheme = call_612244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612244.url(scheme.get, call_612244.host, call_612244.base,
                         call_612244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612244, url, valid)

proc call*(call_612245: Call_UpdateJourney_612231; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_612246 = newJObject()
  var body_612247 = newJObject()
  add(path_612246, "application-id", newJString(applicationId))
  if body != nil:
    body_612247 = body
  add(path_612246, "journey-id", newJString(journeyId))
  result = call_612245.call(path_612246, nil, nil, nil, body_612247)

var updateJourney* = Call_UpdateJourney_612231(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_612232, base: "/", url: url_UpdateJourney_612233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_612216 = ref object of OpenApiRestCall_610642
proc url_GetJourney_612218(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJourney_612217(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612219 = path.getOrDefault("application-id")
  valid_612219 = validateParameter(valid_612219, JString, required = true,
                                 default = nil)
  if valid_612219 != nil:
    section.add "application-id", valid_612219
  var valid_612220 = path.getOrDefault("journey-id")
  valid_612220 = validateParameter(valid_612220, JString, required = true,
                                 default = nil)
  if valid_612220 != nil:
    section.add "journey-id", valid_612220
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
  var valid_612221 = header.getOrDefault("X-Amz-Signature")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Signature", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Content-Sha256", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Date")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Date", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Credential")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Credential", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Security-Token")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Security-Token", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Algorithm")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Algorithm", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-SignedHeaders", valid_612227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612228: Call_GetJourney_612216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_612228.validator(path, query, header, formData, body)
  let scheme = call_612228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612228.url(scheme.get, call_612228.host, call_612228.base,
                         call_612228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612228, url, valid)

proc call*(call_612229: Call_GetJourney_612216; applicationId: string;
          journeyId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_612230 = newJObject()
  add(path_612230, "application-id", newJString(applicationId))
  add(path_612230, "journey-id", newJString(journeyId))
  result = call_612229.call(path_612230, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_612216(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_612217,
                                      base: "/", url: url_GetJourney_612218,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_612248 = ref object of OpenApiRestCall_610642
proc url_DeleteJourney_612250(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_612249(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a journey from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612251 = path.getOrDefault("application-id")
  valid_612251 = validateParameter(valid_612251, JString, required = true,
                                 default = nil)
  if valid_612251 != nil:
    section.add "application-id", valid_612251
  var valid_612252 = path.getOrDefault("journey-id")
  valid_612252 = validateParameter(valid_612252, JString, required = true,
                                 default = nil)
  if valid_612252 != nil:
    section.add "journey-id", valid_612252
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
  var valid_612253 = header.getOrDefault("X-Amz-Signature")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Signature", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Content-Sha256", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Date")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Date", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Credential")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Credential", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Security-Token")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Security-Token", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Algorithm")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Algorithm", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-SignedHeaders", valid_612259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612260: Call_DeleteJourney_612248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_612260.validator(path, query, header, formData, body)
  let scheme = call_612260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612260.url(scheme.get, call_612260.host, call_612260.base,
                         call_612260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612260, url, valid)

proc call*(call_612261: Call_DeleteJourney_612248; applicationId: string;
          journeyId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_612262 = newJObject()
  add(path_612262, "application-id", newJString(applicationId))
  add(path_612262, "journey-id", newJString(journeyId))
  result = call_612261.call(path_612262, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_612248(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_612249, base: "/", url: url_DeleteJourney_612250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_612278 = ref object of OpenApiRestCall_610642
proc url_UpdateSegment_612280(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_612279(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612281 = path.getOrDefault("application-id")
  valid_612281 = validateParameter(valid_612281, JString, required = true,
                                 default = nil)
  if valid_612281 != nil:
    section.add "application-id", valid_612281
  var valid_612282 = path.getOrDefault("segment-id")
  valid_612282 = validateParameter(valid_612282, JString, required = true,
                                 default = nil)
  if valid_612282 != nil:
    section.add "segment-id", valid_612282
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
  var valid_612283 = header.getOrDefault("X-Amz-Signature")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Signature", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Content-Sha256", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Date")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Date", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Credential")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Credential", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Security-Token")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Security-Token", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Algorithm")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Algorithm", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-SignedHeaders", valid_612289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612291: Call_UpdateSegment_612278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_612291.validator(path, query, header, formData, body)
  let scheme = call_612291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612291.url(scheme.get, call_612291.host, call_612291.base,
                         call_612291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612291, url, valid)

proc call*(call_612292: Call_UpdateSegment_612278; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_612293 = newJObject()
  var body_612294 = newJObject()
  add(path_612293, "application-id", newJString(applicationId))
  add(path_612293, "segment-id", newJString(segmentId))
  if body != nil:
    body_612294 = body
  result = call_612292.call(path_612293, nil, nil, nil, body_612294)

var updateSegment* = Call_UpdateSegment_612278(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_612279, base: "/", url: url_UpdateSegment_612280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_612263 = ref object of OpenApiRestCall_610642
proc url_GetSegment_612265(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_612264(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612266 = path.getOrDefault("application-id")
  valid_612266 = validateParameter(valid_612266, JString, required = true,
                                 default = nil)
  if valid_612266 != nil:
    section.add "application-id", valid_612266
  var valid_612267 = path.getOrDefault("segment-id")
  valid_612267 = validateParameter(valid_612267, JString, required = true,
                                 default = nil)
  if valid_612267 != nil:
    section.add "segment-id", valid_612267
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
  var valid_612268 = header.getOrDefault("X-Amz-Signature")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Signature", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Content-Sha256", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Date")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Date", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Credential")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Credential", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Security-Token")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Security-Token", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Algorithm")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Algorithm", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-SignedHeaders", valid_612274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612275: Call_GetSegment_612263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_612275.validator(path, query, header, formData, body)
  let scheme = call_612275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612275.url(scheme.get, call_612275.host, call_612275.base,
                         call_612275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612275, url, valid)

proc call*(call_612276: Call_GetSegment_612263; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_612277 = newJObject()
  add(path_612277, "application-id", newJString(applicationId))
  add(path_612277, "segment-id", newJString(segmentId))
  result = call_612276.call(path_612277, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_612263(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_612264,
                                      base: "/", url: url_GetSegment_612265,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_612295 = ref object of OpenApiRestCall_610642
proc url_DeleteSegment_612297(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_612296(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612298 = path.getOrDefault("application-id")
  valid_612298 = validateParameter(valid_612298, JString, required = true,
                                 default = nil)
  if valid_612298 != nil:
    section.add "application-id", valid_612298
  var valid_612299 = path.getOrDefault("segment-id")
  valid_612299 = validateParameter(valid_612299, JString, required = true,
                                 default = nil)
  if valid_612299 != nil:
    section.add "segment-id", valid_612299
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
  var valid_612300 = header.getOrDefault("X-Amz-Signature")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Signature", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Content-Sha256", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Date")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Date", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Credential")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Credential", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Security-Token")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Security-Token", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Algorithm")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Algorithm", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-SignedHeaders", valid_612306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612307: Call_DeleteSegment_612295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_612307.validator(path, query, header, formData, body)
  let scheme = call_612307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612307.url(scheme.get, call_612307.host, call_612307.base,
                         call_612307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612307, url, valid)

proc call*(call_612308: Call_DeleteSegment_612295; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_612309 = newJObject()
  add(path_612309, "application-id", newJString(applicationId))
  add(path_612309, "segment-id", newJString(segmentId))
  result = call_612308.call(path_612309, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_612295(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_612296, base: "/", url: url_DeleteSegment_612297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_612324 = ref object of OpenApiRestCall_610642
proc url_UpdateSmsChannel_612326(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_612325(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_612327 = path.getOrDefault("application-id")
  valid_612327 = validateParameter(valid_612327, JString, required = true,
                                 default = nil)
  if valid_612327 != nil:
    section.add "application-id", valid_612327
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
  var valid_612328 = header.getOrDefault("X-Amz-Signature")
  valid_612328 = validateParameter(valid_612328, JString, required = false,
                                 default = nil)
  if valid_612328 != nil:
    section.add "X-Amz-Signature", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-Content-Sha256", valid_612329
  var valid_612330 = header.getOrDefault("X-Amz-Date")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "X-Amz-Date", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-Credential")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Credential", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-Security-Token")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Security-Token", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Algorithm")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Algorithm", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-SignedHeaders", valid_612334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612336: Call_UpdateSmsChannel_612324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_612336.validator(path, query, header, formData, body)
  let scheme = call_612336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612336.url(scheme.get, call_612336.host, call_612336.base,
                         call_612336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612336, url, valid)

proc call*(call_612337: Call_UpdateSmsChannel_612324; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612338 = newJObject()
  var body_612339 = newJObject()
  add(path_612338, "application-id", newJString(applicationId))
  if body != nil:
    body_612339 = body
  result = call_612337.call(path_612338, nil, nil, nil, body_612339)

var updateSmsChannel* = Call_UpdateSmsChannel_612324(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_612325, base: "/",
    url: url_UpdateSmsChannel_612326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_612310 = ref object of OpenApiRestCall_610642
proc url_GetSmsChannel_612312(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_612311(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612313 = path.getOrDefault("application-id")
  valid_612313 = validateParameter(valid_612313, JString, required = true,
                                 default = nil)
  if valid_612313 != nil:
    section.add "application-id", valid_612313
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
  var valid_612314 = header.getOrDefault("X-Amz-Signature")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-Signature", valid_612314
  var valid_612315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Content-Sha256", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Date")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Date", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Credential")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Credential", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Security-Token")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Security-Token", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Algorithm")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Algorithm", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-SignedHeaders", valid_612320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612321: Call_GetSmsChannel_612310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_612321.validator(path, query, header, formData, body)
  let scheme = call_612321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612321.url(scheme.get, call_612321.host, call_612321.base,
                         call_612321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612321, url, valid)

proc call*(call_612322: Call_GetSmsChannel_612310; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612323 = newJObject()
  add(path_612323, "application-id", newJString(applicationId))
  result = call_612322.call(path_612323, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_612310(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_612311, base: "/", url: url_GetSmsChannel_612312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_612340 = ref object of OpenApiRestCall_610642
proc url_DeleteSmsChannel_612342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_612341(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_612343 = path.getOrDefault("application-id")
  valid_612343 = validateParameter(valid_612343, JString, required = true,
                                 default = nil)
  if valid_612343 != nil:
    section.add "application-id", valid_612343
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
  var valid_612344 = header.getOrDefault("X-Amz-Signature")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-Signature", valid_612344
  var valid_612345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "X-Amz-Content-Sha256", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Date")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Date", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Credential")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Credential", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Security-Token")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Security-Token", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Algorithm")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Algorithm", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-SignedHeaders", valid_612350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612351: Call_DeleteSmsChannel_612340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_612351.validator(path, query, header, formData, body)
  let scheme = call_612351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612351.url(scheme.get, call_612351.host, call_612351.base,
                         call_612351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612351, url, valid)

proc call*(call_612352: Call_DeleteSmsChannel_612340; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612353 = newJObject()
  add(path_612353, "application-id", newJString(applicationId))
  result = call_612352.call(path_612353, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_612340(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_612341, base: "/",
    url: url_DeleteSmsChannel_612342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_612354 = ref object of OpenApiRestCall_610642
proc url_GetUserEndpoints_612356(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_612355(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   user-id: JString (required)
  ##          : The unique identifier for the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612357 = path.getOrDefault("application-id")
  valid_612357 = validateParameter(valid_612357, JString, required = true,
                                 default = nil)
  if valid_612357 != nil:
    section.add "application-id", valid_612357
  var valid_612358 = path.getOrDefault("user-id")
  valid_612358 = validateParameter(valid_612358, JString, required = true,
                                 default = nil)
  if valid_612358 != nil:
    section.add "user-id", valid_612358
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
  var valid_612359 = header.getOrDefault("X-Amz-Signature")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "X-Amz-Signature", valid_612359
  var valid_612360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612360 = validateParameter(valid_612360, JString, required = false,
                                 default = nil)
  if valid_612360 != nil:
    section.add "X-Amz-Content-Sha256", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Date")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Date", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Credential")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Credential", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Security-Token")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Security-Token", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Algorithm")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Algorithm", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-SignedHeaders", valid_612365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612366: Call_GetUserEndpoints_612354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_612366.validator(path, query, header, formData, body)
  let scheme = call_612366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612366.url(scheme.get, call_612366.host, call_612366.base,
                         call_612366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612366, url, valid)

proc call*(call_612367: Call_GetUserEndpoints_612354; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_612368 = newJObject()
  add(path_612368, "application-id", newJString(applicationId))
  add(path_612368, "user-id", newJString(userId))
  result = call_612367.call(path_612368, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_612354(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_612355, base: "/",
    url: url_GetUserEndpoints_612356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_612369 = ref object of OpenApiRestCall_610642
proc url_DeleteUserEndpoints_612371(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_612370(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   user-id: JString (required)
  ##          : The unique identifier for the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612372 = path.getOrDefault("application-id")
  valid_612372 = validateParameter(valid_612372, JString, required = true,
                                 default = nil)
  if valid_612372 != nil:
    section.add "application-id", valid_612372
  var valid_612373 = path.getOrDefault("user-id")
  valid_612373 = validateParameter(valid_612373, JString, required = true,
                                 default = nil)
  if valid_612373 != nil:
    section.add "user-id", valid_612373
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
  var valid_612374 = header.getOrDefault("X-Amz-Signature")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Signature", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-Content-Sha256", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-Date")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-Date", valid_612376
  var valid_612377 = header.getOrDefault("X-Amz-Credential")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "X-Amz-Credential", valid_612377
  var valid_612378 = header.getOrDefault("X-Amz-Security-Token")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "X-Amz-Security-Token", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Algorithm")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Algorithm", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-SignedHeaders", valid_612380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612381: Call_DeleteUserEndpoints_612369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_612381.validator(path, query, header, formData, body)
  let scheme = call_612381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612381.url(scheme.get, call_612381.host, call_612381.base,
                         call_612381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612381, url, valid)

proc call*(call_612382: Call_DeleteUserEndpoints_612369; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_612383 = newJObject()
  add(path_612383, "application-id", newJString(applicationId))
  add(path_612383, "user-id", newJString(userId))
  result = call_612382.call(path_612383, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_612369(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_612370, base: "/",
    url: url_DeleteUserEndpoints_612371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_612398 = ref object of OpenApiRestCall_610642
proc url_UpdateVoiceChannel_612400(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_612399(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612401 = path.getOrDefault("application-id")
  valid_612401 = validateParameter(valid_612401, JString, required = true,
                                 default = nil)
  if valid_612401 != nil:
    section.add "application-id", valid_612401
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
  var valid_612402 = header.getOrDefault("X-Amz-Signature")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Signature", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Content-Sha256", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Date")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Date", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Credential")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Credential", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Security-Token")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Security-Token", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Algorithm")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Algorithm", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-SignedHeaders", valid_612408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612410: Call_UpdateVoiceChannel_612398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_612410.validator(path, query, header, formData, body)
  let scheme = call_612410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612410.url(scheme.get, call_612410.host, call_612410.base,
                         call_612410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612410, url, valid)

proc call*(call_612411: Call_UpdateVoiceChannel_612398; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612412 = newJObject()
  var body_612413 = newJObject()
  add(path_612412, "application-id", newJString(applicationId))
  if body != nil:
    body_612413 = body
  result = call_612411.call(path_612412, nil, nil, nil, body_612413)

var updateVoiceChannel* = Call_UpdateVoiceChannel_612398(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_612399, base: "/",
    url: url_UpdateVoiceChannel_612400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_612384 = ref object of OpenApiRestCall_610642
proc url_GetVoiceChannel_612386(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_612385(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_612387 = path.getOrDefault("application-id")
  valid_612387 = validateParameter(valid_612387, JString, required = true,
                                 default = nil)
  if valid_612387 != nil:
    section.add "application-id", valid_612387
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
  var valid_612388 = header.getOrDefault("X-Amz-Signature")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Signature", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Content-Sha256", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Date")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Date", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Credential")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Credential", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-Security-Token")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-Security-Token", valid_612392
  var valid_612393 = header.getOrDefault("X-Amz-Algorithm")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Algorithm", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-SignedHeaders", valid_612394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612395: Call_GetVoiceChannel_612384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_612395.validator(path, query, header, formData, body)
  let scheme = call_612395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612395.url(scheme.get, call_612395.host, call_612395.base,
                         call_612395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612395, url, valid)

proc call*(call_612396: Call_GetVoiceChannel_612384; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612397 = newJObject()
  add(path_612397, "application-id", newJString(applicationId))
  result = call_612396.call(path_612397, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_612384(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_612385, base: "/", url: url_GetVoiceChannel_612386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_612414 = ref object of OpenApiRestCall_610642
proc url_DeleteVoiceChannel_612416(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_612415(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612417 = path.getOrDefault("application-id")
  valid_612417 = validateParameter(valid_612417, JString, required = true,
                                 default = nil)
  if valid_612417 != nil:
    section.add "application-id", valid_612417
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
  var valid_612418 = header.getOrDefault("X-Amz-Signature")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Signature", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Content-Sha256", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Date")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Date", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Credential")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Credential", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Security-Token")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Security-Token", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Algorithm")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Algorithm", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-SignedHeaders", valid_612424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612425: Call_DeleteVoiceChannel_612414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_612425.validator(path, query, header, formData, body)
  let scheme = call_612425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612425.url(scheme.get, call_612425.host, call_612425.base,
                         call_612425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612425, url, valid)

proc call*(call_612426: Call_DeleteVoiceChannel_612414; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612427 = newJObject()
  add(path_612427, "application-id", newJString(applicationId))
  result = call_612426.call(path_612427, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_612414(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_612415, base: "/",
    url: url_DeleteVoiceChannel_612416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_612428 = ref object of OpenApiRestCall_610642
proc url_GetApplicationDateRangeKpi_612430(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_612429(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `kpi-name` field"
  var valid_612431 = path.getOrDefault("kpi-name")
  valid_612431 = validateParameter(valid_612431, JString, required = true,
                                 default = nil)
  if valid_612431 != nil:
    section.add "kpi-name", valid_612431
  var valid_612432 = path.getOrDefault("application-id")
  valid_612432 = validateParameter(valid_612432, JString, required = true,
                                 default = nil)
  if valid_612432 != nil:
    section.add "application-id", valid_612432
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612433 = query.getOrDefault("end-time")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "end-time", valid_612433
  var valid_612434 = query.getOrDefault("page-size")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "page-size", valid_612434
  var valid_612435 = query.getOrDefault("start-time")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "start-time", valid_612435
  var valid_612436 = query.getOrDefault("next-token")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "next-token", valid_612436
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
  var valid_612437 = header.getOrDefault("X-Amz-Signature")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Signature", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Content-Sha256", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Date")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Date", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Credential")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Credential", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Security-Token")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Security-Token", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Algorithm")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Algorithm", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-SignedHeaders", valid_612443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612444: Call_GetApplicationDateRangeKpi_612428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_612444.validator(path, query, header, formData, body)
  let scheme = call_612444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612444.url(scheme.get, call_612444.host, call_612444.base,
                         call_612444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612444, url, valid)

proc call*(call_612445: Call_GetApplicationDateRangeKpi_612428; kpiName: string;
          applicationId: string; endTime: string = ""; pageSize: string = "";
          startTime: string = ""; nextToken: string = ""): Recallable =
  ## getApplicationDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612446 = newJObject()
  var query_612447 = newJObject()
  add(path_612446, "kpi-name", newJString(kpiName))
  add(path_612446, "application-id", newJString(applicationId))
  add(query_612447, "end-time", newJString(endTime))
  add(query_612447, "page-size", newJString(pageSize))
  add(query_612447, "start-time", newJString(startTime))
  add(query_612447, "next-token", newJString(nextToken))
  result = call_612445.call(path_612446, query_612447, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_612428(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_612429, base: "/",
    url: url_GetApplicationDateRangeKpi_612430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_612462 = ref object of OpenApiRestCall_610642
proc url_UpdateApplicationSettings_612464(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_612463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612465 = path.getOrDefault("application-id")
  valid_612465 = validateParameter(valid_612465, JString, required = true,
                                 default = nil)
  if valid_612465 != nil:
    section.add "application-id", valid_612465
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
  var valid_612466 = header.getOrDefault("X-Amz-Signature")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "X-Amz-Signature", valid_612466
  var valid_612467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Content-Sha256", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Date")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Date", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Credential")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Credential", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Security-Token")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Security-Token", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Algorithm")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Algorithm", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-SignedHeaders", valid_612472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612474: Call_UpdateApplicationSettings_612462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_612474.validator(path, query, header, formData, body)
  let scheme = call_612474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612474.url(scheme.get, call_612474.host, call_612474.base,
                         call_612474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612474, url, valid)

proc call*(call_612475: Call_UpdateApplicationSettings_612462;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612476 = newJObject()
  var body_612477 = newJObject()
  add(path_612476, "application-id", newJString(applicationId))
  if body != nil:
    body_612477 = body
  result = call_612475.call(path_612476, nil, nil, nil, body_612477)

var updateApplicationSettings* = Call_UpdateApplicationSettings_612462(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_612463, base: "/",
    url: url_UpdateApplicationSettings_612464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_612448 = ref object of OpenApiRestCall_610642
proc url_GetApplicationSettings_612450(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_612449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612451 = path.getOrDefault("application-id")
  valid_612451 = validateParameter(valid_612451, JString, required = true,
                                 default = nil)
  if valid_612451 != nil:
    section.add "application-id", valid_612451
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
  var valid_612452 = header.getOrDefault("X-Amz-Signature")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Signature", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Content-Sha256", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Date")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Date", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Credential")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Credential", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Security-Token")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Security-Token", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Algorithm")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Algorithm", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-SignedHeaders", valid_612458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612459: Call_GetApplicationSettings_612448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_612459.validator(path, query, header, formData, body)
  let scheme = call_612459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612459.url(scheme.get, call_612459.host, call_612459.base,
                         call_612459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612459, url, valid)

proc call*(call_612460: Call_GetApplicationSettings_612448; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612461 = newJObject()
  add(path_612461, "application-id", newJString(applicationId))
  result = call_612460.call(path_612461, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_612448(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_612449, base: "/",
    url: url_GetApplicationSettings_612450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_612478 = ref object of OpenApiRestCall_610642
proc url_GetCampaignActivities_612480(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_612479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612481 = path.getOrDefault("application-id")
  valid_612481 = validateParameter(valid_612481, JString, required = true,
                                 default = nil)
  if valid_612481 != nil:
    section.add "application-id", valid_612481
  var valid_612482 = path.getOrDefault("campaign-id")
  valid_612482 = validateParameter(valid_612482, JString, required = true,
                                 default = nil)
  if valid_612482 != nil:
    section.add "campaign-id", valid_612482
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_612483 = query.getOrDefault("page-size")
  valid_612483 = validateParameter(valid_612483, JString, required = false,
                                 default = nil)
  if valid_612483 != nil:
    section.add "page-size", valid_612483
  var valid_612484 = query.getOrDefault("token")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "token", valid_612484
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
  var valid_612485 = header.getOrDefault("X-Amz-Signature")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "X-Amz-Signature", valid_612485
  var valid_612486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Content-Sha256", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Date")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Date", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Credential")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Credential", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Security-Token")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Security-Token", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Algorithm")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Algorithm", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-SignedHeaders", valid_612491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612492: Call_GetCampaignActivities_612478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_612492.validator(path, query, header, formData, body)
  let scheme = call_612492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612492.url(scheme.get, call_612492.host, call_612492.base,
                         call_612492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612492, url, valid)

proc call*(call_612493: Call_GetCampaignActivities_612478; applicationId: string;
          campaignId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaignActivities
  ## Retrieves information about all the activities for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_612494 = newJObject()
  var query_612495 = newJObject()
  add(path_612494, "application-id", newJString(applicationId))
  add(query_612495, "page-size", newJString(pageSize))
  add(path_612494, "campaign-id", newJString(campaignId))
  add(query_612495, "token", newJString(token))
  result = call_612493.call(path_612494, query_612495, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_612478(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_612479, base: "/",
    url: url_GetCampaignActivities_612480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_612496 = ref object of OpenApiRestCall_610642
proc url_GetCampaignDateRangeKpi_612498(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_612497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `kpi-name` field"
  var valid_612499 = path.getOrDefault("kpi-name")
  valid_612499 = validateParameter(valid_612499, JString, required = true,
                                 default = nil)
  if valid_612499 != nil:
    section.add "kpi-name", valid_612499
  var valid_612500 = path.getOrDefault("application-id")
  valid_612500 = validateParameter(valid_612500, JString, required = true,
                                 default = nil)
  if valid_612500 != nil:
    section.add "application-id", valid_612500
  var valid_612501 = path.getOrDefault("campaign-id")
  valid_612501 = validateParameter(valid_612501, JString, required = true,
                                 default = nil)
  if valid_612501 != nil:
    section.add "campaign-id", valid_612501
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612502 = query.getOrDefault("end-time")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "end-time", valid_612502
  var valid_612503 = query.getOrDefault("page-size")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "page-size", valid_612503
  var valid_612504 = query.getOrDefault("start-time")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "start-time", valid_612504
  var valid_612505 = query.getOrDefault("next-token")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "next-token", valid_612505
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
  var valid_612506 = header.getOrDefault("X-Amz-Signature")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Signature", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Content-Sha256", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Date")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Date", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Credential")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Credential", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Security-Token")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Security-Token", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Algorithm")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Algorithm", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-SignedHeaders", valid_612512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612513: Call_GetCampaignDateRangeKpi_612496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_612513.validator(path, query, header, formData, body)
  let scheme = call_612513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612513.url(scheme.get, call_612513.host, call_612513.base,
                         call_612513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612513, url, valid)

proc call*(call_612514: Call_GetCampaignDateRangeKpi_612496; kpiName: string;
          applicationId: string; campaignId: string; endTime: string = "";
          pageSize: string = ""; startTime: string = ""; nextToken: string = ""): Recallable =
  ## getCampaignDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612515 = newJObject()
  var query_612516 = newJObject()
  add(path_612515, "kpi-name", newJString(kpiName))
  add(path_612515, "application-id", newJString(applicationId))
  add(query_612516, "end-time", newJString(endTime))
  add(query_612516, "page-size", newJString(pageSize))
  add(path_612515, "campaign-id", newJString(campaignId))
  add(query_612516, "start-time", newJString(startTime))
  add(query_612516, "next-token", newJString(nextToken))
  result = call_612514.call(path_612515, query_612516, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_612496(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_612497, base: "/",
    url: url_GetCampaignDateRangeKpi_612498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_612517 = ref object of OpenApiRestCall_610642
proc url_GetCampaignVersion_612519(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_612518(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612520 = path.getOrDefault("version")
  valid_612520 = validateParameter(valid_612520, JString, required = true,
                                 default = nil)
  if valid_612520 != nil:
    section.add "version", valid_612520
  var valid_612521 = path.getOrDefault("application-id")
  valid_612521 = validateParameter(valid_612521, JString, required = true,
                                 default = nil)
  if valid_612521 != nil:
    section.add "application-id", valid_612521
  var valid_612522 = path.getOrDefault("campaign-id")
  valid_612522 = validateParameter(valid_612522, JString, required = true,
                                 default = nil)
  if valid_612522 != nil:
    section.add "campaign-id", valid_612522
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
  var valid_612523 = header.getOrDefault("X-Amz-Signature")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Signature", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Content-Sha256", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Date")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Date", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Credential")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Credential", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Security-Token")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Security-Token", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-Algorithm")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-Algorithm", valid_612528
  var valid_612529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-SignedHeaders", valid_612529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612530: Call_GetCampaignVersion_612517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_612530.validator(path, query, header, formData, body)
  let scheme = call_612530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612530.url(scheme.get, call_612530.host, call_612530.base,
                         call_612530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612530, url, valid)

proc call*(call_612531: Call_GetCampaignVersion_612517; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_612532 = newJObject()
  add(path_612532, "version", newJString(version))
  add(path_612532, "application-id", newJString(applicationId))
  add(path_612532, "campaign-id", newJString(campaignId))
  result = call_612531.call(path_612532, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_612517(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_612518, base: "/",
    url: url_GetCampaignVersion_612519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_612533 = ref object of OpenApiRestCall_610642
proc url_GetCampaignVersions_612535(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_612534(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_612536 = path.getOrDefault("application-id")
  valid_612536 = validateParameter(valid_612536, JString, required = true,
                                 default = nil)
  if valid_612536 != nil:
    section.add "application-id", valid_612536
  var valid_612537 = path.getOrDefault("campaign-id")
  valid_612537 = validateParameter(valid_612537, JString, required = true,
                                 default = nil)
  if valid_612537 != nil:
    section.add "campaign-id", valid_612537
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_612538 = query.getOrDefault("page-size")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "page-size", valid_612538
  var valid_612539 = query.getOrDefault("token")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "token", valid_612539
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
  var valid_612540 = header.getOrDefault("X-Amz-Signature")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Signature", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Content-Sha256", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Date")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Date", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Credential")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Credential", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Security-Token")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Security-Token", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-Algorithm")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-Algorithm", valid_612545
  var valid_612546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-SignedHeaders", valid_612546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612547: Call_GetCampaignVersions_612533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_612547.validator(path, query, header, formData, body)
  let scheme = call_612547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612547.url(scheme.get, call_612547.host, call_612547.base,
                         call_612547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612547, url, valid)

proc call*(call_612548: Call_GetCampaignVersions_612533; applicationId: string;
          campaignId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaignVersions
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_612549 = newJObject()
  var query_612550 = newJObject()
  add(path_612549, "application-id", newJString(applicationId))
  add(query_612550, "page-size", newJString(pageSize))
  add(path_612549, "campaign-id", newJString(campaignId))
  add(query_612550, "token", newJString(token))
  result = call_612548.call(path_612549, query_612550, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_612533(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_612534, base: "/",
    url: url_GetCampaignVersions_612535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_612551 = ref object of OpenApiRestCall_610642
proc url_GetChannels_612553(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_612552(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612554 = path.getOrDefault("application-id")
  valid_612554 = validateParameter(valid_612554, JString, required = true,
                                 default = nil)
  if valid_612554 != nil:
    section.add "application-id", valid_612554
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
  var valid_612555 = header.getOrDefault("X-Amz-Signature")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Signature", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Content-Sha256", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-Date")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-Date", valid_612557
  var valid_612558 = header.getOrDefault("X-Amz-Credential")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Credential", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Security-Token")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Security-Token", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-Algorithm")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-Algorithm", valid_612560
  var valid_612561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-SignedHeaders", valid_612561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612562: Call_GetChannels_612551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_612562.validator(path, query, header, formData, body)
  let scheme = call_612562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612562.url(scheme.get, call_612562.host, call_612562.base,
                         call_612562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612562, url, valid)

proc call*(call_612563: Call_GetChannels_612551; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612564 = newJObject()
  add(path_612564, "application-id", newJString(applicationId))
  result = call_612563.call(path_612564, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_612551(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_612552,
                                        base: "/", url: url_GetChannels_612553,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_612565 = ref object of OpenApiRestCall_610642
proc url_GetExportJob_612567(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_612566(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   job-id: JString (required)
  ##         : The unique identifier for the job.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `job-id` field"
  var valid_612568 = path.getOrDefault("job-id")
  valid_612568 = validateParameter(valid_612568, JString, required = true,
                                 default = nil)
  if valid_612568 != nil:
    section.add "job-id", valid_612568
  var valid_612569 = path.getOrDefault("application-id")
  valid_612569 = validateParameter(valid_612569, JString, required = true,
                                 default = nil)
  if valid_612569 != nil:
    section.add "application-id", valid_612569
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
  var valid_612570 = header.getOrDefault("X-Amz-Signature")
  valid_612570 = validateParameter(valid_612570, JString, required = false,
                                 default = nil)
  if valid_612570 != nil:
    section.add "X-Amz-Signature", valid_612570
  var valid_612571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "X-Amz-Content-Sha256", valid_612571
  var valid_612572 = header.getOrDefault("X-Amz-Date")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "X-Amz-Date", valid_612572
  var valid_612573 = header.getOrDefault("X-Amz-Credential")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "X-Amz-Credential", valid_612573
  var valid_612574 = header.getOrDefault("X-Amz-Security-Token")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "X-Amz-Security-Token", valid_612574
  var valid_612575 = header.getOrDefault("X-Amz-Algorithm")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-Algorithm", valid_612575
  var valid_612576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612576 = validateParameter(valid_612576, JString, required = false,
                                 default = nil)
  if valid_612576 != nil:
    section.add "X-Amz-SignedHeaders", valid_612576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612577: Call_GetExportJob_612565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_612577.validator(path, query, header, formData, body)
  let scheme = call_612577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612577.url(scheme.get, call_612577.host, call_612577.base,
                         call_612577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612577, url, valid)

proc call*(call_612578: Call_GetExportJob_612565; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612579 = newJObject()
  add(path_612579, "job-id", newJString(jobId))
  add(path_612579, "application-id", newJString(applicationId))
  result = call_612578.call(path_612579, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_612565(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_612566, base: "/", url: url_GetExportJob_612567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_612580 = ref object of OpenApiRestCall_610642
proc url_GetImportJob_612582(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_612581(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   job-id: JString (required)
  ##         : The unique identifier for the job.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `job-id` field"
  var valid_612583 = path.getOrDefault("job-id")
  valid_612583 = validateParameter(valid_612583, JString, required = true,
                                 default = nil)
  if valid_612583 != nil:
    section.add "job-id", valid_612583
  var valid_612584 = path.getOrDefault("application-id")
  valid_612584 = validateParameter(valid_612584, JString, required = true,
                                 default = nil)
  if valid_612584 != nil:
    section.add "application-id", valid_612584
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
  var valid_612585 = header.getOrDefault("X-Amz-Signature")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Signature", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Content-Sha256", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-Date")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Date", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Credential")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Credential", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Security-Token")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Security-Token", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-Algorithm")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-Algorithm", valid_612590
  var valid_612591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612591 = validateParameter(valid_612591, JString, required = false,
                                 default = nil)
  if valid_612591 != nil:
    section.add "X-Amz-SignedHeaders", valid_612591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612592: Call_GetImportJob_612580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_612592.validator(path, query, header, formData, body)
  let scheme = call_612592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612592.url(scheme.get, call_612592.host, call_612592.base,
                         call_612592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612592, url, valid)

proc call*(call_612593: Call_GetImportJob_612580; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_612594 = newJObject()
  add(path_612594, "job-id", newJString(jobId))
  add(path_612594, "application-id", newJString(applicationId))
  result = call_612593.call(path_612594, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_612580(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_612581, base: "/", url: url_GetImportJob_612582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_612595 = ref object of OpenApiRestCall_610642
proc url_GetJourneyDateRangeKpi_612597(protocol: Scheme; host: string; base: string;
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

proc validate_GetJourneyDateRangeKpi_612596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `kpi-name` field"
  var valid_612598 = path.getOrDefault("kpi-name")
  valid_612598 = validateParameter(valid_612598, JString, required = true,
                                 default = nil)
  if valid_612598 != nil:
    section.add "kpi-name", valid_612598
  var valid_612599 = path.getOrDefault("application-id")
  valid_612599 = validateParameter(valid_612599, JString, required = true,
                                 default = nil)
  if valid_612599 != nil:
    section.add "application-id", valid_612599
  var valid_612600 = path.getOrDefault("journey-id")
  valid_612600 = validateParameter(valid_612600, JString, required = true,
                                 default = nil)
  if valid_612600 != nil:
    section.add "journey-id", valid_612600
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612601 = query.getOrDefault("end-time")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "end-time", valid_612601
  var valid_612602 = query.getOrDefault("page-size")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "page-size", valid_612602
  var valid_612603 = query.getOrDefault("start-time")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "start-time", valid_612603
  var valid_612604 = query.getOrDefault("next-token")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "next-token", valid_612604
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
  var valid_612605 = header.getOrDefault("X-Amz-Signature")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-Signature", valid_612605
  var valid_612606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "X-Amz-Content-Sha256", valid_612606
  var valid_612607 = header.getOrDefault("X-Amz-Date")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Date", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-Credential")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-Credential", valid_612608
  var valid_612609 = header.getOrDefault("X-Amz-Security-Token")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "X-Amz-Security-Token", valid_612609
  var valid_612610 = header.getOrDefault("X-Amz-Algorithm")
  valid_612610 = validateParameter(valid_612610, JString, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "X-Amz-Algorithm", valid_612610
  var valid_612611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "X-Amz-SignedHeaders", valid_612611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612612: Call_GetJourneyDateRangeKpi_612595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_612612.validator(path, query, header, formData, body)
  let scheme = call_612612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612612.url(scheme.get, call_612612.host, call_612612.base,
                         call_612612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612612, url, valid)

proc call*(call_612613: Call_GetJourneyDateRangeKpi_612595; kpiName: string;
          applicationId: string; journeyId: string; endTime: string = "";
          pageSize: string = ""; startTime: string = ""; nextToken: string = ""): Recallable =
  ## getJourneyDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a 
  ## href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612614 = newJObject()
  var query_612615 = newJObject()
  add(path_612614, "kpi-name", newJString(kpiName))
  add(path_612614, "application-id", newJString(applicationId))
  add(query_612615, "end-time", newJString(endTime))
  add(query_612615, "page-size", newJString(pageSize))
  add(path_612614, "journey-id", newJString(journeyId))
  add(query_612615, "start-time", newJString(startTime))
  add(query_612615, "next-token", newJString(nextToken))
  result = call_612613.call(path_612614, query_612615, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_612595(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_612596, base: "/",
    url: url_GetJourneyDateRangeKpi_612597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_612616 = ref object of OpenApiRestCall_610642
proc url_GetJourneyExecutionActivityMetrics_612618(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionActivityMetrics_612617(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-activity-id: JString (required)
  ##                      : The unique identifier for the journey activity.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612619 = path.getOrDefault("application-id")
  valid_612619 = validateParameter(valid_612619, JString, required = true,
                                 default = nil)
  if valid_612619 != nil:
    section.add "application-id", valid_612619
  var valid_612620 = path.getOrDefault("journey-activity-id")
  valid_612620 = validateParameter(valid_612620, JString, required = true,
                                 default = nil)
  if valid_612620 != nil:
    section.add "journey-activity-id", valid_612620
  var valid_612621 = path.getOrDefault("journey-id")
  valid_612621 = validateParameter(valid_612621, JString, required = true,
                                 default = nil)
  if valid_612621 != nil:
    section.add "journey-id", valid_612621
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612622 = query.getOrDefault("page-size")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "page-size", valid_612622
  var valid_612623 = query.getOrDefault("next-token")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "next-token", valid_612623
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
  var valid_612624 = header.getOrDefault("X-Amz-Signature")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-Signature", valid_612624
  var valid_612625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "X-Amz-Content-Sha256", valid_612625
  var valid_612626 = header.getOrDefault("X-Amz-Date")
  valid_612626 = validateParameter(valid_612626, JString, required = false,
                                 default = nil)
  if valid_612626 != nil:
    section.add "X-Amz-Date", valid_612626
  var valid_612627 = header.getOrDefault("X-Amz-Credential")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "X-Amz-Credential", valid_612627
  var valid_612628 = header.getOrDefault("X-Amz-Security-Token")
  valid_612628 = validateParameter(valid_612628, JString, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "X-Amz-Security-Token", valid_612628
  var valid_612629 = header.getOrDefault("X-Amz-Algorithm")
  valid_612629 = validateParameter(valid_612629, JString, required = false,
                                 default = nil)
  if valid_612629 != nil:
    section.add "X-Amz-Algorithm", valid_612629
  var valid_612630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612630 = validateParameter(valid_612630, JString, required = false,
                                 default = nil)
  if valid_612630 != nil:
    section.add "X-Amz-SignedHeaders", valid_612630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612631: Call_GetJourneyExecutionActivityMetrics_612616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_612631.validator(path, query, header, formData, body)
  let scheme = call_612631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612631.url(scheme.get, call_612631.host, call_612631.base,
                         call_612631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612631, url, valid)

proc call*(call_612632: Call_GetJourneyExecutionActivityMetrics_612616;
          applicationId: string; journeyActivityId: string; journeyId: string;
          pageSize: string = ""; nextToken: string = ""): Recallable =
  ## getJourneyExecutionActivityMetrics
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   journeyActivityId: string (required)
  ##                    : The unique identifier for the journey activity.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612633 = newJObject()
  var query_612634 = newJObject()
  add(path_612633, "application-id", newJString(applicationId))
  add(query_612634, "page-size", newJString(pageSize))
  add(path_612633, "journey-activity-id", newJString(journeyActivityId))
  add(path_612633, "journey-id", newJString(journeyId))
  add(query_612634, "next-token", newJString(nextToken))
  result = call_612632.call(path_612633, query_612634, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_612616(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_612617, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_612618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_612635 = ref object of OpenApiRestCall_610642
proc url_GetJourneyExecutionMetrics_612637(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_612636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612638 = path.getOrDefault("application-id")
  valid_612638 = validateParameter(valid_612638, JString, required = true,
                                 default = nil)
  if valid_612638 != nil:
    section.add "application-id", valid_612638
  var valid_612639 = path.getOrDefault("journey-id")
  valid_612639 = validateParameter(valid_612639, JString, required = true,
                                 default = nil)
  if valid_612639 != nil:
    section.add "journey-id", valid_612639
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612640 = query.getOrDefault("page-size")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "page-size", valid_612640
  var valid_612641 = query.getOrDefault("next-token")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = nil)
  if valid_612641 != nil:
    section.add "next-token", valid_612641
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
  var valid_612642 = header.getOrDefault("X-Amz-Signature")
  valid_612642 = validateParameter(valid_612642, JString, required = false,
                                 default = nil)
  if valid_612642 != nil:
    section.add "X-Amz-Signature", valid_612642
  var valid_612643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612643 = validateParameter(valid_612643, JString, required = false,
                                 default = nil)
  if valid_612643 != nil:
    section.add "X-Amz-Content-Sha256", valid_612643
  var valid_612644 = header.getOrDefault("X-Amz-Date")
  valid_612644 = validateParameter(valid_612644, JString, required = false,
                                 default = nil)
  if valid_612644 != nil:
    section.add "X-Amz-Date", valid_612644
  var valid_612645 = header.getOrDefault("X-Amz-Credential")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "X-Amz-Credential", valid_612645
  var valid_612646 = header.getOrDefault("X-Amz-Security-Token")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "X-Amz-Security-Token", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Algorithm")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Algorithm", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-SignedHeaders", valid_612648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612649: Call_GetJourneyExecutionMetrics_612635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_612649.validator(path, query, header, formData, body)
  let scheme = call_612649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612649.url(scheme.get, call_612649.host, call_612649.base,
                         call_612649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612649, url, valid)

proc call*(call_612650: Call_GetJourneyExecutionMetrics_612635;
          applicationId: string; journeyId: string; pageSize: string = "";
          nextToken: string = ""): Recallable =
  ## getJourneyExecutionMetrics
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612651 = newJObject()
  var query_612652 = newJObject()
  add(path_612651, "application-id", newJString(applicationId))
  add(query_612652, "page-size", newJString(pageSize))
  add(path_612651, "journey-id", newJString(journeyId))
  add(query_612652, "next-token", newJString(nextToken))
  result = call_612650.call(path_612651, query_612652, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_612635(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_612636, base: "/",
    url: url_GetJourneyExecutionMetrics_612637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_612653 = ref object of OpenApiRestCall_610642
proc url_GetSegmentExportJobs_612655(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_612654(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612656 = path.getOrDefault("application-id")
  valid_612656 = validateParameter(valid_612656, JString, required = true,
                                 default = nil)
  if valid_612656 != nil:
    section.add "application-id", valid_612656
  var valid_612657 = path.getOrDefault("segment-id")
  valid_612657 = validateParameter(valid_612657, JString, required = true,
                                 default = nil)
  if valid_612657 != nil:
    section.add "segment-id", valid_612657
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_612658 = query.getOrDefault("page-size")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "page-size", valid_612658
  var valid_612659 = query.getOrDefault("token")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "token", valid_612659
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
  var valid_612660 = header.getOrDefault("X-Amz-Signature")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Signature", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Content-Sha256", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Date")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Date", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-Credential")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-Credential", valid_612663
  var valid_612664 = header.getOrDefault("X-Amz-Security-Token")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "X-Amz-Security-Token", valid_612664
  var valid_612665 = header.getOrDefault("X-Amz-Algorithm")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "X-Amz-Algorithm", valid_612665
  var valid_612666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612666 = validateParameter(valid_612666, JString, required = false,
                                 default = nil)
  if valid_612666 != nil:
    section.add "X-Amz-SignedHeaders", valid_612666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612667: Call_GetSegmentExportJobs_612653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_612667.validator(path, query, header, formData, body)
  let scheme = call_612667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612667.url(scheme.get, call_612667.host, call_612667.base,
                         call_612667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612667, url, valid)

proc call*(call_612668: Call_GetSegmentExportJobs_612653; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentExportJobs
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_612669 = newJObject()
  var query_612670 = newJObject()
  add(path_612669, "application-id", newJString(applicationId))
  add(path_612669, "segment-id", newJString(segmentId))
  add(query_612670, "page-size", newJString(pageSize))
  add(query_612670, "token", newJString(token))
  result = call_612668.call(path_612669, query_612670, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_612653(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_612654, base: "/",
    url: url_GetSegmentExportJobs_612655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_612671 = ref object of OpenApiRestCall_610642
proc url_GetSegmentImportJobs_612673(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_612672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612674 = path.getOrDefault("application-id")
  valid_612674 = validateParameter(valid_612674, JString, required = true,
                                 default = nil)
  if valid_612674 != nil:
    section.add "application-id", valid_612674
  var valid_612675 = path.getOrDefault("segment-id")
  valid_612675 = validateParameter(valid_612675, JString, required = true,
                                 default = nil)
  if valid_612675 != nil:
    section.add "segment-id", valid_612675
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_612676 = query.getOrDefault("page-size")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "page-size", valid_612676
  var valid_612677 = query.getOrDefault("token")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "token", valid_612677
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
  var valid_612678 = header.getOrDefault("X-Amz-Signature")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Signature", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Content-Sha256", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-Date")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-Date", valid_612680
  var valid_612681 = header.getOrDefault("X-Amz-Credential")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "X-Amz-Credential", valid_612681
  var valid_612682 = header.getOrDefault("X-Amz-Security-Token")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-Security-Token", valid_612682
  var valid_612683 = header.getOrDefault("X-Amz-Algorithm")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "X-Amz-Algorithm", valid_612683
  var valid_612684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612684 = validateParameter(valid_612684, JString, required = false,
                                 default = nil)
  if valid_612684 != nil:
    section.add "X-Amz-SignedHeaders", valid_612684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612685: Call_GetSegmentImportJobs_612671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_612685.validator(path, query, header, formData, body)
  let scheme = call_612685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612685.url(scheme.get, call_612685.host, call_612685.base,
                         call_612685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612685, url, valid)

proc call*(call_612686: Call_GetSegmentImportJobs_612671; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentImportJobs
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_612687 = newJObject()
  var query_612688 = newJObject()
  add(path_612687, "application-id", newJString(applicationId))
  add(path_612687, "segment-id", newJString(segmentId))
  add(query_612688, "page-size", newJString(pageSize))
  add(query_612688, "token", newJString(token))
  result = call_612686.call(path_612687, query_612688, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_612671(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_612672, base: "/",
    url: url_GetSegmentImportJobs_612673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_612689 = ref object of OpenApiRestCall_610642
proc url_GetSegmentVersion_612691(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_612690(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segment-id: JString (required)
  ##             : The unique identifier for the segment.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_612692 = path.getOrDefault("version")
  valid_612692 = validateParameter(valid_612692, JString, required = true,
                                 default = nil)
  if valid_612692 != nil:
    section.add "version", valid_612692
  var valid_612693 = path.getOrDefault("application-id")
  valid_612693 = validateParameter(valid_612693, JString, required = true,
                                 default = nil)
  if valid_612693 != nil:
    section.add "application-id", valid_612693
  var valid_612694 = path.getOrDefault("segment-id")
  valid_612694 = validateParameter(valid_612694, JString, required = true,
                                 default = nil)
  if valid_612694 != nil:
    section.add "segment-id", valid_612694
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
  var valid_612695 = header.getOrDefault("X-Amz-Signature")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Signature", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Content-Sha256", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Date")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Date", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-Credential")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-Credential", valid_612698
  var valid_612699 = header.getOrDefault("X-Amz-Security-Token")
  valid_612699 = validateParameter(valid_612699, JString, required = false,
                                 default = nil)
  if valid_612699 != nil:
    section.add "X-Amz-Security-Token", valid_612699
  var valid_612700 = header.getOrDefault("X-Amz-Algorithm")
  valid_612700 = validateParameter(valid_612700, JString, required = false,
                                 default = nil)
  if valid_612700 != nil:
    section.add "X-Amz-Algorithm", valid_612700
  var valid_612701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612701 = validateParameter(valid_612701, JString, required = false,
                                 default = nil)
  if valid_612701 != nil:
    section.add "X-Amz-SignedHeaders", valid_612701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612702: Call_GetSegmentVersion_612689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_612702.validator(path, query, header, formData, body)
  let scheme = call_612702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612702.url(scheme.get, call_612702.host, call_612702.base,
                         call_612702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612702, url, valid)

proc call*(call_612703: Call_GetSegmentVersion_612689; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_612704 = newJObject()
  add(path_612704, "version", newJString(version))
  add(path_612704, "application-id", newJString(applicationId))
  add(path_612704, "segment-id", newJString(segmentId))
  result = call_612703.call(path_612704, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_612689(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_612690, base: "/",
    url: url_GetSegmentVersion_612691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_612705 = ref object of OpenApiRestCall_610642
proc url_GetSegmentVersions_612707(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_612706(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_612708 = path.getOrDefault("application-id")
  valid_612708 = validateParameter(valid_612708, JString, required = true,
                                 default = nil)
  if valid_612708 != nil:
    section.add "application-id", valid_612708
  var valid_612709 = path.getOrDefault("segment-id")
  valid_612709 = validateParameter(valid_612709, JString, required = true,
                                 default = nil)
  if valid_612709 != nil:
    section.add "segment-id", valid_612709
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_612710 = query.getOrDefault("page-size")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "page-size", valid_612710
  var valid_612711 = query.getOrDefault("token")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "token", valid_612711
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
  var valid_612712 = header.getOrDefault("X-Amz-Signature")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Signature", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-Content-Sha256", valid_612713
  var valid_612714 = header.getOrDefault("X-Amz-Date")
  valid_612714 = validateParameter(valid_612714, JString, required = false,
                                 default = nil)
  if valid_612714 != nil:
    section.add "X-Amz-Date", valid_612714
  var valid_612715 = header.getOrDefault("X-Amz-Credential")
  valid_612715 = validateParameter(valid_612715, JString, required = false,
                                 default = nil)
  if valid_612715 != nil:
    section.add "X-Amz-Credential", valid_612715
  var valid_612716 = header.getOrDefault("X-Amz-Security-Token")
  valid_612716 = validateParameter(valid_612716, JString, required = false,
                                 default = nil)
  if valid_612716 != nil:
    section.add "X-Amz-Security-Token", valid_612716
  var valid_612717 = header.getOrDefault("X-Amz-Algorithm")
  valid_612717 = validateParameter(valid_612717, JString, required = false,
                                 default = nil)
  if valid_612717 != nil:
    section.add "X-Amz-Algorithm", valid_612717
  var valid_612718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612718 = validateParameter(valid_612718, JString, required = false,
                                 default = nil)
  if valid_612718 != nil:
    section.add "X-Amz-SignedHeaders", valid_612718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612719: Call_GetSegmentVersions_612705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_612719.validator(path, query, header, formData, body)
  let scheme = call_612719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612719.url(scheme.get, call_612719.host, call_612719.base,
                         call_612719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612719, url, valid)

proc call*(call_612720: Call_GetSegmentVersions_612705; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_612721 = newJObject()
  var query_612722 = newJObject()
  add(path_612721, "application-id", newJString(applicationId))
  add(path_612721, "segment-id", newJString(segmentId))
  add(query_612722, "page-size", newJString(pageSize))
  add(query_612722, "token", newJString(token))
  result = call_612720.call(path_612721, query_612722, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_612705(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_612706, base: "/",
    url: url_GetSegmentVersions_612707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612737 = ref object of OpenApiRestCall_610642
proc url_TagResource_612739(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_612738(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612740 = path.getOrDefault("resource-arn")
  valid_612740 = validateParameter(valid_612740, JString, required = true,
                                 default = nil)
  if valid_612740 != nil:
    section.add "resource-arn", valid_612740
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
  var valid_612741 = header.getOrDefault("X-Amz-Signature")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Signature", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Content-Sha256", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-Date")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-Date", valid_612743
  var valid_612744 = header.getOrDefault("X-Amz-Credential")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Credential", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-Security-Token")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-Security-Token", valid_612745
  var valid_612746 = header.getOrDefault("X-Amz-Algorithm")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "X-Amz-Algorithm", valid_612746
  var valid_612747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "X-Amz-SignedHeaders", valid_612747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612749: Call_TagResource_612737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_612749.validator(path, query, header, formData, body)
  let scheme = call_612749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612749.url(scheme.get, call_612749.host, call_612749.base,
                         call_612749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612749, url, valid)

proc call*(call_612750: Call_TagResource_612737; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_612751 = newJObject()
  var body_612752 = newJObject()
  add(path_612751, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_612752 = body
  result = call_612750.call(path_612751, nil, nil, nil, body_612752)

var tagResource* = Call_TagResource_612737(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_612738,
                                        base: "/", url: url_TagResource_612739,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612723 = ref object of OpenApiRestCall_610642
proc url_ListTagsForResource_612725(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_612724(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_612726 = path.getOrDefault("resource-arn")
  valid_612726 = validateParameter(valid_612726, JString, required = true,
                                 default = nil)
  if valid_612726 != nil:
    section.add "resource-arn", valid_612726
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
  var valid_612727 = header.getOrDefault("X-Amz-Signature")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-Signature", valid_612727
  var valid_612728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-Content-Sha256", valid_612728
  var valid_612729 = header.getOrDefault("X-Amz-Date")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Date", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-Credential")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-Credential", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-Security-Token")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Security-Token", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Algorithm")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Algorithm", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-SignedHeaders", valid_612733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612734: Call_ListTagsForResource_612723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_612734.validator(path, query, header, formData, body)
  let scheme = call_612734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612734.url(scheme.get, call_612734.host, call_612734.base,
                         call_612734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612734, url, valid)

proc call*(call_612735: Call_ListTagsForResource_612723; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_612736 = newJObject()
  add(path_612736, "resource-arn", newJString(resourceArn))
  result = call_612735.call(path_612736, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_612723(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_612724, base: "/",
    url: url_ListTagsForResource_612725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_612753 = ref object of OpenApiRestCall_610642
proc url_ListTemplateVersions_612755(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_612754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612756 = path.getOrDefault("template-type")
  valid_612756 = validateParameter(valid_612756, JString, required = true,
                                 default = nil)
  if valid_612756 != nil:
    section.add "template-type", valid_612756
  var valid_612757 = path.getOrDefault("template-name")
  valid_612757 = validateParameter(valid_612757, JString, required = true,
                                 default = nil)
  if valid_612757 != nil:
    section.add "template-name", valid_612757
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612758 = query.getOrDefault("page-size")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "page-size", valid_612758
  var valid_612759 = query.getOrDefault("next-token")
  valid_612759 = validateParameter(valid_612759, JString, required = false,
                                 default = nil)
  if valid_612759 != nil:
    section.add "next-token", valid_612759
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
  var valid_612760 = header.getOrDefault("X-Amz-Signature")
  valid_612760 = validateParameter(valid_612760, JString, required = false,
                                 default = nil)
  if valid_612760 != nil:
    section.add "X-Amz-Signature", valid_612760
  var valid_612761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612761 = validateParameter(valid_612761, JString, required = false,
                                 default = nil)
  if valid_612761 != nil:
    section.add "X-Amz-Content-Sha256", valid_612761
  var valid_612762 = header.getOrDefault("X-Amz-Date")
  valid_612762 = validateParameter(valid_612762, JString, required = false,
                                 default = nil)
  if valid_612762 != nil:
    section.add "X-Amz-Date", valid_612762
  var valid_612763 = header.getOrDefault("X-Amz-Credential")
  valid_612763 = validateParameter(valid_612763, JString, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "X-Amz-Credential", valid_612763
  var valid_612764 = header.getOrDefault("X-Amz-Security-Token")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "X-Amz-Security-Token", valid_612764
  var valid_612765 = header.getOrDefault("X-Amz-Algorithm")
  valid_612765 = validateParameter(valid_612765, JString, required = false,
                                 default = nil)
  if valid_612765 != nil:
    section.add "X-Amz-Algorithm", valid_612765
  var valid_612766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-SignedHeaders", valid_612766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612767: Call_ListTemplateVersions_612753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_612767.validator(path, query, header, formData, body)
  let scheme = call_612767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612767.url(scheme.get, call_612767.host, call_612767.base,
                         call_612767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612767, url, valid)

proc call*(call_612768: Call_ListTemplateVersions_612753; templateType: string;
          templateName: string; pageSize: string = ""; nextToken: string = ""): Recallable =
  ## listTemplateVersions
  ## Retrieves information about all the versions of a specific message template.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_612769 = newJObject()
  var query_612770 = newJObject()
  add(path_612769, "template-type", newJString(templateType))
  add(path_612769, "template-name", newJString(templateName))
  add(query_612770, "page-size", newJString(pageSize))
  add(query_612770, "next-token", newJString(nextToken))
  result = call_612768.call(path_612769, query_612770, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_612753(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_612754, base: "/",
    url: url_ListTemplateVersions_612755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_612771 = ref object of OpenApiRestCall_610642
proc url_ListTemplates_612773(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTemplates_612772(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   prefix: JString
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   template-type: JString
  ##                : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_612774 = query.getOrDefault("prefix")
  valid_612774 = validateParameter(valid_612774, JString, required = false,
                                 default = nil)
  if valid_612774 != nil:
    section.add "prefix", valid_612774
  var valid_612775 = query.getOrDefault("page-size")
  valid_612775 = validateParameter(valid_612775, JString, required = false,
                                 default = nil)
  if valid_612775 != nil:
    section.add "page-size", valid_612775
  var valid_612776 = query.getOrDefault("template-type")
  valid_612776 = validateParameter(valid_612776, JString, required = false,
                                 default = nil)
  if valid_612776 != nil:
    section.add "template-type", valid_612776
  var valid_612777 = query.getOrDefault("next-token")
  valid_612777 = validateParameter(valid_612777, JString, required = false,
                                 default = nil)
  if valid_612777 != nil:
    section.add "next-token", valid_612777
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
  var valid_612778 = header.getOrDefault("X-Amz-Signature")
  valid_612778 = validateParameter(valid_612778, JString, required = false,
                                 default = nil)
  if valid_612778 != nil:
    section.add "X-Amz-Signature", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Content-Sha256", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-Date")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-Date", valid_612780
  var valid_612781 = header.getOrDefault("X-Amz-Credential")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Credential", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Security-Token")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Security-Token", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Algorithm")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Algorithm", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-SignedHeaders", valid_612784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612785: Call_ListTemplates_612771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_612785.validator(path, query, header, formData, body)
  let scheme = call_612785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612785.url(scheme.get, call_612785.host, call_612785.base,
                         call_612785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612785, url, valid)

proc call*(call_612786: Call_ListTemplates_612771; prefix: string = "";
          pageSize: string = ""; templateType: string = ""; nextToken: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_612787 = newJObject()
  add(query_612787, "prefix", newJString(prefix))
  add(query_612787, "page-size", newJString(pageSize))
  add(query_612787, "template-type", newJString(templateType))
  add(query_612787, "next-token", newJString(nextToken))
  result = call_612786.call(nil, query_612787, nil, nil, nil)

var listTemplates* = Call_ListTemplates_612771(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_612772, base: "/",
    url: url_ListTemplates_612773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_612788 = ref object of OpenApiRestCall_610642
proc url_PhoneNumberValidate_612790(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PhoneNumberValidate_612789(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves information about a phone number.
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
  var valid_612791 = header.getOrDefault("X-Amz-Signature")
  valid_612791 = validateParameter(valid_612791, JString, required = false,
                                 default = nil)
  if valid_612791 != nil:
    section.add "X-Amz-Signature", valid_612791
  var valid_612792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612792 = validateParameter(valid_612792, JString, required = false,
                                 default = nil)
  if valid_612792 != nil:
    section.add "X-Amz-Content-Sha256", valid_612792
  var valid_612793 = header.getOrDefault("X-Amz-Date")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "X-Amz-Date", valid_612793
  var valid_612794 = header.getOrDefault("X-Amz-Credential")
  valid_612794 = validateParameter(valid_612794, JString, required = false,
                                 default = nil)
  if valid_612794 != nil:
    section.add "X-Amz-Credential", valid_612794
  var valid_612795 = header.getOrDefault("X-Amz-Security-Token")
  valid_612795 = validateParameter(valid_612795, JString, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "X-Amz-Security-Token", valid_612795
  var valid_612796 = header.getOrDefault("X-Amz-Algorithm")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "X-Amz-Algorithm", valid_612796
  var valid_612797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "X-Amz-SignedHeaders", valid_612797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612799: Call_PhoneNumberValidate_612788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_612799.validator(path, query, header, formData, body)
  let scheme = call_612799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612799.url(scheme.get, call_612799.host, call_612799.base,
                         call_612799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612799, url, valid)

proc call*(call_612800: Call_PhoneNumberValidate_612788; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_612801 = newJObject()
  if body != nil:
    body_612801 = body
  result = call_612800.call(nil, nil, nil, nil, body_612801)

var phoneNumberValidate* = Call_PhoneNumberValidate_612788(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_612789, base: "/",
    url: url_PhoneNumberValidate_612790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_612802 = ref object of OpenApiRestCall_610642
proc url_PutEvents_612804(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_612803(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612805 = path.getOrDefault("application-id")
  valid_612805 = validateParameter(valid_612805, JString, required = true,
                                 default = nil)
  if valid_612805 != nil:
    section.add "application-id", valid_612805
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
  var valid_612806 = header.getOrDefault("X-Amz-Signature")
  valid_612806 = validateParameter(valid_612806, JString, required = false,
                                 default = nil)
  if valid_612806 != nil:
    section.add "X-Amz-Signature", valid_612806
  var valid_612807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612807 = validateParameter(valid_612807, JString, required = false,
                                 default = nil)
  if valid_612807 != nil:
    section.add "X-Amz-Content-Sha256", valid_612807
  var valid_612808 = header.getOrDefault("X-Amz-Date")
  valid_612808 = validateParameter(valid_612808, JString, required = false,
                                 default = nil)
  if valid_612808 != nil:
    section.add "X-Amz-Date", valid_612808
  var valid_612809 = header.getOrDefault("X-Amz-Credential")
  valid_612809 = validateParameter(valid_612809, JString, required = false,
                                 default = nil)
  if valid_612809 != nil:
    section.add "X-Amz-Credential", valid_612809
  var valid_612810 = header.getOrDefault("X-Amz-Security-Token")
  valid_612810 = validateParameter(valid_612810, JString, required = false,
                                 default = nil)
  if valid_612810 != nil:
    section.add "X-Amz-Security-Token", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-Algorithm")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-Algorithm", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-SignedHeaders", valid_612812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612814: Call_PutEvents_612802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_612814.validator(path, query, header, formData, body)
  let scheme = call_612814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612814.url(scheme.get, call_612814.host, call_612814.base,
                         call_612814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612814, url, valid)

proc call*(call_612815: Call_PutEvents_612802; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612816 = newJObject()
  var body_612817 = newJObject()
  add(path_612816, "application-id", newJString(applicationId))
  if body != nil:
    body_612817 = body
  result = call_612815.call(path_612816, nil, nil, nil, body_612817)

var putEvents* = Call_PutEvents_612802(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_612803,
                                    base: "/", url: url_PutEvents_612804,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_612818 = ref object of OpenApiRestCall_610642
proc url_RemoveAttributes_612820(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_612819(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_612821 = path.getOrDefault("attribute-type")
  valid_612821 = validateParameter(valid_612821, JString, required = true,
                                 default = nil)
  if valid_612821 != nil:
    section.add "attribute-type", valid_612821
  var valid_612822 = path.getOrDefault("application-id")
  valid_612822 = validateParameter(valid_612822, JString, required = true,
                                 default = nil)
  if valid_612822 != nil:
    section.add "application-id", valid_612822
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
  var valid_612823 = header.getOrDefault("X-Amz-Signature")
  valid_612823 = validateParameter(valid_612823, JString, required = false,
                                 default = nil)
  if valid_612823 != nil:
    section.add "X-Amz-Signature", valid_612823
  var valid_612824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612824 = validateParameter(valid_612824, JString, required = false,
                                 default = nil)
  if valid_612824 != nil:
    section.add "X-Amz-Content-Sha256", valid_612824
  var valid_612825 = header.getOrDefault("X-Amz-Date")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "X-Amz-Date", valid_612825
  var valid_612826 = header.getOrDefault("X-Amz-Credential")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "X-Amz-Credential", valid_612826
  var valid_612827 = header.getOrDefault("X-Amz-Security-Token")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Security-Token", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Algorithm")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Algorithm", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-SignedHeaders", valid_612829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612831: Call_RemoveAttributes_612818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_612831.validator(path, query, header, formData, body)
  let scheme = call_612831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612831.url(scheme.get, call_612831.host, call_612831.base,
                         call_612831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612831, url, valid)

proc call*(call_612832: Call_RemoveAttributes_612818; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612833 = newJObject()
  var body_612834 = newJObject()
  add(path_612833, "attribute-type", newJString(attributeType))
  add(path_612833, "application-id", newJString(applicationId))
  if body != nil:
    body_612834 = body
  result = call_612832.call(path_612833, nil, nil, nil, body_612834)

var removeAttributes* = Call_RemoveAttributes_612818(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_612819, base: "/",
    url: url_RemoveAttributes_612820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_612835 = ref object of OpenApiRestCall_610642
proc url_SendMessages_612837(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_612836(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612838 = path.getOrDefault("application-id")
  valid_612838 = validateParameter(valid_612838, JString, required = true,
                                 default = nil)
  if valid_612838 != nil:
    section.add "application-id", valid_612838
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
  var valid_612839 = header.getOrDefault("X-Amz-Signature")
  valid_612839 = validateParameter(valid_612839, JString, required = false,
                                 default = nil)
  if valid_612839 != nil:
    section.add "X-Amz-Signature", valid_612839
  var valid_612840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "X-Amz-Content-Sha256", valid_612840
  var valid_612841 = header.getOrDefault("X-Amz-Date")
  valid_612841 = validateParameter(valid_612841, JString, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "X-Amz-Date", valid_612841
  var valid_612842 = header.getOrDefault("X-Amz-Credential")
  valid_612842 = validateParameter(valid_612842, JString, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "X-Amz-Credential", valid_612842
  var valid_612843 = header.getOrDefault("X-Amz-Security-Token")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Security-Token", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-Algorithm")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-Algorithm", valid_612844
  var valid_612845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "X-Amz-SignedHeaders", valid_612845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612847: Call_SendMessages_612835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_612847.validator(path, query, header, formData, body)
  let scheme = call_612847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612847.url(scheme.get, call_612847.host, call_612847.base,
                         call_612847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612847, url, valid)

proc call*(call_612848: Call_SendMessages_612835; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612849 = newJObject()
  var body_612850 = newJObject()
  add(path_612849, "application-id", newJString(applicationId))
  if body != nil:
    body_612850 = body
  result = call_612848.call(path_612849, nil, nil, nil, body_612850)

var sendMessages* = Call_SendMessages_612835(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_612836,
    base: "/", url: url_SendMessages_612837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_612851 = ref object of OpenApiRestCall_610642
proc url_SendUsersMessages_612853(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_612852(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_612854 = path.getOrDefault("application-id")
  valid_612854 = validateParameter(valid_612854, JString, required = true,
                                 default = nil)
  if valid_612854 != nil:
    section.add "application-id", valid_612854
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
  var valid_612855 = header.getOrDefault("X-Amz-Signature")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "X-Amz-Signature", valid_612855
  var valid_612856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612856 = validateParameter(valid_612856, JString, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "X-Amz-Content-Sha256", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Date")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Date", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-Credential")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-Credential", valid_612858
  var valid_612859 = header.getOrDefault("X-Amz-Security-Token")
  valid_612859 = validateParameter(valid_612859, JString, required = false,
                                 default = nil)
  if valid_612859 != nil:
    section.add "X-Amz-Security-Token", valid_612859
  var valid_612860 = header.getOrDefault("X-Amz-Algorithm")
  valid_612860 = validateParameter(valid_612860, JString, required = false,
                                 default = nil)
  if valid_612860 != nil:
    section.add "X-Amz-Algorithm", valid_612860
  var valid_612861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612861 = validateParameter(valid_612861, JString, required = false,
                                 default = nil)
  if valid_612861 != nil:
    section.add "X-Amz-SignedHeaders", valid_612861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612863: Call_SendUsersMessages_612851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_612863.validator(path, query, header, formData, body)
  let scheme = call_612863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612863.url(scheme.get, call_612863.host, call_612863.base,
                         call_612863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612863, url, valid)

proc call*(call_612864: Call_SendUsersMessages_612851; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612865 = newJObject()
  var body_612866 = newJObject()
  add(path_612865, "application-id", newJString(applicationId))
  if body != nil:
    body_612866 = body
  result = call_612864.call(path_612865, nil, nil, nil, body_612866)

var sendUsersMessages* = Call_SendUsersMessages_612851(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_612852, base: "/",
    url: url_SendUsersMessages_612853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612867 = ref object of OpenApiRestCall_610642
proc url_UntagResource_612869(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_612868(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612870 = path.getOrDefault("resource-arn")
  valid_612870 = validateParameter(valid_612870, JString, required = true,
                                 default = nil)
  if valid_612870 != nil:
    section.add "resource-arn", valid_612870
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_612871 = query.getOrDefault("tagKeys")
  valid_612871 = validateParameter(valid_612871, JArray, required = true, default = nil)
  if valid_612871 != nil:
    section.add "tagKeys", valid_612871
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
  var valid_612872 = header.getOrDefault("X-Amz-Signature")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Signature", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Content-Sha256", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Date")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Date", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-Credential")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-Credential", valid_612875
  var valid_612876 = header.getOrDefault("X-Amz-Security-Token")
  valid_612876 = validateParameter(valid_612876, JString, required = false,
                                 default = nil)
  if valid_612876 != nil:
    section.add "X-Amz-Security-Token", valid_612876
  var valid_612877 = header.getOrDefault("X-Amz-Algorithm")
  valid_612877 = validateParameter(valid_612877, JString, required = false,
                                 default = nil)
  if valid_612877 != nil:
    section.add "X-Amz-Algorithm", valid_612877
  var valid_612878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612878 = validateParameter(valid_612878, JString, required = false,
                                 default = nil)
  if valid_612878 != nil:
    section.add "X-Amz-SignedHeaders", valid_612878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612879: Call_UntagResource_612867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_612879.validator(path, query, header, formData, body)
  let scheme = call_612879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612879.url(scheme.get, call_612879.host, call_612879.base,
                         call_612879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612879, url, valid)

proc call*(call_612880: Call_UntagResource_612867; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_612881 = newJObject()
  var query_612882 = newJObject()
  add(path_612881, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_612882.add "tagKeys", tagKeys
  result = call_612880.call(path_612881, query_612882, nil, nil, nil)

var untagResource* = Call_UntagResource_612867(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_612868,
    base: "/", url: url_UntagResource_612869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_612883 = ref object of OpenApiRestCall_610642
proc url_UpdateEndpointsBatch_612885(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_612884(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612886 = path.getOrDefault("application-id")
  valid_612886 = validateParameter(valid_612886, JString, required = true,
                                 default = nil)
  if valid_612886 != nil:
    section.add "application-id", valid_612886
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
  var valid_612887 = header.getOrDefault("X-Amz-Signature")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Signature", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Content-Sha256", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-Date")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-Date", valid_612889
  var valid_612890 = header.getOrDefault("X-Amz-Credential")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "X-Amz-Credential", valid_612890
  var valid_612891 = header.getOrDefault("X-Amz-Security-Token")
  valid_612891 = validateParameter(valid_612891, JString, required = false,
                                 default = nil)
  if valid_612891 != nil:
    section.add "X-Amz-Security-Token", valid_612891
  var valid_612892 = header.getOrDefault("X-Amz-Algorithm")
  valid_612892 = validateParameter(valid_612892, JString, required = false,
                                 default = nil)
  if valid_612892 != nil:
    section.add "X-Amz-Algorithm", valid_612892
  var valid_612893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612893 = validateParameter(valid_612893, JString, required = false,
                                 default = nil)
  if valid_612893 != nil:
    section.add "X-Amz-SignedHeaders", valid_612893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612895: Call_UpdateEndpointsBatch_612883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_612895.validator(path, query, header, formData, body)
  let scheme = call_612895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612895.url(scheme.get, call_612895.host, call_612895.base,
                         call_612895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612895, url, valid)

proc call*(call_612896: Call_UpdateEndpointsBatch_612883; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_612897 = newJObject()
  var body_612898 = newJObject()
  add(path_612897, "application-id", newJString(applicationId))
  if body != nil:
    body_612898 = body
  result = call_612896.call(path_612897, nil, nil, nil, body_612898)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_612883(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_612884, base: "/",
    url: url_UpdateEndpointsBatch_612885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_612899 = ref object of OpenApiRestCall_610642
proc url_UpdateJourneyState_612901(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_612900(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Cancels (stops) an active journey.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journey-id: JString (required)
  ##             : The unique identifier for the journey.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_612902 = path.getOrDefault("application-id")
  valid_612902 = validateParameter(valid_612902, JString, required = true,
                                 default = nil)
  if valid_612902 != nil:
    section.add "application-id", valid_612902
  var valid_612903 = path.getOrDefault("journey-id")
  valid_612903 = validateParameter(valid_612903, JString, required = true,
                                 default = nil)
  if valid_612903 != nil:
    section.add "journey-id", valid_612903
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
  var valid_612904 = header.getOrDefault("X-Amz-Signature")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Signature", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Content-Sha256", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Date")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Date", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-Credential")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-Credential", valid_612907
  var valid_612908 = header.getOrDefault("X-Amz-Security-Token")
  valid_612908 = validateParameter(valid_612908, JString, required = false,
                                 default = nil)
  if valid_612908 != nil:
    section.add "X-Amz-Security-Token", valid_612908
  var valid_612909 = header.getOrDefault("X-Amz-Algorithm")
  valid_612909 = validateParameter(valid_612909, JString, required = false,
                                 default = nil)
  if valid_612909 != nil:
    section.add "X-Amz-Algorithm", valid_612909
  var valid_612910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612910 = validateParameter(valid_612910, JString, required = false,
                                 default = nil)
  if valid_612910 != nil:
    section.add "X-Amz-SignedHeaders", valid_612910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612912: Call_UpdateJourneyState_612899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_612912.validator(path, query, header, formData, body)
  let scheme = call_612912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612912.url(scheme.get, call_612912.host, call_612912.base,
                         call_612912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612912, url, valid)

proc call*(call_612913: Call_UpdateJourneyState_612899; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_612914 = newJObject()
  var body_612915 = newJObject()
  add(path_612914, "application-id", newJString(applicationId))
  if body != nil:
    body_612915 = body
  add(path_612914, "journey-id", newJString(journeyId))
  result = call_612913.call(path_612914, nil, nil, nil, body_612915)

var updateJourneyState* = Call_UpdateJourneyState_612899(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_612900, base: "/",
    url: url_UpdateJourneyState_612901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_612916 = ref object of OpenApiRestCall_610642
proc url_UpdateTemplateActiveVersion_612918(protocol: Scheme; host: string;
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

proc validate_UpdateTemplateActiveVersion_612917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612919 = path.getOrDefault("template-type")
  valid_612919 = validateParameter(valid_612919, JString, required = true,
                                 default = nil)
  if valid_612919 != nil:
    section.add "template-type", valid_612919
  var valid_612920 = path.getOrDefault("template-name")
  valid_612920 = validateParameter(valid_612920, JString, required = true,
                                 default = nil)
  if valid_612920 != nil:
    section.add "template-name", valid_612920
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
  var valid_612921 = header.getOrDefault("X-Amz-Signature")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Signature", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-Content-Sha256", valid_612922
  var valid_612923 = header.getOrDefault("X-Amz-Date")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "X-Amz-Date", valid_612923
  var valid_612924 = header.getOrDefault("X-Amz-Credential")
  valid_612924 = validateParameter(valid_612924, JString, required = false,
                                 default = nil)
  if valid_612924 != nil:
    section.add "X-Amz-Credential", valid_612924
  var valid_612925 = header.getOrDefault("X-Amz-Security-Token")
  valid_612925 = validateParameter(valid_612925, JString, required = false,
                                 default = nil)
  if valid_612925 != nil:
    section.add "X-Amz-Security-Token", valid_612925
  var valid_612926 = header.getOrDefault("X-Amz-Algorithm")
  valid_612926 = validateParameter(valid_612926, JString, required = false,
                                 default = nil)
  if valid_612926 != nil:
    section.add "X-Amz-Algorithm", valid_612926
  var valid_612927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612927 = validateParameter(valid_612927, JString, required = false,
                                 default = nil)
  if valid_612927 != nil:
    section.add "X-Amz-SignedHeaders", valid_612927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612929: Call_UpdateTemplateActiveVersion_612916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_612929.validator(path, query, header, formData, body)
  let scheme = call_612929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612929.url(scheme.get, call_612929.host, call_612929.base,
                         call_612929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612929, url, valid)

proc call*(call_612930: Call_UpdateTemplateActiveVersion_612916;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_612931 = newJObject()
  var body_612932 = newJObject()
  add(path_612931, "template-type", newJString(templateType))
  add(path_612931, "template-name", newJString(templateName))
  if body != nil:
    body_612932 = body
  result = call_612930.call(path_612931, nil, nil, nil, body_612932)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_612916(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_612917, base: "/",
    url: url_UpdateTemplateActiveVersion_612918,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
