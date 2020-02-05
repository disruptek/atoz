
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  Call_CreateApp_613237 = ref object of OpenApiRestCall_612642
proc url_CreateApp_613239(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_613238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613240 = header.getOrDefault("X-Amz-Signature")
  valid_613240 = validateParameter(valid_613240, JString, required = false,
                                 default = nil)
  if valid_613240 != nil:
    section.add "X-Amz-Signature", valid_613240
  var valid_613241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613241 = validateParameter(valid_613241, JString, required = false,
                                 default = nil)
  if valid_613241 != nil:
    section.add "X-Amz-Content-Sha256", valid_613241
  var valid_613242 = header.getOrDefault("X-Amz-Date")
  valid_613242 = validateParameter(valid_613242, JString, required = false,
                                 default = nil)
  if valid_613242 != nil:
    section.add "X-Amz-Date", valid_613242
  var valid_613243 = header.getOrDefault("X-Amz-Credential")
  valid_613243 = validateParameter(valid_613243, JString, required = false,
                                 default = nil)
  if valid_613243 != nil:
    section.add "X-Amz-Credential", valid_613243
  var valid_613244 = header.getOrDefault("X-Amz-Security-Token")
  valid_613244 = validateParameter(valid_613244, JString, required = false,
                                 default = nil)
  if valid_613244 != nil:
    section.add "X-Amz-Security-Token", valid_613244
  var valid_613245 = header.getOrDefault("X-Amz-Algorithm")
  valid_613245 = validateParameter(valid_613245, JString, required = false,
                                 default = nil)
  if valid_613245 != nil:
    section.add "X-Amz-Algorithm", valid_613245
  var valid_613246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613246 = validateParameter(valid_613246, JString, required = false,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-SignedHeaders", valid_613246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613248: Call_CreateApp_613237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_613248.validator(path, query, header, formData, body)
  let scheme = call_613248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613248.url(scheme.get, call_613248.host, call_613248.base,
                         call_613248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613248, url, valid)

proc call*(call_613249: Call_CreateApp_613237; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_613250 = newJObject()
  if body != nil:
    body_613250 = body
  result = call_613249.call(nil, nil, nil, nil, body_613250)

var createApp* = Call_CreateApp_613237(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_613238,
                                    base: "/", url: url_CreateApp_613239,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_612980 = ref object of OpenApiRestCall_612642
proc url_GetApps_612982(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApps_612981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613094 = query.getOrDefault("page-size")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "page-size", valid_613094
  var valid_613095 = query.getOrDefault("token")
  valid_613095 = validateParameter(valid_613095, JString, required = false,
                                 default = nil)
  if valid_613095 != nil:
    section.add "token", valid_613095
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
  var valid_613096 = header.getOrDefault("X-Amz-Signature")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Signature", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-Content-Sha256", valid_613097
  var valid_613098 = header.getOrDefault("X-Amz-Date")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "X-Amz-Date", valid_613098
  var valid_613099 = header.getOrDefault("X-Amz-Credential")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Credential", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-Security-Token")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-Security-Token", valid_613100
  var valid_613101 = header.getOrDefault("X-Amz-Algorithm")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Algorithm", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-SignedHeaders", valid_613102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613125: Call_GetApps_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_613125.validator(path, query, header, formData, body)
  let scheme = call_613125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613125.url(scheme.get, call_613125.host, call_613125.base,
                         call_613125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613125, url, valid)

proc call*(call_613196: Call_GetApps_612980; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_613197 = newJObject()
  add(query_613197, "page-size", newJString(pageSize))
  add(query_613197, "token", newJString(token))
  result = call_613196.call(nil, query_613197, nil, nil, nil)

var getApps* = Call_GetApps_612980(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_612981, base: "/",
                                url: url_GetApps_612982,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_613282 = ref object of OpenApiRestCall_612642
proc url_CreateCampaign_613284(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCampaign_613283(path: JsonNode; query: JsonNode;
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
  var valid_613285 = path.getOrDefault("application-id")
  valid_613285 = validateParameter(valid_613285, JString, required = true,
                                 default = nil)
  if valid_613285 != nil:
    section.add "application-id", valid_613285
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
  var valid_613286 = header.getOrDefault("X-Amz-Signature")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Signature", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Content-Sha256", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Date")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Date", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Credential")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Credential", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Security-Token")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Security-Token", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Algorithm")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Algorithm", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613294: Call_CreateCampaign_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_613294.validator(path, query, header, formData, body)
  let scheme = call_613294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613294.url(scheme.get, call_613294.host, call_613294.base,
                         call_613294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613294, url, valid)

proc call*(call_613295: Call_CreateCampaign_613282; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613296 = newJObject()
  var body_613297 = newJObject()
  add(path_613296, "application-id", newJString(applicationId))
  if body != nil:
    body_613297 = body
  result = call_613295.call(path_613296, nil, nil, nil, body_613297)

var createCampaign* = Call_CreateCampaign_613282(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_613283, base: "/", url: url_CreateCampaign_613284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_613251 = ref object of OpenApiRestCall_612642
proc url_GetCampaigns_613253(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaigns_613252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613268 = path.getOrDefault("application-id")
  valid_613268 = validateParameter(valid_613268, JString, required = true,
                                 default = nil)
  if valid_613268 != nil:
    section.add "application-id", valid_613268
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_613269 = query.getOrDefault("page-size")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "page-size", valid_613269
  var valid_613270 = query.getOrDefault("token")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "token", valid_613270
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
  var valid_613271 = header.getOrDefault("X-Amz-Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Signature", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Content-Sha256", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Date")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Date", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Credential")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Credential", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Security-Token")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Security-Token", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Algorithm")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Algorithm", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-SignedHeaders", valid_613277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_GetCampaigns_613251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_GetCampaigns_613251; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_613280 = newJObject()
  var query_613281 = newJObject()
  add(path_613280, "application-id", newJString(applicationId))
  add(query_613281, "page-size", newJString(pageSize))
  add(query_613281, "token", newJString(token))
  result = call_613279.call(path_613280, query_613281, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_613251(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_613252, base: "/", url: url_GetCampaigns_613253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_613314 = ref object of OpenApiRestCall_612642
proc url_UpdateEmailTemplate_613316(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEmailTemplate_613315(path: JsonNode; query: JsonNode;
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
  var valid_613317 = path.getOrDefault("template-name")
  valid_613317 = validateParameter(valid_613317, JString, required = true,
                                 default = nil)
  if valid_613317 != nil:
    section.add "template-name", valid_613317
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_613318 = query.getOrDefault("version")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "version", valid_613318
  var valid_613319 = query.getOrDefault("create-new-version")
  valid_613319 = validateParameter(valid_613319, JBool, required = false, default = nil)
  if valid_613319 != nil:
    section.add "create-new-version", valid_613319
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
  var valid_613320 = header.getOrDefault("X-Amz-Signature")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Signature", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Content-Sha256", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Date")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Date", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Credential")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Credential", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Security-Token")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Security-Token", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Algorithm")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Algorithm", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-SignedHeaders", valid_613326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613328: Call_UpdateEmailTemplate_613314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_613328.validator(path, query, header, formData, body)
  let scheme = call_613328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613328.url(scheme.get, call_613328.host, call_613328.base,
                         call_613328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613328, url, valid)

proc call*(call_613329: Call_UpdateEmailTemplate_613314; templateName: string;
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
  var path_613330 = newJObject()
  var query_613331 = newJObject()
  var body_613332 = newJObject()
  add(path_613330, "template-name", newJString(templateName))
  add(query_613331, "version", newJString(version))
  add(query_613331, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_613332 = body
  result = call_613329.call(path_613330, query_613331, nil, nil, body_613332)

var updateEmailTemplate* = Call_UpdateEmailTemplate_613314(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_613315, base: "/",
    url: url_UpdateEmailTemplate_613316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_613333 = ref object of OpenApiRestCall_612642
proc url_CreateEmailTemplate_613335(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateEmailTemplate_613334(path: JsonNode; query: JsonNode;
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
  var valid_613336 = path.getOrDefault("template-name")
  valid_613336 = validateParameter(valid_613336, JString, required = true,
                                 default = nil)
  if valid_613336 != nil:
    section.add "template-name", valid_613336
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

proc call*(call_613345: Call_CreateEmailTemplate_613333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_613345.validator(path, query, header, formData, body)
  let scheme = call_613345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613345.url(scheme.get, call_613345.host, call_613345.base,
                         call_613345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613345, url, valid)

proc call*(call_613346: Call_CreateEmailTemplate_613333; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_613347 = newJObject()
  var body_613348 = newJObject()
  add(path_613347, "template-name", newJString(templateName))
  if body != nil:
    body_613348 = body
  result = call_613346.call(path_613347, nil, nil, nil, body_613348)

var createEmailTemplate* = Call_CreateEmailTemplate_613333(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_613334, base: "/",
    url: url_CreateEmailTemplate_613335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_613298 = ref object of OpenApiRestCall_612642
proc url_GetEmailTemplate_613300(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailTemplate_613299(path: JsonNode; query: JsonNode;
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
  var valid_613301 = path.getOrDefault("template-name")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "template-name", valid_613301
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613302 = query.getOrDefault("version")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "version", valid_613302
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
  var valid_613303 = header.getOrDefault("X-Amz-Signature")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Signature", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Content-Sha256", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Date")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Date", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Credential")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Credential", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Security-Token")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Security-Token", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Algorithm")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Algorithm", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-SignedHeaders", valid_613309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613310: Call_GetEmailTemplate_613298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_613310.validator(path, query, header, formData, body)
  let scheme = call_613310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613310.url(scheme.get, call_613310.host, call_613310.base,
                         call_613310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613310, url, valid)

proc call*(call_613311: Call_GetEmailTemplate_613298; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613312 = newJObject()
  var query_613313 = newJObject()
  add(path_613312, "template-name", newJString(templateName))
  add(query_613313, "version", newJString(version))
  result = call_613311.call(path_613312, query_613313, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_613298(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_613299, base: "/",
    url: url_GetEmailTemplate_613300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_613349 = ref object of OpenApiRestCall_612642
proc url_DeleteEmailTemplate_613351(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailTemplate_613350(path: JsonNode; query: JsonNode;
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
  var valid_613352 = path.getOrDefault("template-name")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "template-name", valid_613352
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613353 = query.getOrDefault("version")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "version", valid_613353
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
  if body != nil:
    result.add "body", body

proc call*(call_613361: Call_DeleteEmailTemplate_613349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_613361.validator(path, query, header, formData, body)
  let scheme = call_613361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613361.url(scheme.get, call_613361.host, call_613361.base,
                         call_613361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613361, url, valid)

proc call*(call_613362: Call_DeleteEmailTemplate_613349; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613363 = newJObject()
  var query_613364 = newJObject()
  add(path_613363, "template-name", newJString(templateName))
  add(query_613364, "version", newJString(version))
  result = call_613362.call(path_613363, query_613364, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_613349(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_613350, base: "/",
    url: url_DeleteEmailTemplate_613351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_613382 = ref object of OpenApiRestCall_612642
proc url_CreateExportJob_613384(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateExportJob_613383(path: JsonNode; query: JsonNode;
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
  var valid_613385 = path.getOrDefault("application-id")
  valid_613385 = validateParameter(valid_613385, JString, required = true,
                                 default = nil)
  if valid_613385 != nil:
    section.add "application-id", valid_613385
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
  var valid_613386 = header.getOrDefault("X-Amz-Signature")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Signature", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Content-Sha256", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Date")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Date", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Credential")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Credential", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Security-Token")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Security-Token", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Algorithm")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Algorithm", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-SignedHeaders", valid_613392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613394: Call_CreateExportJob_613382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_613394.validator(path, query, header, formData, body)
  let scheme = call_613394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613394.url(scheme.get, call_613394.host, call_613394.base,
                         call_613394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613394, url, valid)

proc call*(call_613395: Call_CreateExportJob_613382; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613396 = newJObject()
  var body_613397 = newJObject()
  add(path_613396, "application-id", newJString(applicationId))
  if body != nil:
    body_613397 = body
  result = call_613395.call(path_613396, nil, nil, nil, body_613397)

var createExportJob* = Call_CreateExportJob_613382(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_613383, base: "/", url: url_CreateExportJob_613384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_613365 = ref object of OpenApiRestCall_612642
proc url_GetExportJobs_613367(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExportJobs_613366(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613368 = path.getOrDefault("application-id")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = nil)
  if valid_613368 != nil:
    section.add "application-id", valid_613368
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_613369 = query.getOrDefault("page-size")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "page-size", valid_613369
  var valid_613370 = query.getOrDefault("token")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "token", valid_613370
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
  var valid_613371 = header.getOrDefault("X-Amz-Signature")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Signature", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Content-Sha256", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Date")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Date", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Credential")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Credential", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Security-Token")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Security-Token", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Algorithm")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Algorithm", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-SignedHeaders", valid_613377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613378: Call_GetExportJobs_613365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_613378.validator(path, query, header, formData, body)
  let scheme = call_613378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613378.url(scheme.get, call_613378.host, call_613378.base,
                         call_613378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613378, url, valid)

proc call*(call_613379: Call_GetExportJobs_613365; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_613380 = newJObject()
  var query_613381 = newJObject()
  add(path_613380, "application-id", newJString(applicationId))
  add(query_613381, "page-size", newJString(pageSize))
  add(query_613381, "token", newJString(token))
  result = call_613379.call(path_613380, query_613381, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_613365(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_613366, base: "/", url: url_GetExportJobs_613367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_613415 = ref object of OpenApiRestCall_612642
proc url_CreateImportJob_613417(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateImportJob_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = path.getOrDefault("application-id")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = nil)
  if valid_613418 != nil:
    section.add "application-id", valid_613418
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
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreateImportJob_613415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreateImportJob_613415; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613429 = newJObject()
  var body_613430 = newJObject()
  add(path_613429, "application-id", newJString(applicationId))
  if body != nil:
    body_613430 = body
  result = call_613428.call(path_613429, nil, nil, nil, body_613430)

var createImportJob* = Call_CreateImportJob_613415(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_613416, base: "/", url: url_CreateImportJob_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_613398 = ref object of OpenApiRestCall_612642
proc url_GetImportJobs_613400(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImportJobs_613399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613401 = path.getOrDefault("application-id")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "application-id", valid_613401
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_613402 = query.getOrDefault("page-size")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "page-size", valid_613402
  var valid_613403 = query.getOrDefault("token")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "token", valid_613403
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
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_GetImportJobs_613398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_GetImportJobs_613398; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_613413 = newJObject()
  var query_613414 = newJObject()
  add(path_613413, "application-id", newJString(applicationId))
  add(query_613414, "page-size", newJString(pageSize))
  add(query_613414, "token", newJString(token))
  result = call_613412.call(path_613413, query_613414, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_613398(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_613399, base: "/", url: url_GetImportJobs_613400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_613448 = ref object of OpenApiRestCall_612642
proc url_CreateJourney_613450(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateJourney_613449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613451 = path.getOrDefault("application-id")
  valid_613451 = validateParameter(valid_613451, JString, required = true,
                                 default = nil)
  if valid_613451 != nil:
    section.add "application-id", valid_613451
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
  var valid_613452 = header.getOrDefault("X-Amz-Signature")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Signature", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Content-Sha256", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Date")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Date", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Credential")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Credential", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Security-Token")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Security-Token", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Algorithm")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Algorithm", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-SignedHeaders", valid_613458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613460: Call_CreateJourney_613448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_613460.validator(path, query, header, formData, body)
  let scheme = call_613460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613460.url(scheme.get, call_613460.host, call_613460.base,
                         call_613460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613460, url, valid)

proc call*(call_613461: Call_CreateJourney_613448; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613462 = newJObject()
  var body_613463 = newJObject()
  add(path_613462, "application-id", newJString(applicationId))
  if body != nil:
    body_613463 = body
  result = call_613461.call(path_613462, nil, nil, nil, body_613463)

var createJourney* = Call_CreateJourney_613448(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_613449, base: "/", url: url_CreateJourney_613450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_613431 = ref object of OpenApiRestCall_612642
proc url_ListJourneys_613433(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJourneys_613432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613434 = path.getOrDefault("application-id")
  valid_613434 = validateParameter(valid_613434, JString, required = true,
                                 default = nil)
  if valid_613434 != nil:
    section.add "application-id", valid_613434
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_613435 = query.getOrDefault("page-size")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "page-size", valid_613435
  var valid_613436 = query.getOrDefault("token")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "token", valid_613436
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
  var valid_613437 = header.getOrDefault("X-Amz-Signature")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Signature", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Content-Sha256", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Date")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Date", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Credential")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Credential", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Security-Token")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Security-Token", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Algorithm")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Algorithm", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-SignedHeaders", valid_613443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613444: Call_ListJourneys_613431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_613444.validator(path, query, header, formData, body)
  let scheme = call_613444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613444.url(scheme.get, call_613444.host, call_613444.base,
                         call_613444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613444, url, valid)

proc call*(call_613445: Call_ListJourneys_613431; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_613446 = newJObject()
  var query_613447 = newJObject()
  add(path_613446, "application-id", newJString(applicationId))
  add(query_613447, "page-size", newJString(pageSize))
  add(query_613447, "token", newJString(token))
  result = call_613445.call(path_613446, query_613447, nil, nil, nil)

var listJourneys* = Call_ListJourneys_613431(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_613432,
    base: "/", url: url_ListJourneys_613433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_613480 = ref object of OpenApiRestCall_612642
proc url_UpdatePushTemplate_613482(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePushTemplate_613481(path: JsonNode; query: JsonNode;
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
  var valid_613483 = path.getOrDefault("template-name")
  valid_613483 = validateParameter(valid_613483, JString, required = true,
                                 default = nil)
  if valid_613483 != nil:
    section.add "template-name", valid_613483
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_613484 = query.getOrDefault("version")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "version", valid_613484
  var valid_613485 = query.getOrDefault("create-new-version")
  valid_613485 = validateParameter(valid_613485, JBool, required = false, default = nil)
  if valid_613485 != nil:
    section.add "create-new-version", valid_613485
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
  var valid_613486 = header.getOrDefault("X-Amz-Signature")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Signature", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Content-Sha256", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Date")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Date", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Credential")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Credential", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Security-Token")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Security-Token", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Algorithm")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Algorithm", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-SignedHeaders", valid_613492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613494: Call_UpdatePushTemplate_613480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_613494.validator(path, query, header, formData, body)
  let scheme = call_613494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613494.url(scheme.get, call_613494.host, call_613494.base,
                         call_613494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613494, url, valid)

proc call*(call_613495: Call_UpdatePushTemplate_613480; templateName: string;
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
  var path_613496 = newJObject()
  var query_613497 = newJObject()
  var body_613498 = newJObject()
  add(path_613496, "template-name", newJString(templateName))
  add(query_613497, "version", newJString(version))
  add(query_613497, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_613498 = body
  result = call_613495.call(path_613496, query_613497, nil, nil, body_613498)

var updatePushTemplate* = Call_UpdatePushTemplate_613480(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_613481, base: "/",
    url: url_UpdatePushTemplate_613482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_613499 = ref object of OpenApiRestCall_612642
proc url_CreatePushTemplate_613501(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePushTemplate_613500(path: JsonNode; query: JsonNode;
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
  var valid_613502 = path.getOrDefault("template-name")
  valid_613502 = validateParameter(valid_613502, JString, required = true,
                                 default = nil)
  if valid_613502 != nil:
    section.add "template-name", valid_613502
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
  var valid_613503 = header.getOrDefault("X-Amz-Signature")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Signature", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Content-Sha256", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Date")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Date", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Credential")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Credential", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Security-Token")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Security-Token", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Algorithm")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Algorithm", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-SignedHeaders", valid_613509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613511: Call_CreatePushTemplate_613499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_613511.validator(path, query, header, formData, body)
  let scheme = call_613511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613511.url(scheme.get, call_613511.host, call_613511.base,
                         call_613511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613511, url, valid)

proc call*(call_613512: Call_CreatePushTemplate_613499; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_613513 = newJObject()
  var body_613514 = newJObject()
  add(path_613513, "template-name", newJString(templateName))
  if body != nil:
    body_613514 = body
  result = call_613512.call(path_613513, nil, nil, nil, body_613514)

var createPushTemplate* = Call_CreatePushTemplate_613499(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_613500, base: "/",
    url: url_CreatePushTemplate_613501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_613464 = ref object of OpenApiRestCall_612642
proc url_GetPushTemplate_613466(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPushTemplate_613465(path: JsonNode; query: JsonNode;
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
  var valid_613467 = path.getOrDefault("template-name")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = nil)
  if valid_613467 != nil:
    section.add "template-name", valid_613467
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613468 = query.getOrDefault("version")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "version", valid_613468
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
  var valid_613469 = header.getOrDefault("X-Amz-Signature")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Signature", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Content-Sha256", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Date")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Date", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Credential")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Credential", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Security-Token")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Security-Token", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Algorithm")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Algorithm", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-SignedHeaders", valid_613475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_GetPushTemplate_613464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_GetPushTemplate_613464; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613478 = newJObject()
  var query_613479 = newJObject()
  add(path_613478, "template-name", newJString(templateName))
  add(query_613479, "version", newJString(version))
  result = call_613477.call(path_613478, query_613479, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_613464(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_613465, base: "/", url: url_GetPushTemplate_613466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_613515 = ref object of OpenApiRestCall_612642
proc url_DeletePushTemplate_613517(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePushTemplate_613516(path: JsonNode; query: JsonNode;
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
  var valid_613518 = path.getOrDefault("template-name")
  valid_613518 = validateParameter(valid_613518, JString, required = true,
                                 default = nil)
  if valid_613518 != nil:
    section.add "template-name", valid_613518
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613519 = query.getOrDefault("version")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "version", valid_613519
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
  var valid_613520 = header.getOrDefault("X-Amz-Signature")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Signature", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Content-Sha256", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Date")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Date", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Credential")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Credential", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Security-Token")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Security-Token", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Algorithm")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Algorithm", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-SignedHeaders", valid_613526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613527: Call_DeletePushTemplate_613515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_613527.validator(path, query, header, formData, body)
  let scheme = call_613527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613527.url(scheme.get, call_613527.host, call_613527.base,
                         call_613527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613527, url, valid)

proc call*(call_613528: Call_DeletePushTemplate_613515; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613529 = newJObject()
  var query_613530 = newJObject()
  add(path_613529, "template-name", newJString(templateName))
  add(query_613530, "version", newJString(version))
  result = call_613528.call(path_613529, query_613530, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_613515(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_613516, base: "/",
    url: url_DeletePushTemplate_613517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_613548 = ref object of OpenApiRestCall_612642
proc url_CreateSegment_613550(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSegment_613549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613551 = path.getOrDefault("application-id")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = nil)
  if valid_613551 != nil:
    section.add "application-id", valid_613551
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
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_CreateSegment_613548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_CreateSegment_613548; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613562 = newJObject()
  var body_613563 = newJObject()
  add(path_613562, "application-id", newJString(applicationId))
  if body != nil:
    body_613563 = body
  result = call_613561.call(path_613562, nil, nil, nil, body_613563)

var createSegment* = Call_CreateSegment_613548(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_613549, base: "/", url: url_CreateSegment_613550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_613531 = ref object of OpenApiRestCall_612642
proc url_GetSegments_613533(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegments_613532(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613534 = path.getOrDefault("application-id")
  valid_613534 = validateParameter(valid_613534, JString, required = true,
                                 default = nil)
  if valid_613534 != nil:
    section.add "application-id", valid_613534
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_613535 = query.getOrDefault("page-size")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "page-size", valid_613535
  var valid_613536 = query.getOrDefault("token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "token", valid_613536
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
  var valid_613537 = header.getOrDefault("X-Amz-Signature")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Signature", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Content-Sha256", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Date")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Date", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Credential")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Credential", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Security-Token")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Security-Token", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Algorithm")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Algorithm", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-SignedHeaders", valid_613543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_GetSegments_613531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_GetSegments_613531; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_613546 = newJObject()
  var query_613547 = newJObject()
  add(path_613546, "application-id", newJString(applicationId))
  add(query_613547, "page-size", newJString(pageSize))
  add(query_613547, "token", newJString(token))
  result = call_613545.call(path_613546, query_613547, nil, nil, nil)

var getSegments* = Call_GetSegments_613531(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_613532,
                                        base: "/", url: url_GetSegments_613533,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_613580 = ref object of OpenApiRestCall_612642
proc url_UpdateSmsTemplate_613582(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSmsTemplate_613581(path: JsonNode; query: JsonNode;
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
  var valid_613583 = path.getOrDefault("template-name")
  valid_613583 = validateParameter(valid_613583, JString, required = true,
                                 default = nil)
  if valid_613583 != nil:
    section.add "template-name", valid_613583
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_613584 = query.getOrDefault("version")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "version", valid_613584
  var valid_613585 = query.getOrDefault("create-new-version")
  valid_613585 = validateParameter(valid_613585, JBool, required = false, default = nil)
  if valid_613585 != nil:
    section.add "create-new-version", valid_613585
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
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Algorithm")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Algorithm", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-SignedHeaders", valid_613592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613594: Call_UpdateSmsTemplate_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_613594.validator(path, query, header, formData, body)
  let scheme = call_613594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613594.url(scheme.get, call_613594.host, call_613594.base,
                         call_613594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613594, url, valid)

proc call*(call_613595: Call_UpdateSmsTemplate_613580; templateName: string;
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
  var path_613596 = newJObject()
  var query_613597 = newJObject()
  var body_613598 = newJObject()
  add(path_613596, "template-name", newJString(templateName))
  add(query_613597, "version", newJString(version))
  add(query_613597, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_613598 = body
  result = call_613595.call(path_613596, query_613597, nil, nil, body_613598)

var updateSmsTemplate* = Call_UpdateSmsTemplate_613580(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_613581, base: "/",
    url: url_UpdateSmsTemplate_613582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_613599 = ref object of OpenApiRestCall_612642
proc url_CreateSmsTemplate_613601(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSmsTemplate_613600(path: JsonNode; query: JsonNode;
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
  var valid_613602 = path.getOrDefault("template-name")
  valid_613602 = validateParameter(valid_613602, JString, required = true,
                                 default = nil)
  if valid_613602 != nil:
    section.add "template-name", valid_613602
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
  var valid_613603 = header.getOrDefault("X-Amz-Signature")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Signature", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Content-Sha256", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Date")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Date", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Credential")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Credential", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Security-Token")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Security-Token", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Algorithm")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Algorithm", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-SignedHeaders", valid_613609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613611: Call_CreateSmsTemplate_613599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_613611.validator(path, query, header, formData, body)
  let scheme = call_613611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613611.url(scheme.get, call_613611.host, call_613611.base,
                         call_613611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613611, url, valid)

proc call*(call_613612: Call_CreateSmsTemplate_613599; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_613613 = newJObject()
  var body_613614 = newJObject()
  add(path_613613, "template-name", newJString(templateName))
  if body != nil:
    body_613614 = body
  result = call_613612.call(path_613613, nil, nil, nil, body_613614)

var createSmsTemplate* = Call_CreateSmsTemplate_613599(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_613600, base: "/",
    url: url_CreateSmsTemplate_613601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_613564 = ref object of OpenApiRestCall_612642
proc url_GetSmsTemplate_613566(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSmsTemplate_613565(path: JsonNode; query: JsonNode;
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
  var valid_613567 = path.getOrDefault("template-name")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = nil)
  if valid_613567 != nil:
    section.add "template-name", valid_613567
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613568 = query.getOrDefault("version")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "version", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613576: Call_GetSmsTemplate_613564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_613576.validator(path, query, header, formData, body)
  let scheme = call_613576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613576.url(scheme.get, call_613576.host, call_613576.base,
                         call_613576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613576, url, valid)

proc call*(call_613577: Call_GetSmsTemplate_613564; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613578 = newJObject()
  var query_613579 = newJObject()
  add(path_613578, "template-name", newJString(templateName))
  add(query_613579, "version", newJString(version))
  result = call_613577.call(path_613578, query_613579, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_613564(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_613565, base: "/", url: url_GetSmsTemplate_613566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_613615 = ref object of OpenApiRestCall_612642
proc url_DeleteSmsTemplate_613617(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSmsTemplate_613616(path: JsonNode; query: JsonNode;
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
  var valid_613618 = path.getOrDefault("template-name")
  valid_613618 = validateParameter(valid_613618, JString, required = true,
                                 default = nil)
  if valid_613618 != nil:
    section.add "template-name", valid_613618
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613619 = query.getOrDefault("version")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "version", valid_613619
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
  var valid_613620 = header.getOrDefault("X-Amz-Signature")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Signature", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Content-Sha256", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Date")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Date", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Credential")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Credential", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Security-Token")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Security-Token", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Algorithm")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Algorithm", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-SignedHeaders", valid_613626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613627: Call_DeleteSmsTemplate_613615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_613627.validator(path, query, header, formData, body)
  let scheme = call_613627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613627.url(scheme.get, call_613627.host, call_613627.base,
                         call_613627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613627, url, valid)

proc call*(call_613628: Call_DeleteSmsTemplate_613615; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613629 = newJObject()
  var query_613630 = newJObject()
  add(path_613629, "template-name", newJString(templateName))
  add(query_613630, "version", newJString(version))
  result = call_613628.call(path_613629, query_613630, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_613615(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_613616, base: "/",
    url: url_DeleteSmsTemplate_613617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_613647 = ref object of OpenApiRestCall_612642
proc url_UpdateVoiceTemplate_613649(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceTemplate_613648(path: JsonNode; query: JsonNode;
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
  var valid_613650 = path.getOrDefault("template-name")
  valid_613650 = validateParameter(valid_613650, JString, required = true,
                                 default = nil)
  if valid_613650 != nil:
    section.add "template-name", valid_613650
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_613651 = query.getOrDefault("version")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "version", valid_613651
  var valid_613652 = query.getOrDefault("create-new-version")
  valid_613652 = validateParameter(valid_613652, JBool, required = false, default = nil)
  if valid_613652 != nil:
    section.add "create-new-version", valid_613652
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
  var valid_613653 = header.getOrDefault("X-Amz-Signature")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Signature", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Content-Sha256", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Date")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Date", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Credential")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Credential", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Security-Token")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Security-Token", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Algorithm")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Algorithm", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-SignedHeaders", valid_613659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613661: Call_UpdateVoiceTemplate_613647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_613661.validator(path, query, header, formData, body)
  let scheme = call_613661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613661.url(scheme.get, call_613661.host, call_613661.base,
                         call_613661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613661, url, valid)

proc call*(call_613662: Call_UpdateVoiceTemplate_613647; templateName: string;
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
  var path_613663 = newJObject()
  var query_613664 = newJObject()
  var body_613665 = newJObject()
  add(path_613663, "template-name", newJString(templateName))
  add(query_613664, "version", newJString(version))
  add(query_613664, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_613665 = body
  result = call_613662.call(path_613663, query_613664, nil, nil, body_613665)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_613647(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_613648, base: "/",
    url: url_UpdateVoiceTemplate_613649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_613666 = ref object of OpenApiRestCall_612642
proc url_CreateVoiceTemplate_613668(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVoiceTemplate_613667(path: JsonNode; query: JsonNode;
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
  var valid_613669 = path.getOrDefault("template-name")
  valid_613669 = validateParameter(valid_613669, JString, required = true,
                                 default = nil)
  if valid_613669 != nil:
    section.add "template-name", valid_613669
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
  var valid_613670 = header.getOrDefault("X-Amz-Signature")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Signature", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Content-Sha256", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Date")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Date", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Credential")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Credential", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Security-Token")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Security-Token", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Algorithm")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Algorithm", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-SignedHeaders", valid_613676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613678: Call_CreateVoiceTemplate_613666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_613678.validator(path, query, header, formData, body)
  let scheme = call_613678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613678.url(scheme.get, call_613678.host, call_613678.base,
                         call_613678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613678, url, valid)

proc call*(call_613679: Call_CreateVoiceTemplate_613666; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_613680 = newJObject()
  var body_613681 = newJObject()
  add(path_613680, "template-name", newJString(templateName))
  if body != nil:
    body_613681 = body
  result = call_613679.call(path_613680, nil, nil, nil, body_613681)

var createVoiceTemplate* = Call_CreateVoiceTemplate_613666(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_613667, base: "/",
    url: url_CreateVoiceTemplate_613668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_613631 = ref object of OpenApiRestCall_612642
proc url_GetVoiceTemplate_613633(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceTemplate_613632(path: JsonNode; query: JsonNode;
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
  var valid_613634 = path.getOrDefault("template-name")
  valid_613634 = validateParameter(valid_613634, JString, required = true,
                                 default = nil)
  if valid_613634 != nil:
    section.add "template-name", valid_613634
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613635 = query.getOrDefault("version")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "version", valid_613635
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

proc call*(call_613643: Call_GetVoiceTemplate_613631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_613643.validator(path, query, header, formData, body)
  let scheme = call_613643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613643.url(scheme.get, call_613643.host, call_613643.base,
                         call_613643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613643, url, valid)

proc call*(call_613644: Call_GetVoiceTemplate_613631; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613645 = newJObject()
  var query_613646 = newJObject()
  add(path_613645, "template-name", newJString(templateName))
  add(query_613646, "version", newJString(version))
  result = call_613644.call(path_613645, query_613646, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_613631(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_613632, base: "/",
    url: url_GetVoiceTemplate_613633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_613682 = ref object of OpenApiRestCall_612642
proc url_DeleteVoiceTemplate_613684(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceTemplate_613683(path: JsonNode; query: JsonNode;
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
  var valid_613685 = path.getOrDefault("template-name")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = nil)
  if valid_613685 != nil:
    section.add "template-name", valid_613685
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_613686 = query.getOrDefault("version")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "version", valid_613686
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
  var valid_613687 = header.getOrDefault("X-Amz-Signature")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Signature", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Content-Sha256", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Date")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Date", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Credential")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Credential", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Security-Token")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Security-Token", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Algorithm")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Algorithm", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-SignedHeaders", valid_613693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_DeleteVoiceTemplate_613682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_DeleteVoiceTemplate_613682; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_613696 = newJObject()
  var query_613697 = newJObject()
  add(path_613696, "template-name", newJString(templateName))
  add(query_613697, "version", newJString(version))
  result = call_613695.call(path_613696, query_613697, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_613682(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_613683, base: "/",
    url: url_DeleteVoiceTemplate_613684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_613712 = ref object of OpenApiRestCall_612642
proc url_UpdateAdmChannel_613714(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAdmChannel_613713(path: JsonNode; query: JsonNode;
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
  var valid_613715 = path.getOrDefault("application-id")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "application-id", valid_613715
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
  var valid_613716 = header.getOrDefault("X-Amz-Signature")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Signature", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Content-Sha256", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Date")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Date", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Credential")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Credential", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Security-Token")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Security-Token", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Algorithm")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Algorithm", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-SignedHeaders", valid_613722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613724: Call_UpdateAdmChannel_613712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_613724.validator(path, query, header, formData, body)
  let scheme = call_613724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613724.url(scheme.get, call_613724.host, call_613724.base,
                         call_613724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613724, url, valid)

proc call*(call_613725: Call_UpdateAdmChannel_613712; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613726 = newJObject()
  var body_613727 = newJObject()
  add(path_613726, "application-id", newJString(applicationId))
  if body != nil:
    body_613727 = body
  result = call_613725.call(path_613726, nil, nil, nil, body_613727)

var updateAdmChannel* = Call_UpdateAdmChannel_613712(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_613713, base: "/",
    url: url_UpdateAdmChannel_613714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_613698 = ref object of OpenApiRestCall_612642
proc url_GetAdmChannel_613700(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAdmChannel_613699(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613701 = path.getOrDefault("application-id")
  valid_613701 = validateParameter(valid_613701, JString, required = true,
                                 default = nil)
  if valid_613701 != nil:
    section.add "application-id", valid_613701
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
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613709: Call_GetAdmChannel_613698; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_613709.validator(path, query, header, formData, body)
  let scheme = call_613709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613709.url(scheme.get, call_613709.host, call_613709.base,
                         call_613709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613709, url, valid)

proc call*(call_613710: Call_GetAdmChannel_613698; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613711 = newJObject()
  add(path_613711, "application-id", newJString(applicationId))
  result = call_613710.call(path_613711, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_613698(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_613699, base: "/", url: url_GetAdmChannel_613700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_613728 = ref object of OpenApiRestCall_612642
proc url_DeleteAdmChannel_613730(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAdmChannel_613729(path: JsonNode; query: JsonNode;
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
  var valid_613731 = path.getOrDefault("application-id")
  valid_613731 = validateParameter(valid_613731, JString, required = true,
                                 default = nil)
  if valid_613731 != nil:
    section.add "application-id", valid_613731
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

proc call*(call_613739: Call_DeleteAdmChannel_613728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613739.validator(path, query, header, formData, body)
  let scheme = call_613739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613739.url(scheme.get, call_613739.host, call_613739.base,
                         call_613739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613739, url, valid)

proc call*(call_613740: Call_DeleteAdmChannel_613728; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613741 = newJObject()
  add(path_613741, "application-id", newJString(applicationId))
  result = call_613740.call(path_613741, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_613728(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_613729, base: "/",
    url: url_DeleteAdmChannel_613730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_613756 = ref object of OpenApiRestCall_612642
proc url_UpdateApnsChannel_613758(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsChannel_613757(path: JsonNode; query: JsonNode;
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
  var valid_613759 = path.getOrDefault("application-id")
  valid_613759 = validateParameter(valid_613759, JString, required = true,
                                 default = nil)
  if valid_613759 != nil:
    section.add "application-id", valid_613759
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
  var valid_613760 = header.getOrDefault("X-Amz-Signature")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Signature", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Content-Sha256", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Date")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Date", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Credential")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Credential", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Security-Token")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Security-Token", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Algorithm")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Algorithm", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-SignedHeaders", valid_613766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613768: Call_UpdateApnsChannel_613756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_613768.validator(path, query, header, formData, body)
  let scheme = call_613768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613768.url(scheme.get, call_613768.host, call_613768.base,
                         call_613768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613768, url, valid)

proc call*(call_613769: Call_UpdateApnsChannel_613756; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613770 = newJObject()
  var body_613771 = newJObject()
  add(path_613770, "application-id", newJString(applicationId))
  if body != nil:
    body_613771 = body
  result = call_613769.call(path_613770, nil, nil, nil, body_613771)

var updateApnsChannel* = Call_UpdateApnsChannel_613756(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_613757, base: "/",
    url: url_UpdateApnsChannel_613758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_613742 = ref object of OpenApiRestCall_612642
proc url_GetApnsChannel_613744(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsChannel_613743(path: JsonNode; query: JsonNode;
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
  var valid_613745 = path.getOrDefault("application-id")
  valid_613745 = validateParameter(valid_613745, JString, required = true,
                                 default = nil)
  if valid_613745 != nil:
    section.add "application-id", valid_613745
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
  var valid_613746 = header.getOrDefault("X-Amz-Signature")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Signature", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Content-Sha256", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Date")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Date", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Credential")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Credential", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Security-Token")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Security-Token", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Algorithm")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Algorithm", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-SignedHeaders", valid_613752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613753: Call_GetApnsChannel_613742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_613753.validator(path, query, header, formData, body)
  let scheme = call_613753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613753.url(scheme.get, call_613753.host, call_613753.base,
                         call_613753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613753, url, valid)

proc call*(call_613754: Call_GetApnsChannel_613742; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613755 = newJObject()
  add(path_613755, "application-id", newJString(applicationId))
  result = call_613754.call(path_613755, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_613742(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_613743, base: "/", url: url_GetApnsChannel_613744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_613772 = ref object of OpenApiRestCall_612642
proc url_DeleteApnsChannel_613774(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsChannel_613773(path: JsonNode; query: JsonNode;
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
  var valid_613775 = path.getOrDefault("application-id")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = nil)
  if valid_613775 != nil:
    section.add "application-id", valid_613775
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
  var valid_613776 = header.getOrDefault("X-Amz-Signature")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Signature", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Content-Sha256", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Date")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Date", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Credential")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Credential", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Security-Token")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Security-Token", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Algorithm")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Algorithm", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-SignedHeaders", valid_613782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613783: Call_DeleteApnsChannel_613772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613783.validator(path, query, header, formData, body)
  let scheme = call_613783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613783.url(scheme.get, call_613783.host, call_613783.base,
                         call_613783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613783, url, valid)

proc call*(call_613784: Call_DeleteApnsChannel_613772; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613785 = newJObject()
  add(path_613785, "application-id", newJString(applicationId))
  result = call_613784.call(path_613785, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_613772(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_613773, base: "/",
    url: url_DeleteApnsChannel_613774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_613800 = ref object of OpenApiRestCall_612642
proc url_UpdateApnsSandboxChannel_613802(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsSandboxChannel_613801(path: JsonNode; query: JsonNode;
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
  var valid_613803 = path.getOrDefault("application-id")
  valid_613803 = validateParameter(valid_613803, JString, required = true,
                                 default = nil)
  if valid_613803 != nil:
    section.add "application-id", valid_613803
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
  var valid_613804 = header.getOrDefault("X-Amz-Signature")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Signature", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Content-Sha256", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Date")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Date", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Credential")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Credential", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Security-Token")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Security-Token", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Algorithm")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Algorithm", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-SignedHeaders", valid_613810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613812: Call_UpdateApnsSandboxChannel_613800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_613812.validator(path, query, header, formData, body)
  let scheme = call_613812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613812.url(scheme.get, call_613812.host, call_613812.base,
                         call_613812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613812, url, valid)

proc call*(call_613813: Call_UpdateApnsSandboxChannel_613800;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613814 = newJObject()
  var body_613815 = newJObject()
  add(path_613814, "application-id", newJString(applicationId))
  if body != nil:
    body_613815 = body
  result = call_613813.call(path_613814, nil, nil, nil, body_613815)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_613800(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_613801, base: "/",
    url: url_UpdateApnsSandboxChannel_613802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_613786 = ref object of OpenApiRestCall_612642
proc url_GetApnsSandboxChannel_613788(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsSandboxChannel_613787(path: JsonNode; query: JsonNode;
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
  var valid_613789 = path.getOrDefault("application-id")
  valid_613789 = validateParameter(valid_613789, JString, required = true,
                                 default = nil)
  if valid_613789 != nil:
    section.add "application-id", valid_613789
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
  var valid_613790 = header.getOrDefault("X-Amz-Signature")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Signature", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Content-Sha256", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Date")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Date", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Credential")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Credential", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Security-Token")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Security-Token", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Algorithm")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Algorithm", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-SignedHeaders", valid_613796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613797: Call_GetApnsSandboxChannel_613786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_613797.validator(path, query, header, formData, body)
  let scheme = call_613797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613797.url(scheme.get, call_613797.host, call_613797.base,
                         call_613797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613797, url, valid)

proc call*(call_613798: Call_GetApnsSandboxChannel_613786; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613799 = newJObject()
  add(path_613799, "application-id", newJString(applicationId))
  result = call_613798.call(path_613799, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_613786(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_613787, base: "/",
    url: url_GetApnsSandboxChannel_613788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_613816 = ref object of OpenApiRestCall_612642
proc url_DeleteApnsSandboxChannel_613818(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsSandboxChannel_613817(path: JsonNode; query: JsonNode;
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
  var valid_613819 = path.getOrDefault("application-id")
  valid_613819 = validateParameter(valid_613819, JString, required = true,
                                 default = nil)
  if valid_613819 != nil:
    section.add "application-id", valid_613819
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
  var valid_613820 = header.getOrDefault("X-Amz-Signature")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Signature", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Content-Sha256", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Date")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Date", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Credential")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Credential", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Security-Token")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Security-Token", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Algorithm")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Algorithm", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-SignedHeaders", valid_613826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613827: Call_DeleteApnsSandboxChannel_613816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613827.validator(path, query, header, formData, body)
  let scheme = call_613827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613827.url(scheme.get, call_613827.host, call_613827.base,
                         call_613827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613827, url, valid)

proc call*(call_613828: Call_DeleteApnsSandboxChannel_613816; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613829 = newJObject()
  add(path_613829, "application-id", newJString(applicationId))
  result = call_613828.call(path_613829, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_613816(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_613817, base: "/",
    url: url_DeleteApnsSandboxChannel_613818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_613844 = ref object of OpenApiRestCall_612642
proc url_UpdateApnsVoipChannel_613846(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsVoipChannel_613845(path: JsonNode; query: JsonNode;
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
  var valid_613847 = path.getOrDefault("application-id")
  valid_613847 = validateParameter(valid_613847, JString, required = true,
                                 default = nil)
  if valid_613847 != nil:
    section.add "application-id", valid_613847
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
  var valid_613848 = header.getOrDefault("X-Amz-Signature")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Signature", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Content-Sha256", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Date")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Date", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Credential")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Credential", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Security-Token")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Security-Token", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Algorithm")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Algorithm", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-SignedHeaders", valid_613854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613856: Call_UpdateApnsVoipChannel_613844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_613856.validator(path, query, header, formData, body)
  let scheme = call_613856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613856.url(scheme.get, call_613856.host, call_613856.base,
                         call_613856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613856, url, valid)

proc call*(call_613857: Call_UpdateApnsVoipChannel_613844; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613858 = newJObject()
  var body_613859 = newJObject()
  add(path_613858, "application-id", newJString(applicationId))
  if body != nil:
    body_613859 = body
  result = call_613857.call(path_613858, nil, nil, nil, body_613859)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_613844(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_613845, base: "/",
    url: url_UpdateApnsVoipChannel_613846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_613830 = ref object of OpenApiRestCall_612642
proc url_GetApnsVoipChannel_613832(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsVoipChannel_613831(path: JsonNode; query: JsonNode;
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
  var valid_613833 = path.getOrDefault("application-id")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "application-id", valid_613833
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
  var valid_613834 = header.getOrDefault("X-Amz-Signature")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Signature", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Content-Sha256", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Date")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Date", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Credential")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Credential", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Security-Token")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Security-Token", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Algorithm")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Algorithm", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-SignedHeaders", valid_613840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613841: Call_GetApnsVoipChannel_613830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_613841.validator(path, query, header, formData, body)
  let scheme = call_613841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613841.url(scheme.get, call_613841.host, call_613841.base,
                         call_613841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613841, url, valid)

proc call*(call_613842: Call_GetApnsVoipChannel_613830; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613843 = newJObject()
  add(path_613843, "application-id", newJString(applicationId))
  result = call_613842.call(path_613843, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_613830(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_613831, base: "/",
    url: url_GetApnsVoipChannel_613832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_613860 = ref object of OpenApiRestCall_612642
proc url_DeleteApnsVoipChannel_613862(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsVoipChannel_613861(path: JsonNode; query: JsonNode;
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
  var valid_613863 = path.getOrDefault("application-id")
  valid_613863 = validateParameter(valid_613863, JString, required = true,
                                 default = nil)
  if valid_613863 != nil:
    section.add "application-id", valid_613863
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
  var valid_613864 = header.getOrDefault("X-Amz-Signature")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Signature", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Content-Sha256", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Date")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Date", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Credential")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Credential", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Security-Token")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Security-Token", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Algorithm")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Algorithm", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-SignedHeaders", valid_613870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_DeleteApnsVoipChannel_613860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_DeleteApnsVoipChannel_613860; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613873 = newJObject()
  add(path_613873, "application-id", newJString(applicationId))
  result = call_613872.call(path_613873, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_613860(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_613861, base: "/",
    url: url_DeleteApnsVoipChannel_613862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_613888 = ref object of OpenApiRestCall_612642
proc url_UpdateApnsVoipSandboxChannel_613890(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApnsVoipSandboxChannel_613889(path: JsonNode; query: JsonNode;
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
  var valid_613891 = path.getOrDefault("application-id")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = nil)
  if valid_613891 != nil:
    section.add "application-id", valid_613891
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
  var valid_613892 = header.getOrDefault("X-Amz-Signature")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Signature", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Content-Sha256", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Date")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Date", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Credential")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Credential", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Security-Token")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Security-Token", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Algorithm")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Algorithm", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-SignedHeaders", valid_613898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613900: Call_UpdateApnsVoipSandboxChannel_613888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_613900.validator(path, query, header, formData, body)
  let scheme = call_613900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613900.url(scheme.get, call_613900.host, call_613900.base,
                         call_613900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613900, url, valid)

proc call*(call_613901: Call_UpdateApnsVoipSandboxChannel_613888;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613902 = newJObject()
  var body_613903 = newJObject()
  add(path_613902, "application-id", newJString(applicationId))
  if body != nil:
    body_613903 = body
  result = call_613901.call(path_613902, nil, nil, nil, body_613903)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_613888(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_613889, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_613890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_613874 = ref object of OpenApiRestCall_612642
proc url_GetApnsVoipSandboxChannel_613876(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApnsVoipSandboxChannel_613875(path: JsonNode; query: JsonNode;
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
  var valid_613877 = path.getOrDefault("application-id")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = nil)
  if valid_613877 != nil:
    section.add "application-id", valid_613877
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
  var valid_613878 = header.getOrDefault("X-Amz-Signature")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Signature", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Content-Sha256", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Date")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Date", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Credential")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Credential", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Security-Token")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Security-Token", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Algorithm")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Algorithm", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-SignedHeaders", valid_613884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613885: Call_GetApnsVoipSandboxChannel_613874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_613885.validator(path, query, header, formData, body)
  let scheme = call_613885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613885.url(scheme.get, call_613885.host, call_613885.base,
                         call_613885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613885, url, valid)

proc call*(call_613886: Call_GetApnsVoipSandboxChannel_613874;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613887 = newJObject()
  add(path_613887, "application-id", newJString(applicationId))
  result = call_613886.call(path_613887, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_613874(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_613875, base: "/",
    url: url_GetApnsVoipSandboxChannel_613876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_613904 = ref object of OpenApiRestCall_612642
proc url_DeleteApnsVoipSandboxChannel_613906(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApnsVoipSandboxChannel_613905(path: JsonNode; query: JsonNode;
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
  var valid_613907 = path.getOrDefault("application-id")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "application-id", valid_613907
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
  var valid_613908 = header.getOrDefault("X-Amz-Signature")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Signature", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Content-Sha256", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Date")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Date", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Credential")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Credential", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Security-Token")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Security-Token", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Algorithm")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Algorithm", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-SignedHeaders", valid_613914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613915: Call_DeleteApnsVoipSandboxChannel_613904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613915.validator(path, query, header, formData, body)
  let scheme = call_613915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613915.url(scheme.get, call_613915.host, call_613915.base,
                         call_613915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613915, url, valid)

proc call*(call_613916: Call_DeleteApnsVoipSandboxChannel_613904;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613917 = newJObject()
  add(path_613917, "application-id", newJString(applicationId))
  result = call_613916.call(path_613917, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_613904(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_613905, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_613906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_613918 = ref object of OpenApiRestCall_612642
proc url_GetApp_613920(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApp_613919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613921 = path.getOrDefault("application-id")
  valid_613921 = validateParameter(valid_613921, JString, required = true,
                                 default = nil)
  if valid_613921 != nil:
    section.add "application-id", valid_613921
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
  var valid_613922 = header.getOrDefault("X-Amz-Signature")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Signature", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Content-Sha256", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Date")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Date", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Credential")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Credential", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Security-Token")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Security-Token", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Algorithm")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Algorithm", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-SignedHeaders", valid_613928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613929: Call_GetApp_613918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_613929.validator(path, query, header, formData, body)
  let scheme = call_613929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613929.url(scheme.get, call_613929.host, call_613929.base,
                         call_613929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613929, url, valid)

proc call*(call_613930: Call_GetApp_613918; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613931 = newJObject()
  add(path_613931, "application-id", newJString(applicationId))
  result = call_613930.call(path_613931, nil, nil, nil, nil)

var getApp* = Call_GetApp_613918(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_613919, base: "/",
                              url: url_GetApp_613920,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_613932 = ref object of OpenApiRestCall_612642
proc url_DeleteApp_613934(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApp_613933(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613935 = path.getOrDefault("application-id")
  valid_613935 = validateParameter(valid_613935, JString, required = true,
                                 default = nil)
  if valid_613935 != nil:
    section.add "application-id", valid_613935
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
  var valid_613936 = header.getOrDefault("X-Amz-Signature")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Signature", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Content-Sha256", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Date")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Date", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Credential")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Credential", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Security-Token")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Security-Token", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Algorithm")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Algorithm", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-SignedHeaders", valid_613942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613943: Call_DeleteApp_613932; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_613943.validator(path, query, header, formData, body)
  let scheme = call_613943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613943.url(scheme.get, call_613943.host, call_613943.base,
                         call_613943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613943, url, valid)

proc call*(call_613944: Call_DeleteApp_613932; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613945 = newJObject()
  add(path_613945, "application-id", newJString(applicationId))
  result = call_613944.call(path_613945, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_613932(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_613933,
                                    base: "/", url: url_DeleteApp_613934,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_613960 = ref object of OpenApiRestCall_612642
proc url_UpdateBaiduChannel_613962(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBaiduChannel_613961(path: JsonNode; query: JsonNode;
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
  var valid_613963 = path.getOrDefault("application-id")
  valid_613963 = validateParameter(valid_613963, JString, required = true,
                                 default = nil)
  if valid_613963 != nil:
    section.add "application-id", valid_613963
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
  var valid_613964 = header.getOrDefault("X-Amz-Signature")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Signature", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Content-Sha256", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Date")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Date", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Credential")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Credential", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Security-Token")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Security-Token", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Algorithm")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Algorithm", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-SignedHeaders", valid_613970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613972: Call_UpdateBaiduChannel_613960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_613972.validator(path, query, header, formData, body)
  let scheme = call_613972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613972.url(scheme.get, call_613972.host, call_613972.base,
                         call_613972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613972, url, valid)

proc call*(call_613973: Call_UpdateBaiduChannel_613960; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_613974 = newJObject()
  var body_613975 = newJObject()
  add(path_613974, "application-id", newJString(applicationId))
  if body != nil:
    body_613975 = body
  result = call_613973.call(path_613974, nil, nil, nil, body_613975)

var updateBaiduChannel* = Call_UpdateBaiduChannel_613960(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_613961, base: "/",
    url: url_UpdateBaiduChannel_613962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_613946 = ref object of OpenApiRestCall_612642
proc url_GetBaiduChannel_613948(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBaiduChannel_613947(path: JsonNode; query: JsonNode;
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
  var valid_613949 = path.getOrDefault("application-id")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = nil)
  if valid_613949 != nil:
    section.add "application-id", valid_613949
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
  var valid_613950 = header.getOrDefault("X-Amz-Signature")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Signature", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Content-Sha256", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Date")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Date", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Credential")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Credential", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613957: Call_GetBaiduChannel_613946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_613957.validator(path, query, header, formData, body)
  let scheme = call_613957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613957.url(scheme.get, call_613957.host, call_613957.base,
                         call_613957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613957, url, valid)

proc call*(call_613958: Call_GetBaiduChannel_613946; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613959 = newJObject()
  add(path_613959, "application-id", newJString(applicationId))
  result = call_613958.call(path_613959, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_613946(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_613947, base: "/", url: url_GetBaiduChannel_613948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_613976 = ref object of OpenApiRestCall_612642
proc url_DeleteBaiduChannel_613978(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBaiduChannel_613977(path: JsonNode; query: JsonNode;
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
  var valid_613979 = path.getOrDefault("application-id")
  valid_613979 = validateParameter(valid_613979, JString, required = true,
                                 default = nil)
  if valid_613979 != nil:
    section.add "application-id", valid_613979
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
  var valid_613980 = header.getOrDefault("X-Amz-Signature")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Signature", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Content-Sha256", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Date")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Date", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Credential")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Credential", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Security-Token")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Security-Token", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Algorithm")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Algorithm", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-SignedHeaders", valid_613986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613987: Call_DeleteBaiduChannel_613976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_613987.validator(path, query, header, formData, body)
  let scheme = call_613987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613987.url(scheme.get, call_613987.host, call_613987.base,
                         call_613987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613987, url, valid)

proc call*(call_613988: Call_DeleteBaiduChannel_613976; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_613989 = newJObject()
  add(path_613989, "application-id", newJString(applicationId))
  result = call_613988.call(path_613989, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_613976(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_613977, base: "/",
    url: url_DeleteBaiduChannel_613978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_614005 = ref object of OpenApiRestCall_612642
proc url_UpdateCampaign_614007(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCampaign_614006(path: JsonNode; query: JsonNode;
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
  var valid_614008 = path.getOrDefault("application-id")
  valid_614008 = validateParameter(valid_614008, JString, required = true,
                                 default = nil)
  if valid_614008 != nil:
    section.add "application-id", valid_614008
  var valid_614009 = path.getOrDefault("campaign-id")
  valid_614009 = validateParameter(valid_614009, JString, required = true,
                                 default = nil)
  if valid_614009 != nil:
    section.add "campaign-id", valid_614009
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
  var valid_614010 = header.getOrDefault("X-Amz-Signature")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Signature", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Content-Sha256", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Date")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Date", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Credential")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Credential", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Security-Token")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Security-Token", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Algorithm")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Algorithm", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-SignedHeaders", valid_614016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614018: Call_UpdateCampaign_614005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_614018.validator(path, query, header, formData, body)
  let scheme = call_614018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614018.url(scheme.get, call_614018.host, call_614018.base,
                         call_614018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614018, url, valid)

proc call*(call_614019: Call_UpdateCampaign_614005; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_614020 = newJObject()
  var body_614021 = newJObject()
  add(path_614020, "application-id", newJString(applicationId))
  if body != nil:
    body_614021 = body
  add(path_614020, "campaign-id", newJString(campaignId))
  result = call_614019.call(path_614020, nil, nil, nil, body_614021)

var updateCampaign* = Call_UpdateCampaign_614005(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_614006, base: "/", url: url_UpdateCampaign_614007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_613990 = ref object of OpenApiRestCall_612642
proc url_GetCampaign_613992(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaign_613991(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613993 = path.getOrDefault("application-id")
  valid_613993 = validateParameter(valid_613993, JString, required = true,
                                 default = nil)
  if valid_613993 != nil:
    section.add "application-id", valid_613993
  var valid_613994 = path.getOrDefault("campaign-id")
  valid_613994 = validateParameter(valid_613994, JString, required = true,
                                 default = nil)
  if valid_613994 != nil:
    section.add "campaign-id", valid_613994
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
  var valid_613995 = header.getOrDefault("X-Amz-Signature")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Signature", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Content-Sha256", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Date")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Date", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Credential")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Credential", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Security-Token")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Security-Token", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Algorithm")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Algorithm", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-SignedHeaders", valid_614001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614002: Call_GetCampaign_613990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_614002.validator(path, query, header, formData, body)
  let scheme = call_614002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614002.url(scheme.get, call_614002.host, call_614002.base,
                         call_614002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614002, url, valid)

proc call*(call_614003: Call_GetCampaign_613990; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_614004 = newJObject()
  add(path_614004, "application-id", newJString(applicationId))
  add(path_614004, "campaign-id", newJString(campaignId))
  result = call_614003.call(path_614004, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_613990(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_613991,
                                        base: "/", url: url_GetCampaign_613992,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_614022 = ref object of OpenApiRestCall_612642
proc url_DeleteCampaign_614024(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCampaign_614023(path: JsonNode; query: JsonNode;
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
  var valid_614025 = path.getOrDefault("application-id")
  valid_614025 = validateParameter(valid_614025, JString, required = true,
                                 default = nil)
  if valid_614025 != nil:
    section.add "application-id", valid_614025
  var valid_614026 = path.getOrDefault("campaign-id")
  valid_614026 = validateParameter(valid_614026, JString, required = true,
                                 default = nil)
  if valid_614026 != nil:
    section.add "campaign-id", valid_614026
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
  var valid_614027 = header.getOrDefault("X-Amz-Signature")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Signature", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Content-Sha256", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Date")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Date", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Credential")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Credential", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Security-Token")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Security-Token", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Algorithm")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Algorithm", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-SignedHeaders", valid_614033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614034: Call_DeleteCampaign_614022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_614034.validator(path, query, header, formData, body)
  let scheme = call_614034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614034.url(scheme.get, call_614034.host, call_614034.base,
                         call_614034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614034, url, valid)

proc call*(call_614035: Call_DeleteCampaign_614022; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_614036 = newJObject()
  add(path_614036, "application-id", newJString(applicationId))
  add(path_614036, "campaign-id", newJString(campaignId))
  result = call_614035.call(path_614036, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_614022(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_614023, base: "/", url: url_DeleteCampaign_614024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_614051 = ref object of OpenApiRestCall_612642
proc url_UpdateEmailChannel_614053(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEmailChannel_614052(path: JsonNode; query: JsonNode;
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
  var valid_614054 = path.getOrDefault("application-id")
  valid_614054 = validateParameter(valid_614054, JString, required = true,
                                 default = nil)
  if valid_614054 != nil:
    section.add "application-id", valid_614054
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
  var valid_614055 = header.getOrDefault("X-Amz-Signature")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Signature", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Content-Sha256", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Date")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Date", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Credential")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Credential", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Security-Token")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Security-Token", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Algorithm")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Algorithm", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-SignedHeaders", valid_614061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614063: Call_UpdateEmailChannel_614051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_614063.validator(path, query, header, formData, body)
  let scheme = call_614063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614063.url(scheme.get, call_614063.host, call_614063.base,
                         call_614063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614063, url, valid)

proc call*(call_614064: Call_UpdateEmailChannel_614051; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614065 = newJObject()
  var body_614066 = newJObject()
  add(path_614065, "application-id", newJString(applicationId))
  if body != nil:
    body_614066 = body
  result = call_614064.call(path_614065, nil, nil, nil, body_614066)

var updateEmailChannel* = Call_UpdateEmailChannel_614051(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_614052, base: "/",
    url: url_UpdateEmailChannel_614053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_614037 = ref object of OpenApiRestCall_612642
proc url_GetEmailChannel_614039(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailChannel_614038(path: JsonNode; query: JsonNode;
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
  var valid_614040 = path.getOrDefault("application-id")
  valid_614040 = validateParameter(valid_614040, JString, required = true,
                                 default = nil)
  if valid_614040 != nil:
    section.add "application-id", valid_614040
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
  var valid_614041 = header.getOrDefault("X-Amz-Signature")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Signature", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Content-Sha256", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Date")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Date", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Credential")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Credential", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Security-Token")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Security-Token", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Algorithm")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Algorithm", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-SignedHeaders", valid_614047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614048: Call_GetEmailChannel_614037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_614048.validator(path, query, header, formData, body)
  let scheme = call_614048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614048.url(scheme.get, call_614048.host, call_614048.base,
                         call_614048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614048, url, valid)

proc call*(call_614049: Call_GetEmailChannel_614037; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614050 = newJObject()
  add(path_614050, "application-id", newJString(applicationId))
  result = call_614049.call(path_614050, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_614037(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_614038, base: "/", url: url_GetEmailChannel_614039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_614067 = ref object of OpenApiRestCall_612642
proc url_DeleteEmailChannel_614069(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailChannel_614068(path: JsonNode; query: JsonNode;
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
  var valid_614070 = path.getOrDefault("application-id")
  valid_614070 = validateParameter(valid_614070, JString, required = true,
                                 default = nil)
  if valid_614070 != nil:
    section.add "application-id", valid_614070
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
  var valid_614071 = header.getOrDefault("X-Amz-Signature")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Signature", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Content-Sha256", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-Date")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-Date", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-Credential")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Credential", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-Security-Token")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Security-Token", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Algorithm")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Algorithm", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-SignedHeaders", valid_614077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614078: Call_DeleteEmailChannel_614067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_614078.validator(path, query, header, formData, body)
  let scheme = call_614078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614078.url(scheme.get, call_614078.host, call_614078.base,
                         call_614078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614078, url, valid)

proc call*(call_614079: Call_DeleteEmailChannel_614067; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614080 = newJObject()
  add(path_614080, "application-id", newJString(applicationId))
  result = call_614079.call(path_614080, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_614067(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_614068, base: "/",
    url: url_DeleteEmailChannel_614069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_614096 = ref object of OpenApiRestCall_612642
proc url_UpdateEndpoint_614098(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEndpoint_614097(path: JsonNode; query: JsonNode;
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
  var valid_614099 = path.getOrDefault("application-id")
  valid_614099 = validateParameter(valid_614099, JString, required = true,
                                 default = nil)
  if valid_614099 != nil:
    section.add "application-id", valid_614099
  var valid_614100 = path.getOrDefault("endpoint-id")
  valid_614100 = validateParameter(valid_614100, JString, required = true,
                                 default = nil)
  if valid_614100 != nil:
    section.add "endpoint-id", valid_614100
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
  var valid_614101 = header.getOrDefault("X-Amz-Signature")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Signature", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Content-Sha256", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Date")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Date", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Credential")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Credential", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Security-Token")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Security-Token", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Algorithm")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Algorithm", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-SignedHeaders", valid_614107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614109: Call_UpdateEndpoint_614096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_614109.validator(path, query, header, formData, body)
  let scheme = call_614109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614109.url(scheme.get, call_614109.host, call_614109.base,
                         call_614109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614109, url, valid)

proc call*(call_614110: Call_UpdateEndpoint_614096; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_614111 = newJObject()
  var body_614112 = newJObject()
  add(path_614111, "application-id", newJString(applicationId))
  if body != nil:
    body_614112 = body
  add(path_614111, "endpoint-id", newJString(endpointId))
  result = call_614110.call(path_614111, nil, nil, nil, body_614112)

var updateEndpoint* = Call_UpdateEndpoint_614096(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_614097, base: "/", url: url_UpdateEndpoint_614098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_614081 = ref object of OpenApiRestCall_612642
proc url_GetEndpoint_614083(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEndpoint_614082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614084 = path.getOrDefault("application-id")
  valid_614084 = validateParameter(valid_614084, JString, required = true,
                                 default = nil)
  if valid_614084 != nil:
    section.add "application-id", valid_614084
  var valid_614085 = path.getOrDefault("endpoint-id")
  valid_614085 = validateParameter(valid_614085, JString, required = true,
                                 default = nil)
  if valid_614085 != nil:
    section.add "endpoint-id", valid_614085
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
  var valid_614086 = header.getOrDefault("X-Amz-Signature")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-Signature", valid_614086
  var valid_614087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Content-Sha256", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Date")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Date", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Credential")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Credential", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Security-Token")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Security-Token", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Algorithm")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Algorithm", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-SignedHeaders", valid_614092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614093: Call_GetEndpoint_614081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_614093.validator(path, query, header, formData, body)
  let scheme = call_614093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614093.url(scheme.get, call_614093.host, call_614093.base,
                         call_614093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614093, url, valid)

proc call*(call_614094: Call_GetEndpoint_614081; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_614095 = newJObject()
  add(path_614095, "application-id", newJString(applicationId))
  add(path_614095, "endpoint-id", newJString(endpointId))
  result = call_614094.call(path_614095, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_614081(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_614082,
                                        base: "/", url: url_GetEndpoint_614083,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_614113 = ref object of OpenApiRestCall_612642
proc url_DeleteEndpoint_614115(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEndpoint_614114(path: JsonNode; query: JsonNode;
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
  var valid_614116 = path.getOrDefault("application-id")
  valid_614116 = validateParameter(valid_614116, JString, required = true,
                                 default = nil)
  if valid_614116 != nil:
    section.add "application-id", valid_614116
  var valid_614117 = path.getOrDefault("endpoint-id")
  valid_614117 = validateParameter(valid_614117, JString, required = true,
                                 default = nil)
  if valid_614117 != nil:
    section.add "endpoint-id", valid_614117
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
  var valid_614118 = header.getOrDefault("X-Amz-Signature")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-Signature", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Content-Sha256", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-Date")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Date", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Credential")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Credential", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Security-Token")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Security-Token", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Algorithm")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Algorithm", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-SignedHeaders", valid_614124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614125: Call_DeleteEndpoint_614113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_614125.validator(path, query, header, formData, body)
  let scheme = call_614125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614125.url(scheme.get, call_614125.host, call_614125.base,
                         call_614125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614125, url, valid)

proc call*(call_614126: Call_DeleteEndpoint_614113; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_614127 = newJObject()
  add(path_614127, "application-id", newJString(applicationId))
  add(path_614127, "endpoint-id", newJString(endpointId))
  result = call_614126.call(path_614127, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_614113(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_614114, base: "/", url: url_DeleteEndpoint_614115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_614142 = ref object of OpenApiRestCall_612642
proc url_PutEventStream_614144(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEventStream_614143(path: JsonNode; query: JsonNode;
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
  var valid_614145 = path.getOrDefault("application-id")
  valid_614145 = validateParameter(valid_614145, JString, required = true,
                                 default = nil)
  if valid_614145 != nil:
    section.add "application-id", valid_614145
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
  var valid_614146 = header.getOrDefault("X-Amz-Signature")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Signature", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Content-Sha256", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Date")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Date", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Credential")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Credential", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Security-Token")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Security-Token", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Algorithm")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Algorithm", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-SignedHeaders", valid_614152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614154: Call_PutEventStream_614142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_614154.validator(path, query, header, formData, body)
  let scheme = call_614154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614154.url(scheme.get, call_614154.host, call_614154.base,
                         call_614154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614154, url, valid)

proc call*(call_614155: Call_PutEventStream_614142; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614156 = newJObject()
  var body_614157 = newJObject()
  add(path_614156, "application-id", newJString(applicationId))
  if body != nil:
    body_614157 = body
  result = call_614155.call(path_614156, nil, nil, nil, body_614157)

var putEventStream* = Call_PutEventStream_614142(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_614143, base: "/", url: url_PutEventStream_614144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_614128 = ref object of OpenApiRestCall_612642
proc url_GetEventStream_614130(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventStream_614129(path: JsonNode; query: JsonNode;
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
  var valid_614131 = path.getOrDefault("application-id")
  valid_614131 = validateParameter(valid_614131, JString, required = true,
                                 default = nil)
  if valid_614131 != nil:
    section.add "application-id", valid_614131
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
  var valid_614132 = header.getOrDefault("X-Amz-Signature")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Signature", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Content-Sha256", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Date")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Date", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Credential")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Credential", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Security-Token")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Security-Token", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-Algorithm")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Algorithm", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-SignedHeaders", valid_614138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614139: Call_GetEventStream_614128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_614139.validator(path, query, header, formData, body)
  let scheme = call_614139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614139.url(scheme.get, call_614139.host, call_614139.base,
                         call_614139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614139, url, valid)

proc call*(call_614140: Call_GetEventStream_614128; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614141 = newJObject()
  add(path_614141, "application-id", newJString(applicationId))
  result = call_614140.call(path_614141, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_614128(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_614129, base: "/", url: url_GetEventStream_614130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_614158 = ref object of OpenApiRestCall_612642
proc url_DeleteEventStream_614160(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventStream_614159(path: JsonNode; query: JsonNode;
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
  var valid_614161 = path.getOrDefault("application-id")
  valid_614161 = validateParameter(valid_614161, JString, required = true,
                                 default = nil)
  if valid_614161 != nil:
    section.add "application-id", valid_614161
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
  var valid_614162 = header.getOrDefault("X-Amz-Signature")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Signature", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Content-Sha256", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Date")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Date", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Credential")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Credential", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Security-Token")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Security-Token", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Algorithm")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Algorithm", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-SignedHeaders", valid_614168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614169: Call_DeleteEventStream_614158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_614169.validator(path, query, header, formData, body)
  let scheme = call_614169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614169.url(scheme.get, call_614169.host, call_614169.base,
                         call_614169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614169, url, valid)

proc call*(call_614170: Call_DeleteEventStream_614158; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614171 = newJObject()
  add(path_614171, "application-id", newJString(applicationId))
  result = call_614170.call(path_614171, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_614158(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_614159, base: "/",
    url: url_DeleteEventStream_614160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_614186 = ref object of OpenApiRestCall_612642
proc url_UpdateGcmChannel_614188(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGcmChannel_614187(path: JsonNode; query: JsonNode;
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
  var valid_614189 = path.getOrDefault("application-id")
  valid_614189 = validateParameter(valid_614189, JString, required = true,
                                 default = nil)
  if valid_614189 != nil:
    section.add "application-id", valid_614189
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
  var valid_614190 = header.getOrDefault("X-Amz-Signature")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Signature", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-Content-Sha256", valid_614191
  var valid_614192 = header.getOrDefault("X-Amz-Date")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "X-Amz-Date", valid_614192
  var valid_614193 = header.getOrDefault("X-Amz-Credential")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Credential", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Security-Token")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Security-Token", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Algorithm")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Algorithm", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-SignedHeaders", valid_614196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614198: Call_UpdateGcmChannel_614186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_614198.validator(path, query, header, formData, body)
  let scheme = call_614198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614198.url(scheme.get, call_614198.host, call_614198.base,
                         call_614198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614198, url, valid)

proc call*(call_614199: Call_UpdateGcmChannel_614186; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614200 = newJObject()
  var body_614201 = newJObject()
  add(path_614200, "application-id", newJString(applicationId))
  if body != nil:
    body_614201 = body
  result = call_614199.call(path_614200, nil, nil, nil, body_614201)

var updateGcmChannel* = Call_UpdateGcmChannel_614186(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_614187, base: "/",
    url: url_UpdateGcmChannel_614188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_614172 = ref object of OpenApiRestCall_612642
proc url_GetGcmChannel_614174(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGcmChannel_614173(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614175 = path.getOrDefault("application-id")
  valid_614175 = validateParameter(valid_614175, JString, required = true,
                                 default = nil)
  if valid_614175 != nil:
    section.add "application-id", valid_614175
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
  var valid_614176 = header.getOrDefault("X-Amz-Signature")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Signature", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Content-Sha256", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Date")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Date", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Credential")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Credential", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Security-Token")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Security-Token", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Algorithm")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Algorithm", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-SignedHeaders", valid_614182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614183: Call_GetGcmChannel_614172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_614183.validator(path, query, header, formData, body)
  let scheme = call_614183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614183.url(scheme.get, call_614183.host, call_614183.base,
                         call_614183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614183, url, valid)

proc call*(call_614184: Call_GetGcmChannel_614172; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614185 = newJObject()
  add(path_614185, "application-id", newJString(applicationId))
  result = call_614184.call(path_614185, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_614172(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_614173, base: "/", url: url_GetGcmChannel_614174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_614202 = ref object of OpenApiRestCall_612642
proc url_DeleteGcmChannel_614204(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGcmChannel_614203(path: JsonNode; query: JsonNode;
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
  var valid_614205 = path.getOrDefault("application-id")
  valid_614205 = validateParameter(valid_614205, JString, required = true,
                                 default = nil)
  if valid_614205 != nil:
    section.add "application-id", valid_614205
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
  var valid_614206 = header.getOrDefault("X-Amz-Signature")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-Signature", valid_614206
  var valid_614207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Content-Sha256", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Date")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Date", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Credential")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Credential", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Security-Token")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Security-Token", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Algorithm")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Algorithm", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-SignedHeaders", valid_614212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614213: Call_DeleteGcmChannel_614202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_614213.validator(path, query, header, formData, body)
  let scheme = call_614213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614213.url(scheme.get, call_614213.host, call_614213.base,
                         call_614213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614213, url, valid)

proc call*(call_614214: Call_DeleteGcmChannel_614202; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614215 = newJObject()
  add(path_614215, "application-id", newJString(applicationId))
  result = call_614214.call(path_614215, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_614202(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_614203, base: "/",
    url: url_DeleteGcmChannel_614204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_614231 = ref object of OpenApiRestCall_612642
proc url_UpdateJourney_614233(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJourney_614232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614234 = path.getOrDefault("application-id")
  valid_614234 = validateParameter(valid_614234, JString, required = true,
                                 default = nil)
  if valid_614234 != nil:
    section.add "application-id", valid_614234
  var valid_614235 = path.getOrDefault("journey-id")
  valid_614235 = validateParameter(valid_614235, JString, required = true,
                                 default = nil)
  if valid_614235 != nil:
    section.add "journey-id", valid_614235
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
  var valid_614236 = header.getOrDefault("X-Amz-Signature")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Signature", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Content-Sha256", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Date")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Date", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Credential")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Credential", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-Security-Token")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-Security-Token", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Algorithm")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Algorithm", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-SignedHeaders", valid_614242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614244: Call_UpdateJourney_614231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_614244.validator(path, query, header, formData, body)
  let scheme = call_614244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614244.url(scheme.get, call_614244.host, call_614244.base,
                         call_614244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614244, url, valid)

proc call*(call_614245: Call_UpdateJourney_614231; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_614246 = newJObject()
  var body_614247 = newJObject()
  add(path_614246, "application-id", newJString(applicationId))
  if body != nil:
    body_614247 = body
  add(path_614246, "journey-id", newJString(journeyId))
  result = call_614245.call(path_614246, nil, nil, nil, body_614247)

var updateJourney* = Call_UpdateJourney_614231(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_614232, base: "/", url: url_UpdateJourney_614233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_614216 = ref object of OpenApiRestCall_612642
proc url_GetJourney_614218(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourney_614217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614219 = path.getOrDefault("application-id")
  valid_614219 = validateParameter(valid_614219, JString, required = true,
                                 default = nil)
  if valid_614219 != nil:
    section.add "application-id", valid_614219
  var valid_614220 = path.getOrDefault("journey-id")
  valid_614220 = validateParameter(valid_614220, JString, required = true,
                                 default = nil)
  if valid_614220 != nil:
    section.add "journey-id", valid_614220
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
  var valid_614221 = header.getOrDefault("X-Amz-Signature")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Signature", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Content-Sha256", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Date")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Date", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Credential")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Credential", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-Security-Token")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Security-Token", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Algorithm")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Algorithm", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-SignedHeaders", valid_614227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614228: Call_GetJourney_614216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_614228.validator(path, query, header, formData, body)
  let scheme = call_614228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614228.url(scheme.get, call_614228.host, call_614228.base,
                         call_614228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614228, url, valid)

proc call*(call_614229: Call_GetJourney_614216; applicationId: string;
          journeyId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_614230 = newJObject()
  add(path_614230, "application-id", newJString(applicationId))
  add(path_614230, "journey-id", newJString(journeyId))
  result = call_614229.call(path_614230, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_614216(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_614217,
                                      base: "/", url: url_GetJourney_614218,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_614248 = ref object of OpenApiRestCall_612642
proc url_DeleteJourney_614250(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJourney_614249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614251 = path.getOrDefault("application-id")
  valid_614251 = validateParameter(valid_614251, JString, required = true,
                                 default = nil)
  if valid_614251 != nil:
    section.add "application-id", valid_614251
  var valid_614252 = path.getOrDefault("journey-id")
  valid_614252 = validateParameter(valid_614252, JString, required = true,
                                 default = nil)
  if valid_614252 != nil:
    section.add "journey-id", valid_614252
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
  var valid_614253 = header.getOrDefault("X-Amz-Signature")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Signature", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Content-Sha256", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Date")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Date", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Credential")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Credential", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Security-Token")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Security-Token", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Algorithm")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Algorithm", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-SignedHeaders", valid_614259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614260: Call_DeleteJourney_614248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_614260.validator(path, query, header, formData, body)
  let scheme = call_614260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614260.url(scheme.get, call_614260.host, call_614260.base,
                         call_614260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614260, url, valid)

proc call*(call_614261: Call_DeleteJourney_614248; applicationId: string;
          journeyId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_614262 = newJObject()
  add(path_614262, "application-id", newJString(applicationId))
  add(path_614262, "journey-id", newJString(journeyId))
  result = call_614261.call(path_614262, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_614248(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_614249, base: "/", url: url_DeleteJourney_614250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_614278 = ref object of OpenApiRestCall_612642
proc url_UpdateSegment_614280(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSegment_614279(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614281 = path.getOrDefault("application-id")
  valid_614281 = validateParameter(valid_614281, JString, required = true,
                                 default = nil)
  if valid_614281 != nil:
    section.add "application-id", valid_614281
  var valid_614282 = path.getOrDefault("segment-id")
  valid_614282 = validateParameter(valid_614282, JString, required = true,
                                 default = nil)
  if valid_614282 != nil:
    section.add "segment-id", valid_614282
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
  var valid_614283 = header.getOrDefault("X-Amz-Signature")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Signature", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Content-Sha256", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-Date")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Date", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Credential")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Credential", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Security-Token")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Security-Token", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-Algorithm")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-Algorithm", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-SignedHeaders", valid_614289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614291: Call_UpdateSegment_614278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_614291.validator(path, query, header, formData, body)
  let scheme = call_614291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614291.url(scheme.get, call_614291.host, call_614291.base,
                         call_614291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614291, url, valid)

proc call*(call_614292: Call_UpdateSegment_614278; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_614293 = newJObject()
  var body_614294 = newJObject()
  add(path_614293, "application-id", newJString(applicationId))
  add(path_614293, "segment-id", newJString(segmentId))
  if body != nil:
    body_614294 = body
  result = call_614292.call(path_614293, nil, nil, nil, body_614294)

var updateSegment* = Call_UpdateSegment_614278(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_614279, base: "/", url: url_UpdateSegment_614280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_614263 = ref object of OpenApiRestCall_612642
proc url_GetSegment_614265(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegment_614264(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614266 = path.getOrDefault("application-id")
  valid_614266 = validateParameter(valid_614266, JString, required = true,
                                 default = nil)
  if valid_614266 != nil:
    section.add "application-id", valid_614266
  var valid_614267 = path.getOrDefault("segment-id")
  valid_614267 = validateParameter(valid_614267, JString, required = true,
                                 default = nil)
  if valid_614267 != nil:
    section.add "segment-id", valid_614267
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
  var valid_614268 = header.getOrDefault("X-Amz-Signature")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Signature", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Content-Sha256", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Date")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Date", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Credential")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Credential", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Security-Token")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Security-Token", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Algorithm")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Algorithm", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-SignedHeaders", valid_614274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614275: Call_GetSegment_614263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_614275.validator(path, query, header, formData, body)
  let scheme = call_614275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614275.url(scheme.get, call_614275.host, call_614275.base,
                         call_614275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614275, url, valid)

proc call*(call_614276: Call_GetSegment_614263; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_614277 = newJObject()
  add(path_614277, "application-id", newJString(applicationId))
  add(path_614277, "segment-id", newJString(segmentId))
  result = call_614276.call(path_614277, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_614263(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_614264,
                                      base: "/", url: url_GetSegment_614265,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_614295 = ref object of OpenApiRestCall_612642
proc url_DeleteSegment_614297(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSegment_614296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614298 = path.getOrDefault("application-id")
  valid_614298 = validateParameter(valid_614298, JString, required = true,
                                 default = nil)
  if valid_614298 != nil:
    section.add "application-id", valid_614298
  var valid_614299 = path.getOrDefault("segment-id")
  valid_614299 = validateParameter(valid_614299, JString, required = true,
                                 default = nil)
  if valid_614299 != nil:
    section.add "segment-id", valid_614299
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
  var valid_614300 = header.getOrDefault("X-Amz-Signature")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Signature", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Content-Sha256", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Date")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Date", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Credential")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Credential", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Security-Token")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Security-Token", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Algorithm")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Algorithm", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-SignedHeaders", valid_614306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614307: Call_DeleteSegment_614295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_614307.validator(path, query, header, formData, body)
  let scheme = call_614307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614307.url(scheme.get, call_614307.host, call_614307.base,
                         call_614307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614307, url, valid)

proc call*(call_614308: Call_DeleteSegment_614295; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_614309 = newJObject()
  add(path_614309, "application-id", newJString(applicationId))
  add(path_614309, "segment-id", newJString(segmentId))
  result = call_614308.call(path_614309, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_614295(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_614296, base: "/", url: url_DeleteSegment_614297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_614324 = ref object of OpenApiRestCall_612642
proc url_UpdateSmsChannel_614326(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSmsChannel_614325(path: JsonNode; query: JsonNode;
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
  var valid_614327 = path.getOrDefault("application-id")
  valid_614327 = validateParameter(valid_614327, JString, required = true,
                                 default = nil)
  if valid_614327 != nil:
    section.add "application-id", valid_614327
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
  var valid_614328 = header.getOrDefault("X-Amz-Signature")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "X-Amz-Signature", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Content-Sha256", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Date")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Date", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Credential")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Credential", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Security-Token")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Security-Token", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Algorithm")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Algorithm", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-SignedHeaders", valid_614334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614336: Call_UpdateSmsChannel_614324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_614336.validator(path, query, header, formData, body)
  let scheme = call_614336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614336.url(scheme.get, call_614336.host, call_614336.base,
                         call_614336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614336, url, valid)

proc call*(call_614337: Call_UpdateSmsChannel_614324; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614338 = newJObject()
  var body_614339 = newJObject()
  add(path_614338, "application-id", newJString(applicationId))
  if body != nil:
    body_614339 = body
  result = call_614337.call(path_614338, nil, nil, nil, body_614339)

var updateSmsChannel* = Call_UpdateSmsChannel_614324(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_614325, base: "/",
    url: url_UpdateSmsChannel_614326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_614310 = ref object of OpenApiRestCall_612642
proc url_GetSmsChannel_614312(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSmsChannel_614311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614313 = path.getOrDefault("application-id")
  valid_614313 = validateParameter(valid_614313, JString, required = true,
                                 default = nil)
  if valid_614313 != nil:
    section.add "application-id", valid_614313
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
  var valid_614314 = header.getOrDefault("X-Amz-Signature")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Signature", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Content-Sha256", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Date")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Date", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Credential")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Credential", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Security-Token")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Security-Token", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Algorithm")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Algorithm", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-SignedHeaders", valid_614320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614321: Call_GetSmsChannel_614310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_614321.validator(path, query, header, formData, body)
  let scheme = call_614321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614321.url(scheme.get, call_614321.host, call_614321.base,
                         call_614321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614321, url, valid)

proc call*(call_614322: Call_GetSmsChannel_614310; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614323 = newJObject()
  add(path_614323, "application-id", newJString(applicationId))
  result = call_614322.call(path_614323, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_614310(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_614311, base: "/", url: url_GetSmsChannel_614312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_614340 = ref object of OpenApiRestCall_612642
proc url_DeleteSmsChannel_614342(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSmsChannel_614341(path: JsonNode; query: JsonNode;
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
  var valid_614343 = path.getOrDefault("application-id")
  valid_614343 = validateParameter(valid_614343, JString, required = true,
                                 default = nil)
  if valid_614343 != nil:
    section.add "application-id", valid_614343
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
  var valid_614344 = header.getOrDefault("X-Amz-Signature")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Signature", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-Content-Sha256", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Date")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Date", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Credential")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Credential", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Security-Token")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Security-Token", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Algorithm")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Algorithm", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-SignedHeaders", valid_614350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614351: Call_DeleteSmsChannel_614340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_614351.validator(path, query, header, formData, body)
  let scheme = call_614351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614351.url(scheme.get, call_614351.host, call_614351.base,
                         call_614351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614351, url, valid)

proc call*(call_614352: Call_DeleteSmsChannel_614340; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614353 = newJObject()
  add(path_614353, "application-id", newJString(applicationId))
  result = call_614352.call(path_614353, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_614340(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_614341, base: "/",
    url: url_DeleteSmsChannel_614342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_614354 = ref object of OpenApiRestCall_612642
proc url_GetUserEndpoints_614356(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUserEndpoints_614355(path: JsonNode; query: JsonNode;
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
  var valid_614357 = path.getOrDefault("application-id")
  valid_614357 = validateParameter(valid_614357, JString, required = true,
                                 default = nil)
  if valid_614357 != nil:
    section.add "application-id", valid_614357
  var valid_614358 = path.getOrDefault("user-id")
  valid_614358 = validateParameter(valid_614358, JString, required = true,
                                 default = nil)
  if valid_614358 != nil:
    section.add "user-id", valid_614358
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
  var valid_614359 = header.getOrDefault("X-Amz-Signature")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "X-Amz-Signature", valid_614359
  var valid_614360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "X-Amz-Content-Sha256", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-Date")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Date", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Credential")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Credential", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Security-Token")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Security-Token", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Algorithm")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Algorithm", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-SignedHeaders", valid_614365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614366: Call_GetUserEndpoints_614354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_614366.validator(path, query, header, formData, body)
  let scheme = call_614366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614366.url(scheme.get, call_614366.host, call_614366.base,
                         call_614366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614366, url, valid)

proc call*(call_614367: Call_GetUserEndpoints_614354; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_614368 = newJObject()
  add(path_614368, "application-id", newJString(applicationId))
  add(path_614368, "user-id", newJString(userId))
  result = call_614367.call(path_614368, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_614354(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_614355, base: "/",
    url: url_GetUserEndpoints_614356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_614369 = ref object of OpenApiRestCall_612642
proc url_DeleteUserEndpoints_614371(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserEndpoints_614370(path: JsonNode; query: JsonNode;
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
  var valid_614372 = path.getOrDefault("application-id")
  valid_614372 = validateParameter(valid_614372, JString, required = true,
                                 default = nil)
  if valid_614372 != nil:
    section.add "application-id", valid_614372
  var valid_614373 = path.getOrDefault("user-id")
  valid_614373 = validateParameter(valid_614373, JString, required = true,
                                 default = nil)
  if valid_614373 != nil:
    section.add "user-id", valid_614373
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
  var valid_614374 = header.getOrDefault("X-Amz-Signature")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Signature", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-Content-Sha256", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-Date")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-Date", valid_614376
  var valid_614377 = header.getOrDefault("X-Amz-Credential")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "X-Amz-Credential", valid_614377
  var valid_614378 = header.getOrDefault("X-Amz-Security-Token")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "X-Amz-Security-Token", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Algorithm")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Algorithm", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-SignedHeaders", valid_614380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614381: Call_DeleteUserEndpoints_614369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_614381.validator(path, query, header, formData, body)
  let scheme = call_614381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614381.url(scheme.get, call_614381.host, call_614381.base,
                         call_614381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614381, url, valid)

proc call*(call_614382: Call_DeleteUserEndpoints_614369; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_614383 = newJObject()
  add(path_614383, "application-id", newJString(applicationId))
  add(path_614383, "user-id", newJString(userId))
  result = call_614382.call(path_614383, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_614369(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_614370, base: "/",
    url: url_DeleteUserEndpoints_614371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_614398 = ref object of OpenApiRestCall_612642
proc url_UpdateVoiceChannel_614400(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceChannel_614399(path: JsonNode; query: JsonNode;
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
  var valid_614401 = path.getOrDefault("application-id")
  valid_614401 = validateParameter(valid_614401, JString, required = true,
                                 default = nil)
  if valid_614401 != nil:
    section.add "application-id", valid_614401
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
  var valid_614402 = header.getOrDefault("X-Amz-Signature")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Signature", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Content-Sha256", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Date")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Date", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-Credential")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Credential", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Security-Token")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Security-Token", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Algorithm")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Algorithm", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-SignedHeaders", valid_614408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614410: Call_UpdateVoiceChannel_614398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_614410.validator(path, query, header, formData, body)
  let scheme = call_614410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614410.url(scheme.get, call_614410.host, call_614410.base,
                         call_614410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614410, url, valid)

proc call*(call_614411: Call_UpdateVoiceChannel_614398; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614412 = newJObject()
  var body_614413 = newJObject()
  add(path_614412, "application-id", newJString(applicationId))
  if body != nil:
    body_614413 = body
  result = call_614411.call(path_614412, nil, nil, nil, body_614413)

var updateVoiceChannel* = Call_UpdateVoiceChannel_614398(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_614399, base: "/",
    url: url_UpdateVoiceChannel_614400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_614384 = ref object of OpenApiRestCall_612642
proc url_GetVoiceChannel_614386(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceChannel_614385(path: JsonNode; query: JsonNode;
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
  var valid_614387 = path.getOrDefault("application-id")
  valid_614387 = validateParameter(valid_614387, JString, required = true,
                                 default = nil)
  if valid_614387 != nil:
    section.add "application-id", valid_614387
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
  var valid_614388 = header.getOrDefault("X-Amz-Signature")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Signature", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Content-Sha256", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-Date")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Date", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Credential")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Credential", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-Security-Token")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-Security-Token", valid_614392
  var valid_614393 = header.getOrDefault("X-Amz-Algorithm")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Algorithm", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-SignedHeaders", valid_614394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614395: Call_GetVoiceChannel_614384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_614395.validator(path, query, header, formData, body)
  let scheme = call_614395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614395.url(scheme.get, call_614395.host, call_614395.base,
                         call_614395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614395, url, valid)

proc call*(call_614396: Call_GetVoiceChannel_614384; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614397 = newJObject()
  add(path_614397, "application-id", newJString(applicationId))
  result = call_614396.call(path_614397, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_614384(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_614385, base: "/", url: url_GetVoiceChannel_614386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_614414 = ref object of OpenApiRestCall_612642
proc url_DeleteVoiceChannel_614416(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceChannel_614415(path: JsonNode; query: JsonNode;
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
  var valid_614417 = path.getOrDefault("application-id")
  valid_614417 = validateParameter(valid_614417, JString, required = true,
                                 default = nil)
  if valid_614417 != nil:
    section.add "application-id", valid_614417
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
  var valid_614418 = header.getOrDefault("X-Amz-Signature")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Signature", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Content-Sha256", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Date")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Date", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Credential")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Credential", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Security-Token")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Security-Token", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Algorithm")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Algorithm", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-SignedHeaders", valid_614424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614425: Call_DeleteVoiceChannel_614414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_614425.validator(path, query, header, formData, body)
  let scheme = call_614425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614425.url(scheme.get, call_614425.host, call_614425.base,
                         call_614425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614425, url, valid)

proc call*(call_614426: Call_DeleteVoiceChannel_614414; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614427 = newJObject()
  add(path_614427, "application-id", newJString(applicationId))
  result = call_614426.call(path_614427, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_614414(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_614415, base: "/",
    url: url_DeleteVoiceChannel_614416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_614428 = ref object of OpenApiRestCall_612642
proc url_GetApplicationDateRangeKpi_614430(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplicationDateRangeKpi_614429(path: JsonNode; query: JsonNode;
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
  var valid_614431 = path.getOrDefault("kpi-name")
  valid_614431 = validateParameter(valid_614431, JString, required = true,
                                 default = nil)
  if valid_614431 != nil:
    section.add "kpi-name", valid_614431
  var valid_614432 = path.getOrDefault("application-id")
  valid_614432 = validateParameter(valid_614432, JString, required = true,
                                 default = nil)
  if valid_614432 != nil:
    section.add "application-id", valid_614432
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
  var valid_614433 = query.getOrDefault("end-time")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "end-time", valid_614433
  var valid_614434 = query.getOrDefault("page-size")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "page-size", valid_614434
  var valid_614435 = query.getOrDefault("start-time")
  valid_614435 = validateParameter(valid_614435, JString, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "start-time", valid_614435
  var valid_614436 = query.getOrDefault("next-token")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "next-token", valid_614436
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
  var valid_614437 = header.getOrDefault("X-Amz-Signature")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Signature", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Content-Sha256", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Date")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Date", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Credential")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Credential", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Security-Token")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Security-Token", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Algorithm")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Algorithm", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-SignedHeaders", valid_614443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614444: Call_GetApplicationDateRangeKpi_614428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_614444.validator(path, query, header, formData, body)
  let scheme = call_614444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614444.url(scheme.get, call_614444.host, call_614444.base,
                         call_614444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614444, url, valid)

proc call*(call_614445: Call_GetApplicationDateRangeKpi_614428; kpiName: string;
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
  var path_614446 = newJObject()
  var query_614447 = newJObject()
  add(path_614446, "kpi-name", newJString(kpiName))
  add(path_614446, "application-id", newJString(applicationId))
  add(query_614447, "end-time", newJString(endTime))
  add(query_614447, "page-size", newJString(pageSize))
  add(query_614447, "start-time", newJString(startTime))
  add(query_614447, "next-token", newJString(nextToken))
  result = call_614445.call(path_614446, query_614447, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_614428(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_614429, base: "/",
    url: url_GetApplicationDateRangeKpi_614430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_614462 = ref object of OpenApiRestCall_612642
proc url_UpdateApplicationSettings_614464(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApplicationSettings_614463(path: JsonNode; query: JsonNode;
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
  var valid_614465 = path.getOrDefault("application-id")
  valid_614465 = validateParameter(valid_614465, JString, required = true,
                                 default = nil)
  if valid_614465 != nil:
    section.add "application-id", valid_614465
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
  var valid_614466 = header.getOrDefault("X-Amz-Signature")
  valid_614466 = validateParameter(valid_614466, JString, required = false,
                                 default = nil)
  if valid_614466 != nil:
    section.add "X-Amz-Signature", valid_614466
  var valid_614467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "X-Amz-Content-Sha256", valid_614467
  var valid_614468 = header.getOrDefault("X-Amz-Date")
  valid_614468 = validateParameter(valid_614468, JString, required = false,
                                 default = nil)
  if valid_614468 != nil:
    section.add "X-Amz-Date", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Credential")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Credential", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Security-Token")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Security-Token", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Algorithm")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Algorithm", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-SignedHeaders", valid_614472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614474: Call_UpdateApplicationSettings_614462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_614474.validator(path, query, header, formData, body)
  let scheme = call_614474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614474.url(scheme.get, call_614474.host, call_614474.base,
                         call_614474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614474, url, valid)

proc call*(call_614475: Call_UpdateApplicationSettings_614462;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614476 = newJObject()
  var body_614477 = newJObject()
  add(path_614476, "application-id", newJString(applicationId))
  if body != nil:
    body_614477 = body
  result = call_614475.call(path_614476, nil, nil, nil, body_614477)

var updateApplicationSettings* = Call_UpdateApplicationSettings_614462(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_614463, base: "/",
    url: url_UpdateApplicationSettings_614464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_614448 = ref object of OpenApiRestCall_612642
proc url_GetApplicationSettings_614450(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplicationSettings_614449(path: JsonNode; query: JsonNode;
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
  var valid_614451 = path.getOrDefault("application-id")
  valid_614451 = validateParameter(valid_614451, JString, required = true,
                                 default = nil)
  if valid_614451 != nil:
    section.add "application-id", valid_614451
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
  var valid_614452 = header.getOrDefault("X-Amz-Signature")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Signature", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Content-Sha256", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Date")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Date", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Credential")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Credential", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Security-Token")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Security-Token", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Algorithm")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Algorithm", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-SignedHeaders", valid_614458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614459: Call_GetApplicationSettings_614448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_614459.validator(path, query, header, formData, body)
  let scheme = call_614459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614459.url(scheme.get, call_614459.host, call_614459.base,
                         call_614459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614459, url, valid)

proc call*(call_614460: Call_GetApplicationSettings_614448; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614461 = newJObject()
  add(path_614461, "application-id", newJString(applicationId))
  result = call_614460.call(path_614461, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_614448(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_614449, base: "/",
    url: url_GetApplicationSettings_614450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_614478 = ref object of OpenApiRestCall_612642
proc url_GetCampaignActivities_614480(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignActivities_614479(path: JsonNode; query: JsonNode;
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
  var valid_614481 = path.getOrDefault("application-id")
  valid_614481 = validateParameter(valid_614481, JString, required = true,
                                 default = nil)
  if valid_614481 != nil:
    section.add "application-id", valid_614481
  var valid_614482 = path.getOrDefault("campaign-id")
  valid_614482 = validateParameter(valid_614482, JString, required = true,
                                 default = nil)
  if valid_614482 != nil:
    section.add "campaign-id", valid_614482
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_614483 = query.getOrDefault("page-size")
  valid_614483 = validateParameter(valid_614483, JString, required = false,
                                 default = nil)
  if valid_614483 != nil:
    section.add "page-size", valid_614483
  var valid_614484 = query.getOrDefault("token")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "token", valid_614484
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
  var valid_614485 = header.getOrDefault("X-Amz-Signature")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "X-Amz-Signature", valid_614485
  var valid_614486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Content-Sha256", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Date")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Date", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Credential")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Credential", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Security-Token")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Security-Token", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Algorithm")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Algorithm", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-SignedHeaders", valid_614491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614492: Call_GetCampaignActivities_614478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_614492.validator(path, query, header, formData, body)
  let scheme = call_614492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614492.url(scheme.get, call_614492.host, call_614492.base,
                         call_614492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614492, url, valid)

proc call*(call_614493: Call_GetCampaignActivities_614478; applicationId: string;
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
  var path_614494 = newJObject()
  var query_614495 = newJObject()
  add(path_614494, "application-id", newJString(applicationId))
  add(query_614495, "page-size", newJString(pageSize))
  add(path_614494, "campaign-id", newJString(campaignId))
  add(query_614495, "token", newJString(token))
  result = call_614493.call(path_614494, query_614495, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_614478(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_614479, base: "/",
    url: url_GetCampaignActivities_614480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_614496 = ref object of OpenApiRestCall_612642
proc url_GetCampaignDateRangeKpi_614498(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignDateRangeKpi_614497(path: JsonNode; query: JsonNode;
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
  var valid_614499 = path.getOrDefault("kpi-name")
  valid_614499 = validateParameter(valid_614499, JString, required = true,
                                 default = nil)
  if valid_614499 != nil:
    section.add "kpi-name", valid_614499
  var valid_614500 = path.getOrDefault("application-id")
  valid_614500 = validateParameter(valid_614500, JString, required = true,
                                 default = nil)
  if valid_614500 != nil:
    section.add "application-id", valid_614500
  var valid_614501 = path.getOrDefault("campaign-id")
  valid_614501 = validateParameter(valid_614501, JString, required = true,
                                 default = nil)
  if valid_614501 != nil:
    section.add "campaign-id", valid_614501
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
  var valid_614502 = query.getOrDefault("end-time")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "end-time", valid_614502
  var valid_614503 = query.getOrDefault("page-size")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "page-size", valid_614503
  var valid_614504 = query.getOrDefault("start-time")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "start-time", valid_614504
  var valid_614505 = query.getOrDefault("next-token")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "next-token", valid_614505
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
  var valid_614506 = header.getOrDefault("X-Amz-Signature")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Signature", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Content-Sha256", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Date")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Date", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Credential")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Credential", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Security-Token")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Security-Token", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Algorithm")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Algorithm", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-SignedHeaders", valid_614512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614513: Call_GetCampaignDateRangeKpi_614496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_614513.validator(path, query, header, formData, body)
  let scheme = call_614513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614513.url(scheme.get, call_614513.host, call_614513.base,
                         call_614513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614513, url, valid)

proc call*(call_614514: Call_GetCampaignDateRangeKpi_614496; kpiName: string;
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
  var path_614515 = newJObject()
  var query_614516 = newJObject()
  add(path_614515, "kpi-name", newJString(kpiName))
  add(path_614515, "application-id", newJString(applicationId))
  add(query_614516, "end-time", newJString(endTime))
  add(query_614516, "page-size", newJString(pageSize))
  add(path_614515, "campaign-id", newJString(campaignId))
  add(query_614516, "start-time", newJString(startTime))
  add(query_614516, "next-token", newJString(nextToken))
  result = call_614514.call(path_614515, query_614516, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_614496(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_614497, base: "/",
    url: url_GetCampaignDateRangeKpi_614498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_614517 = ref object of OpenApiRestCall_612642
proc url_GetCampaignVersion_614519(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignVersion_614518(path: JsonNode; query: JsonNode;
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
  var valid_614520 = path.getOrDefault("version")
  valid_614520 = validateParameter(valid_614520, JString, required = true,
                                 default = nil)
  if valid_614520 != nil:
    section.add "version", valid_614520
  var valid_614521 = path.getOrDefault("application-id")
  valid_614521 = validateParameter(valid_614521, JString, required = true,
                                 default = nil)
  if valid_614521 != nil:
    section.add "application-id", valid_614521
  var valid_614522 = path.getOrDefault("campaign-id")
  valid_614522 = validateParameter(valid_614522, JString, required = true,
                                 default = nil)
  if valid_614522 != nil:
    section.add "campaign-id", valid_614522
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
  var valid_614523 = header.getOrDefault("X-Amz-Signature")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Signature", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-Content-Sha256", valid_614524
  var valid_614525 = header.getOrDefault("X-Amz-Date")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "X-Amz-Date", valid_614525
  var valid_614526 = header.getOrDefault("X-Amz-Credential")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "X-Amz-Credential", valid_614526
  var valid_614527 = header.getOrDefault("X-Amz-Security-Token")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "X-Amz-Security-Token", valid_614527
  var valid_614528 = header.getOrDefault("X-Amz-Algorithm")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "X-Amz-Algorithm", valid_614528
  var valid_614529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-SignedHeaders", valid_614529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614530: Call_GetCampaignVersion_614517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_614530.validator(path, query, header, formData, body)
  let scheme = call_614530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614530.url(scheme.get, call_614530.host, call_614530.base,
                         call_614530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614530, url, valid)

proc call*(call_614531: Call_GetCampaignVersion_614517; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_614532 = newJObject()
  add(path_614532, "version", newJString(version))
  add(path_614532, "application-id", newJString(applicationId))
  add(path_614532, "campaign-id", newJString(campaignId))
  result = call_614531.call(path_614532, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_614517(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_614518, base: "/",
    url: url_GetCampaignVersion_614519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_614533 = ref object of OpenApiRestCall_612642
proc url_GetCampaignVersions_614535(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCampaignVersions_614534(path: JsonNode; query: JsonNode;
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
  var valid_614536 = path.getOrDefault("application-id")
  valid_614536 = validateParameter(valid_614536, JString, required = true,
                                 default = nil)
  if valid_614536 != nil:
    section.add "application-id", valid_614536
  var valid_614537 = path.getOrDefault("campaign-id")
  valid_614537 = validateParameter(valid_614537, JString, required = true,
                                 default = nil)
  if valid_614537 != nil:
    section.add "campaign-id", valid_614537
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_614538 = query.getOrDefault("page-size")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "page-size", valid_614538
  var valid_614539 = query.getOrDefault("token")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "token", valid_614539
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
  var valid_614540 = header.getOrDefault("X-Amz-Signature")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Signature", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Content-Sha256", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-Date")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-Date", valid_614542
  var valid_614543 = header.getOrDefault("X-Amz-Credential")
  valid_614543 = validateParameter(valid_614543, JString, required = false,
                                 default = nil)
  if valid_614543 != nil:
    section.add "X-Amz-Credential", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Security-Token")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Security-Token", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-Algorithm")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-Algorithm", valid_614545
  var valid_614546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-SignedHeaders", valid_614546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614547: Call_GetCampaignVersions_614533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_614547.validator(path, query, header, formData, body)
  let scheme = call_614547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614547.url(scheme.get, call_614547.host, call_614547.base,
                         call_614547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614547, url, valid)

proc call*(call_614548: Call_GetCampaignVersions_614533; applicationId: string;
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
  var path_614549 = newJObject()
  var query_614550 = newJObject()
  add(path_614549, "application-id", newJString(applicationId))
  add(query_614550, "page-size", newJString(pageSize))
  add(path_614549, "campaign-id", newJString(campaignId))
  add(query_614550, "token", newJString(token))
  result = call_614548.call(path_614549, query_614550, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_614533(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_614534, base: "/",
    url: url_GetCampaignVersions_614535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_614551 = ref object of OpenApiRestCall_612642
proc url_GetChannels_614553(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChannels_614552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614554 = path.getOrDefault("application-id")
  valid_614554 = validateParameter(valid_614554, JString, required = true,
                                 default = nil)
  if valid_614554 != nil:
    section.add "application-id", valid_614554
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
  var valid_614555 = header.getOrDefault("X-Amz-Signature")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Signature", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-Content-Sha256", valid_614556
  var valid_614557 = header.getOrDefault("X-Amz-Date")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "X-Amz-Date", valid_614557
  var valid_614558 = header.getOrDefault("X-Amz-Credential")
  valid_614558 = validateParameter(valid_614558, JString, required = false,
                                 default = nil)
  if valid_614558 != nil:
    section.add "X-Amz-Credential", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Security-Token")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Security-Token", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-Algorithm")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-Algorithm", valid_614560
  var valid_614561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-SignedHeaders", valid_614561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614562: Call_GetChannels_614551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_614562.validator(path, query, header, formData, body)
  let scheme = call_614562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614562.url(scheme.get, call_614562.host, call_614562.base,
                         call_614562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614562, url, valid)

proc call*(call_614563: Call_GetChannels_614551; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614564 = newJObject()
  add(path_614564, "application-id", newJString(applicationId))
  result = call_614563.call(path_614564, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_614551(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_614552,
                                        base: "/", url: url_GetChannels_614553,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_614565 = ref object of OpenApiRestCall_612642
proc url_GetExportJob_614567(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetExportJob_614566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614568 = path.getOrDefault("job-id")
  valid_614568 = validateParameter(valid_614568, JString, required = true,
                                 default = nil)
  if valid_614568 != nil:
    section.add "job-id", valid_614568
  var valid_614569 = path.getOrDefault("application-id")
  valid_614569 = validateParameter(valid_614569, JString, required = true,
                                 default = nil)
  if valid_614569 != nil:
    section.add "application-id", valid_614569
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
  var valid_614570 = header.getOrDefault("X-Amz-Signature")
  valid_614570 = validateParameter(valid_614570, JString, required = false,
                                 default = nil)
  if valid_614570 != nil:
    section.add "X-Amz-Signature", valid_614570
  var valid_614571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "X-Amz-Content-Sha256", valid_614571
  var valid_614572 = header.getOrDefault("X-Amz-Date")
  valid_614572 = validateParameter(valid_614572, JString, required = false,
                                 default = nil)
  if valid_614572 != nil:
    section.add "X-Amz-Date", valid_614572
  var valid_614573 = header.getOrDefault("X-Amz-Credential")
  valid_614573 = validateParameter(valid_614573, JString, required = false,
                                 default = nil)
  if valid_614573 != nil:
    section.add "X-Amz-Credential", valid_614573
  var valid_614574 = header.getOrDefault("X-Amz-Security-Token")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "X-Amz-Security-Token", valid_614574
  var valid_614575 = header.getOrDefault("X-Amz-Algorithm")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "X-Amz-Algorithm", valid_614575
  var valid_614576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614576 = validateParameter(valid_614576, JString, required = false,
                                 default = nil)
  if valid_614576 != nil:
    section.add "X-Amz-SignedHeaders", valid_614576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614577: Call_GetExportJob_614565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_614577.validator(path, query, header, formData, body)
  let scheme = call_614577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614577.url(scheme.get, call_614577.host, call_614577.base,
                         call_614577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614577, url, valid)

proc call*(call_614578: Call_GetExportJob_614565; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614579 = newJObject()
  add(path_614579, "job-id", newJString(jobId))
  add(path_614579, "application-id", newJString(applicationId))
  result = call_614578.call(path_614579, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_614565(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_614566, base: "/", url: url_GetExportJob_614567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_614580 = ref object of OpenApiRestCall_612642
proc url_GetImportJob_614582(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImportJob_614581(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614583 = path.getOrDefault("job-id")
  valid_614583 = validateParameter(valid_614583, JString, required = true,
                                 default = nil)
  if valid_614583 != nil:
    section.add "job-id", valid_614583
  var valid_614584 = path.getOrDefault("application-id")
  valid_614584 = validateParameter(valid_614584, JString, required = true,
                                 default = nil)
  if valid_614584 != nil:
    section.add "application-id", valid_614584
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
  var valid_614585 = header.getOrDefault("X-Amz-Signature")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-Signature", valid_614585
  var valid_614586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614586 = validateParameter(valid_614586, JString, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "X-Amz-Content-Sha256", valid_614586
  var valid_614587 = header.getOrDefault("X-Amz-Date")
  valid_614587 = validateParameter(valid_614587, JString, required = false,
                                 default = nil)
  if valid_614587 != nil:
    section.add "X-Amz-Date", valid_614587
  var valid_614588 = header.getOrDefault("X-Amz-Credential")
  valid_614588 = validateParameter(valid_614588, JString, required = false,
                                 default = nil)
  if valid_614588 != nil:
    section.add "X-Amz-Credential", valid_614588
  var valid_614589 = header.getOrDefault("X-Amz-Security-Token")
  valid_614589 = validateParameter(valid_614589, JString, required = false,
                                 default = nil)
  if valid_614589 != nil:
    section.add "X-Amz-Security-Token", valid_614589
  var valid_614590 = header.getOrDefault("X-Amz-Algorithm")
  valid_614590 = validateParameter(valid_614590, JString, required = false,
                                 default = nil)
  if valid_614590 != nil:
    section.add "X-Amz-Algorithm", valid_614590
  var valid_614591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614591 = validateParameter(valid_614591, JString, required = false,
                                 default = nil)
  if valid_614591 != nil:
    section.add "X-Amz-SignedHeaders", valid_614591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614592: Call_GetImportJob_614580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_614592.validator(path, query, header, formData, body)
  let scheme = call_614592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614592.url(scheme.get, call_614592.host, call_614592.base,
                         call_614592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614592, url, valid)

proc call*(call_614593: Call_GetImportJob_614580; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_614594 = newJObject()
  add(path_614594, "job-id", newJString(jobId))
  add(path_614594, "application-id", newJString(applicationId))
  result = call_614593.call(path_614594, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_614580(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_614581, base: "/", url: url_GetImportJob_614582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_614595 = ref object of OpenApiRestCall_612642
proc url_GetJourneyDateRangeKpi_614597(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyDateRangeKpi_614596(path: JsonNode; query: JsonNode;
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
  var valid_614598 = path.getOrDefault("kpi-name")
  valid_614598 = validateParameter(valid_614598, JString, required = true,
                                 default = nil)
  if valid_614598 != nil:
    section.add "kpi-name", valid_614598
  var valid_614599 = path.getOrDefault("application-id")
  valid_614599 = validateParameter(valid_614599, JString, required = true,
                                 default = nil)
  if valid_614599 != nil:
    section.add "application-id", valid_614599
  var valid_614600 = path.getOrDefault("journey-id")
  valid_614600 = validateParameter(valid_614600, JString, required = true,
                                 default = nil)
  if valid_614600 != nil:
    section.add "journey-id", valid_614600
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
  var valid_614601 = query.getOrDefault("end-time")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "end-time", valid_614601
  var valid_614602 = query.getOrDefault("page-size")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "page-size", valid_614602
  var valid_614603 = query.getOrDefault("start-time")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "start-time", valid_614603
  var valid_614604 = query.getOrDefault("next-token")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "next-token", valid_614604
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
  var valid_614605 = header.getOrDefault("X-Amz-Signature")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "X-Amz-Signature", valid_614605
  var valid_614606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "X-Amz-Content-Sha256", valid_614606
  var valid_614607 = header.getOrDefault("X-Amz-Date")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Date", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-Credential")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-Credential", valid_614608
  var valid_614609 = header.getOrDefault("X-Amz-Security-Token")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "X-Amz-Security-Token", valid_614609
  var valid_614610 = header.getOrDefault("X-Amz-Algorithm")
  valid_614610 = validateParameter(valid_614610, JString, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "X-Amz-Algorithm", valid_614610
  var valid_614611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614611 = validateParameter(valid_614611, JString, required = false,
                                 default = nil)
  if valid_614611 != nil:
    section.add "X-Amz-SignedHeaders", valid_614611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614612: Call_GetJourneyDateRangeKpi_614595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_614612.validator(path, query, header, formData, body)
  let scheme = call_614612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614612.url(scheme.get, call_614612.host, call_614612.base,
                         call_614612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614612, url, valid)

proc call*(call_614613: Call_GetJourneyDateRangeKpi_614595; kpiName: string;
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
  var path_614614 = newJObject()
  var query_614615 = newJObject()
  add(path_614614, "kpi-name", newJString(kpiName))
  add(path_614614, "application-id", newJString(applicationId))
  add(query_614615, "end-time", newJString(endTime))
  add(query_614615, "page-size", newJString(pageSize))
  add(path_614614, "journey-id", newJString(journeyId))
  add(query_614615, "start-time", newJString(startTime))
  add(query_614615, "next-token", newJString(nextToken))
  result = call_614613.call(path_614614, query_614615, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_614595(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_614596, base: "/",
    url: url_GetJourneyDateRangeKpi_614597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_614616 = ref object of OpenApiRestCall_612642
proc url_GetJourneyExecutionActivityMetrics_614618(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyExecutionActivityMetrics_614617(path: JsonNode;
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
  var valid_614619 = path.getOrDefault("application-id")
  valid_614619 = validateParameter(valid_614619, JString, required = true,
                                 default = nil)
  if valid_614619 != nil:
    section.add "application-id", valid_614619
  var valid_614620 = path.getOrDefault("journey-activity-id")
  valid_614620 = validateParameter(valid_614620, JString, required = true,
                                 default = nil)
  if valid_614620 != nil:
    section.add "journey-activity-id", valid_614620
  var valid_614621 = path.getOrDefault("journey-id")
  valid_614621 = validateParameter(valid_614621, JString, required = true,
                                 default = nil)
  if valid_614621 != nil:
    section.add "journey-id", valid_614621
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_614622 = query.getOrDefault("page-size")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "page-size", valid_614622
  var valid_614623 = query.getOrDefault("next-token")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "next-token", valid_614623
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
  var valid_614624 = header.getOrDefault("X-Amz-Signature")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-Signature", valid_614624
  var valid_614625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "X-Amz-Content-Sha256", valid_614625
  var valid_614626 = header.getOrDefault("X-Amz-Date")
  valid_614626 = validateParameter(valid_614626, JString, required = false,
                                 default = nil)
  if valid_614626 != nil:
    section.add "X-Amz-Date", valid_614626
  var valid_614627 = header.getOrDefault("X-Amz-Credential")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "X-Amz-Credential", valid_614627
  var valid_614628 = header.getOrDefault("X-Amz-Security-Token")
  valid_614628 = validateParameter(valid_614628, JString, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "X-Amz-Security-Token", valid_614628
  var valid_614629 = header.getOrDefault("X-Amz-Algorithm")
  valid_614629 = validateParameter(valid_614629, JString, required = false,
                                 default = nil)
  if valid_614629 != nil:
    section.add "X-Amz-Algorithm", valid_614629
  var valid_614630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614630 = validateParameter(valid_614630, JString, required = false,
                                 default = nil)
  if valid_614630 != nil:
    section.add "X-Amz-SignedHeaders", valid_614630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614631: Call_GetJourneyExecutionActivityMetrics_614616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_614631.validator(path, query, header, formData, body)
  let scheme = call_614631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614631.url(scheme.get, call_614631.host, call_614631.base,
                         call_614631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614631, url, valid)

proc call*(call_614632: Call_GetJourneyExecutionActivityMetrics_614616;
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
  var path_614633 = newJObject()
  var query_614634 = newJObject()
  add(path_614633, "application-id", newJString(applicationId))
  add(query_614634, "page-size", newJString(pageSize))
  add(path_614633, "journey-activity-id", newJString(journeyActivityId))
  add(path_614633, "journey-id", newJString(journeyId))
  add(query_614634, "next-token", newJString(nextToken))
  result = call_614632.call(path_614633, query_614634, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_614616(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_614617, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_614618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_614635 = ref object of OpenApiRestCall_612642
proc url_GetJourneyExecutionMetrics_614637(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJourneyExecutionMetrics_614636(path: JsonNode; query: JsonNode;
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
  var valid_614638 = path.getOrDefault("application-id")
  valid_614638 = validateParameter(valid_614638, JString, required = true,
                                 default = nil)
  if valid_614638 != nil:
    section.add "application-id", valid_614638
  var valid_614639 = path.getOrDefault("journey-id")
  valid_614639 = validateParameter(valid_614639, JString, required = true,
                                 default = nil)
  if valid_614639 != nil:
    section.add "journey-id", valid_614639
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_614640 = query.getOrDefault("page-size")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "page-size", valid_614640
  var valid_614641 = query.getOrDefault("next-token")
  valid_614641 = validateParameter(valid_614641, JString, required = false,
                                 default = nil)
  if valid_614641 != nil:
    section.add "next-token", valid_614641
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
  var valid_614642 = header.getOrDefault("X-Amz-Signature")
  valid_614642 = validateParameter(valid_614642, JString, required = false,
                                 default = nil)
  if valid_614642 != nil:
    section.add "X-Amz-Signature", valid_614642
  var valid_614643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614643 = validateParameter(valid_614643, JString, required = false,
                                 default = nil)
  if valid_614643 != nil:
    section.add "X-Amz-Content-Sha256", valid_614643
  var valid_614644 = header.getOrDefault("X-Amz-Date")
  valid_614644 = validateParameter(valid_614644, JString, required = false,
                                 default = nil)
  if valid_614644 != nil:
    section.add "X-Amz-Date", valid_614644
  var valid_614645 = header.getOrDefault("X-Amz-Credential")
  valid_614645 = validateParameter(valid_614645, JString, required = false,
                                 default = nil)
  if valid_614645 != nil:
    section.add "X-Amz-Credential", valid_614645
  var valid_614646 = header.getOrDefault("X-Amz-Security-Token")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "X-Amz-Security-Token", valid_614646
  var valid_614647 = header.getOrDefault("X-Amz-Algorithm")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "X-Amz-Algorithm", valid_614647
  var valid_614648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "X-Amz-SignedHeaders", valid_614648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614649: Call_GetJourneyExecutionMetrics_614635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_614649.validator(path, query, header, formData, body)
  let scheme = call_614649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614649.url(scheme.get, call_614649.host, call_614649.base,
                         call_614649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614649, url, valid)

proc call*(call_614650: Call_GetJourneyExecutionMetrics_614635;
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
  var path_614651 = newJObject()
  var query_614652 = newJObject()
  add(path_614651, "application-id", newJString(applicationId))
  add(query_614652, "page-size", newJString(pageSize))
  add(path_614651, "journey-id", newJString(journeyId))
  add(query_614652, "next-token", newJString(nextToken))
  result = call_614650.call(path_614651, query_614652, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_614635(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_614636, base: "/",
    url: url_GetJourneyExecutionMetrics_614637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_614653 = ref object of OpenApiRestCall_612642
proc url_GetSegmentExportJobs_614655(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentExportJobs_614654(path: JsonNode; query: JsonNode;
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
  var valid_614656 = path.getOrDefault("application-id")
  valid_614656 = validateParameter(valid_614656, JString, required = true,
                                 default = nil)
  if valid_614656 != nil:
    section.add "application-id", valid_614656
  var valid_614657 = path.getOrDefault("segment-id")
  valid_614657 = validateParameter(valid_614657, JString, required = true,
                                 default = nil)
  if valid_614657 != nil:
    section.add "segment-id", valid_614657
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_614658 = query.getOrDefault("page-size")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "page-size", valid_614658
  var valid_614659 = query.getOrDefault("token")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "token", valid_614659
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
  var valid_614660 = header.getOrDefault("X-Amz-Signature")
  valid_614660 = validateParameter(valid_614660, JString, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "X-Amz-Signature", valid_614660
  var valid_614661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "X-Amz-Content-Sha256", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-Date")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-Date", valid_614662
  var valid_614663 = header.getOrDefault("X-Amz-Credential")
  valid_614663 = validateParameter(valid_614663, JString, required = false,
                                 default = nil)
  if valid_614663 != nil:
    section.add "X-Amz-Credential", valid_614663
  var valid_614664 = header.getOrDefault("X-Amz-Security-Token")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "X-Amz-Security-Token", valid_614664
  var valid_614665 = header.getOrDefault("X-Amz-Algorithm")
  valid_614665 = validateParameter(valid_614665, JString, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "X-Amz-Algorithm", valid_614665
  var valid_614666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614666 = validateParameter(valid_614666, JString, required = false,
                                 default = nil)
  if valid_614666 != nil:
    section.add "X-Amz-SignedHeaders", valid_614666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614667: Call_GetSegmentExportJobs_614653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_614667.validator(path, query, header, formData, body)
  let scheme = call_614667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614667.url(scheme.get, call_614667.host, call_614667.base,
                         call_614667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614667, url, valid)

proc call*(call_614668: Call_GetSegmentExportJobs_614653; applicationId: string;
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
  var path_614669 = newJObject()
  var query_614670 = newJObject()
  add(path_614669, "application-id", newJString(applicationId))
  add(path_614669, "segment-id", newJString(segmentId))
  add(query_614670, "page-size", newJString(pageSize))
  add(query_614670, "token", newJString(token))
  result = call_614668.call(path_614669, query_614670, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_614653(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_614654, base: "/",
    url: url_GetSegmentExportJobs_614655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_614671 = ref object of OpenApiRestCall_612642
proc url_GetSegmentImportJobs_614673(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentImportJobs_614672(path: JsonNode; query: JsonNode;
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
  var valid_614674 = path.getOrDefault("application-id")
  valid_614674 = validateParameter(valid_614674, JString, required = true,
                                 default = nil)
  if valid_614674 != nil:
    section.add "application-id", valid_614674
  var valid_614675 = path.getOrDefault("segment-id")
  valid_614675 = validateParameter(valid_614675, JString, required = true,
                                 default = nil)
  if valid_614675 != nil:
    section.add "segment-id", valid_614675
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_614676 = query.getOrDefault("page-size")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "page-size", valid_614676
  var valid_614677 = query.getOrDefault("token")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "token", valid_614677
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
  var valid_614678 = header.getOrDefault("X-Amz-Signature")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "X-Amz-Signature", valid_614678
  var valid_614679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614679 = validateParameter(valid_614679, JString, required = false,
                                 default = nil)
  if valid_614679 != nil:
    section.add "X-Amz-Content-Sha256", valid_614679
  var valid_614680 = header.getOrDefault("X-Amz-Date")
  valid_614680 = validateParameter(valid_614680, JString, required = false,
                                 default = nil)
  if valid_614680 != nil:
    section.add "X-Amz-Date", valid_614680
  var valid_614681 = header.getOrDefault("X-Amz-Credential")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "X-Amz-Credential", valid_614681
  var valid_614682 = header.getOrDefault("X-Amz-Security-Token")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-Security-Token", valid_614682
  var valid_614683 = header.getOrDefault("X-Amz-Algorithm")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "X-Amz-Algorithm", valid_614683
  var valid_614684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614684 = validateParameter(valid_614684, JString, required = false,
                                 default = nil)
  if valid_614684 != nil:
    section.add "X-Amz-SignedHeaders", valid_614684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614685: Call_GetSegmentImportJobs_614671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_614685.validator(path, query, header, formData, body)
  let scheme = call_614685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614685.url(scheme.get, call_614685.host, call_614685.base,
                         call_614685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614685, url, valid)

proc call*(call_614686: Call_GetSegmentImportJobs_614671; applicationId: string;
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
  var path_614687 = newJObject()
  var query_614688 = newJObject()
  add(path_614687, "application-id", newJString(applicationId))
  add(path_614687, "segment-id", newJString(segmentId))
  add(query_614688, "page-size", newJString(pageSize))
  add(query_614688, "token", newJString(token))
  result = call_614686.call(path_614687, query_614688, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_614671(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_614672, base: "/",
    url: url_GetSegmentImportJobs_614673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_614689 = ref object of OpenApiRestCall_612642
proc url_GetSegmentVersion_614691(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentVersion_614690(path: JsonNode; query: JsonNode;
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
  var valid_614692 = path.getOrDefault("version")
  valid_614692 = validateParameter(valid_614692, JString, required = true,
                                 default = nil)
  if valid_614692 != nil:
    section.add "version", valid_614692
  var valid_614693 = path.getOrDefault("application-id")
  valid_614693 = validateParameter(valid_614693, JString, required = true,
                                 default = nil)
  if valid_614693 != nil:
    section.add "application-id", valid_614693
  var valid_614694 = path.getOrDefault("segment-id")
  valid_614694 = validateParameter(valid_614694, JString, required = true,
                                 default = nil)
  if valid_614694 != nil:
    section.add "segment-id", valid_614694
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
  var valid_614695 = header.getOrDefault("X-Amz-Signature")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Signature", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Content-Sha256", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Date")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Date", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-Credential")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-Credential", valid_614698
  var valid_614699 = header.getOrDefault("X-Amz-Security-Token")
  valid_614699 = validateParameter(valid_614699, JString, required = false,
                                 default = nil)
  if valid_614699 != nil:
    section.add "X-Amz-Security-Token", valid_614699
  var valid_614700 = header.getOrDefault("X-Amz-Algorithm")
  valid_614700 = validateParameter(valid_614700, JString, required = false,
                                 default = nil)
  if valid_614700 != nil:
    section.add "X-Amz-Algorithm", valid_614700
  var valid_614701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614701 = validateParameter(valid_614701, JString, required = false,
                                 default = nil)
  if valid_614701 != nil:
    section.add "X-Amz-SignedHeaders", valid_614701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614702: Call_GetSegmentVersion_614689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_614702.validator(path, query, header, formData, body)
  let scheme = call_614702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614702.url(scheme.get, call_614702.host, call_614702.base,
                         call_614702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614702, url, valid)

proc call*(call_614703: Call_GetSegmentVersion_614689; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_614704 = newJObject()
  add(path_614704, "version", newJString(version))
  add(path_614704, "application-id", newJString(applicationId))
  add(path_614704, "segment-id", newJString(segmentId))
  result = call_614703.call(path_614704, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_614689(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_614690, base: "/",
    url: url_GetSegmentVersion_614691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_614705 = ref object of OpenApiRestCall_612642
proc url_GetSegmentVersions_614707(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSegmentVersions_614706(path: JsonNode; query: JsonNode;
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
  var valid_614708 = path.getOrDefault("application-id")
  valid_614708 = validateParameter(valid_614708, JString, required = true,
                                 default = nil)
  if valid_614708 != nil:
    section.add "application-id", valid_614708
  var valid_614709 = path.getOrDefault("segment-id")
  valid_614709 = validateParameter(valid_614709, JString, required = true,
                                 default = nil)
  if valid_614709 != nil:
    section.add "segment-id", valid_614709
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_614710 = query.getOrDefault("page-size")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "page-size", valid_614710
  var valid_614711 = query.getOrDefault("token")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "token", valid_614711
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
  var valid_614712 = header.getOrDefault("X-Amz-Signature")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Signature", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-Content-Sha256", valid_614713
  var valid_614714 = header.getOrDefault("X-Amz-Date")
  valid_614714 = validateParameter(valid_614714, JString, required = false,
                                 default = nil)
  if valid_614714 != nil:
    section.add "X-Amz-Date", valid_614714
  var valid_614715 = header.getOrDefault("X-Amz-Credential")
  valid_614715 = validateParameter(valid_614715, JString, required = false,
                                 default = nil)
  if valid_614715 != nil:
    section.add "X-Amz-Credential", valid_614715
  var valid_614716 = header.getOrDefault("X-Amz-Security-Token")
  valid_614716 = validateParameter(valid_614716, JString, required = false,
                                 default = nil)
  if valid_614716 != nil:
    section.add "X-Amz-Security-Token", valid_614716
  var valid_614717 = header.getOrDefault("X-Amz-Algorithm")
  valid_614717 = validateParameter(valid_614717, JString, required = false,
                                 default = nil)
  if valid_614717 != nil:
    section.add "X-Amz-Algorithm", valid_614717
  var valid_614718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614718 = validateParameter(valid_614718, JString, required = false,
                                 default = nil)
  if valid_614718 != nil:
    section.add "X-Amz-SignedHeaders", valid_614718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614719: Call_GetSegmentVersions_614705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_614719.validator(path, query, header, formData, body)
  let scheme = call_614719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614719.url(scheme.get, call_614719.host, call_614719.base,
                         call_614719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614719, url, valid)

proc call*(call_614720: Call_GetSegmentVersions_614705; applicationId: string;
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
  var path_614721 = newJObject()
  var query_614722 = newJObject()
  add(path_614721, "application-id", newJString(applicationId))
  add(path_614721, "segment-id", newJString(segmentId))
  add(query_614722, "page-size", newJString(pageSize))
  add(query_614722, "token", newJString(token))
  result = call_614720.call(path_614721, query_614722, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_614705(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_614706, base: "/",
    url: url_GetSegmentVersions_614707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614737 = ref object of OpenApiRestCall_612642
proc url_TagResource_614739(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_614738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614740 = path.getOrDefault("resource-arn")
  valid_614740 = validateParameter(valid_614740, JString, required = true,
                                 default = nil)
  if valid_614740 != nil:
    section.add "resource-arn", valid_614740
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
  var valid_614741 = header.getOrDefault("X-Amz-Signature")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "X-Amz-Signature", valid_614741
  var valid_614742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "X-Amz-Content-Sha256", valid_614742
  var valid_614743 = header.getOrDefault("X-Amz-Date")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-Date", valid_614743
  var valid_614744 = header.getOrDefault("X-Amz-Credential")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Credential", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-Security-Token")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-Security-Token", valid_614745
  var valid_614746 = header.getOrDefault("X-Amz-Algorithm")
  valid_614746 = validateParameter(valid_614746, JString, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "X-Amz-Algorithm", valid_614746
  var valid_614747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "X-Amz-SignedHeaders", valid_614747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614749: Call_TagResource_614737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_614749.validator(path, query, header, formData, body)
  let scheme = call_614749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614749.url(scheme.get, call_614749.host, call_614749.base,
                         call_614749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614749, url, valid)

proc call*(call_614750: Call_TagResource_614737; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_614751 = newJObject()
  var body_614752 = newJObject()
  add(path_614751, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_614752 = body
  result = call_614750.call(path_614751, nil, nil, nil, body_614752)

var tagResource* = Call_TagResource_614737(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_614738,
                                        base: "/", url: url_TagResource_614739,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_614723 = ref object of OpenApiRestCall_612642
proc url_ListTagsForResource_614725(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_614724(path: JsonNode; query: JsonNode;
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
  var valid_614726 = path.getOrDefault("resource-arn")
  valid_614726 = validateParameter(valid_614726, JString, required = true,
                                 default = nil)
  if valid_614726 != nil:
    section.add "resource-arn", valid_614726
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
  var valid_614727 = header.getOrDefault("X-Amz-Signature")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-Signature", valid_614727
  var valid_614728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-Content-Sha256", valid_614728
  var valid_614729 = header.getOrDefault("X-Amz-Date")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Date", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-Credential")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-Credential", valid_614730
  var valid_614731 = header.getOrDefault("X-Amz-Security-Token")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Security-Token", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Algorithm")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Algorithm", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-SignedHeaders", valid_614733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614734: Call_ListTagsForResource_614723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_614734.validator(path, query, header, formData, body)
  let scheme = call_614734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614734.url(scheme.get, call_614734.host, call_614734.base,
                         call_614734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614734, url, valid)

proc call*(call_614735: Call_ListTagsForResource_614723; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_614736 = newJObject()
  add(path_614736, "resource-arn", newJString(resourceArn))
  result = call_614735.call(path_614736, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_614723(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_614724, base: "/",
    url: url_ListTagsForResource_614725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_614753 = ref object of OpenApiRestCall_612642
proc url_ListTemplateVersions_614755(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateVersions_614754(path: JsonNode; query: JsonNode;
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
  var valid_614756 = path.getOrDefault("template-type")
  valid_614756 = validateParameter(valid_614756, JString, required = true,
                                 default = nil)
  if valid_614756 != nil:
    section.add "template-type", valid_614756
  var valid_614757 = path.getOrDefault("template-name")
  valid_614757 = validateParameter(valid_614757, JString, required = true,
                                 default = nil)
  if valid_614757 != nil:
    section.add "template-name", valid_614757
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_614758 = query.getOrDefault("page-size")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "page-size", valid_614758
  var valid_614759 = query.getOrDefault("next-token")
  valid_614759 = validateParameter(valid_614759, JString, required = false,
                                 default = nil)
  if valid_614759 != nil:
    section.add "next-token", valid_614759
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
  var valid_614760 = header.getOrDefault("X-Amz-Signature")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "X-Amz-Signature", valid_614760
  var valid_614761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614761 = validateParameter(valid_614761, JString, required = false,
                                 default = nil)
  if valid_614761 != nil:
    section.add "X-Amz-Content-Sha256", valid_614761
  var valid_614762 = header.getOrDefault("X-Amz-Date")
  valid_614762 = validateParameter(valid_614762, JString, required = false,
                                 default = nil)
  if valid_614762 != nil:
    section.add "X-Amz-Date", valid_614762
  var valid_614763 = header.getOrDefault("X-Amz-Credential")
  valid_614763 = validateParameter(valid_614763, JString, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "X-Amz-Credential", valid_614763
  var valid_614764 = header.getOrDefault("X-Amz-Security-Token")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "X-Amz-Security-Token", valid_614764
  var valid_614765 = header.getOrDefault("X-Amz-Algorithm")
  valid_614765 = validateParameter(valid_614765, JString, required = false,
                                 default = nil)
  if valid_614765 != nil:
    section.add "X-Amz-Algorithm", valid_614765
  var valid_614766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-SignedHeaders", valid_614766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614767: Call_ListTemplateVersions_614753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_614767.validator(path, query, header, formData, body)
  let scheme = call_614767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614767.url(scheme.get, call_614767.host, call_614767.base,
                         call_614767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614767, url, valid)

proc call*(call_614768: Call_ListTemplateVersions_614753; templateType: string;
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
  var path_614769 = newJObject()
  var query_614770 = newJObject()
  add(path_614769, "template-type", newJString(templateType))
  add(path_614769, "template-name", newJString(templateName))
  add(query_614770, "page-size", newJString(pageSize))
  add(query_614770, "next-token", newJString(nextToken))
  result = call_614768.call(path_614769, query_614770, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_614753(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_614754, base: "/",
    url: url_ListTemplateVersions_614755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_614771 = ref object of OpenApiRestCall_612642
proc url_ListTemplates_614773(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTemplates_614772(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614774 = query.getOrDefault("prefix")
  valid_614774 = validateParameter(valid_614774, JString, required = false,
                                 default = nil)
  if valid_614774 != nil:
    section.add "prefix", valid_614774
  var valid_614775 = query.getOrDefault("page-size")
  valid_614775 = validateParameter(valid_614775, JString, required = false,
                                 default = nil)
  if valid_614775 != nil:
    section.add "page-size", valid_614775
  var valid_614776 = query.getOrDefault("template-type")
  valid_614776 = validateParameter(valid_614776, JString, required = false,
                                 default = nil)
  if valid_614776 != nil:
    section.add "template-type", valid_614776
  var valid_614777 = query.getOrDefault("next-token")
  valid_614777 = validateParameter(valid_614777, JString, required = false,
                                 default = nil)
  if valid_614777 != nil:
    section.add "next-token", valid_614777
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
  var valid_614778 = header.getOrDefault("X-Amz-Signature")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "X-Amz-Signature", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Content-Sha256", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-Date")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-Date", valid_614780
  var valid_614781 = header.getOrDefault("X-Amz-Credential")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Credential", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Security-Token")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Security-Token", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Algorithm")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Algorithm", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-SignedHeaders", valid_614784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614785: Call_ListTemplates_614771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_614785.validator(path, query, header, formData, body)
  let scheme = call_614785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614785.url(scheme.get, call_614785.host, call_614785.base,
                         call_614785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614785, url, valid)

proc call*(call_614786: Call_ListTemplates_614771; prefix: string = "";
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
  var query_614787 = newJObject()
  add(query_614787, "prefix", newJString(prefix))
  add(query_614787, "page-size", newJString(pageSize))
  add(query_614787, "template-type", newJString(templateType))
  add(query_614787, "next-token", newJString(nextToken))
  result = call_614786.call(nil, query_614787, nil, nil, nil)

var listTemplates* = Call_ListTemplates_614771(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_614772, base: "/",
    url: url_ListTemplates_614773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_614788 = ref object of OpenApiRestCall_612642
proc url_PhoneNumberValidate_614790(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PhoneNumberValidate_614789(path: JsonNode; query: JsonNode;
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
  var valid_614791 = header.getOrDefault("X-Amz-Signature")
  valid_614791 = validateParameter(valid_614791, JString, required = false,
                                 default = nil)
  if valid_614791 != nil:
    section.add "X-Amz-Signature", valid_614791
  var valid_614792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614792 = validateParameter(valid_614792, JString, required = false,
                                 default = nil)
  if valid_614792 != nil:
    section.add "X-Amz-Content-Sha256", valid_614792
  var valid_614793 = header.getOrDefault("X-Amz-Date")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "X-Amz-Date", valid_614793
  var valid_614794 = header.getOrDefault("X-Amz-Credential")
  valid_614794 = validateParameter(valid_614794, JString, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "X-Amz-Credential", valid_614794
  var valid_614795 = header.getOrDefault("X-Amz-Security-Token")
  valid_614795 = validateParameter(valid_614795, JString, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "X-Amz-Security-Token", valid_614795
  var valid_614796 = header.getOrDefault("X-Amz-Algorithm")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "X-Amz-Algorithm", valid_614796
  var valid_614797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "X-Amz-SignedHeaders", valid_614797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614799: Call_PhoneNumberValidate_614788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_614799.validator(path, query, header, formData, body)
  let scheme = call_614799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614799.url(scheme.get, call_614799.host, call_614799.base,
                         call_614799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614799, url, valid)

proc call*(call_614800: Call_PhoneNumberValidate_614788; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_614801 = newJObject()
  if body != nil:
    body_614801 = body
  result = call_614800.call(nil, nil, nil, nil, body_614801)

var phoneNumberValidate* = Call_PhoneNumberValidate_614788(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_614789, base: "/",
    url: url_PhoneNumberValidate_614790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_614802 = ref object of OpenApiRestCall_612642
proc url_PutEvents_614804(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEvents_614803(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614805 = path.getOrDefault("application-id")
  valid_614805 = validateParameter(valid_614805, JString, required = true,
                                 default = nil)
  if valid_614805 != nil:
    section.add "application-id", valid_614805
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
  var valid_614806 = header.getOrDefault("X-Amz-Signature")
  valid_614806 = validateParameter(valid_614806, JString, required = false,
                                 default = nil)
  if valid_614806 != nil:
    section.add "X-Amz-Signature", valid_614806
  var valid_614807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614807 = validateParameter(valid_614807, JString, required = false,
                                 default = nil)
  if valid_614807 != nil:
    section.add "X-Amz-Content-Sha256", valid_614807
  var valid_614808 = header.getOrDefault("X-Amz-Date")
  valid_614808 = validateParameter(valid_614808, JString, required = false,
                                 default = nil)
  if valid_614808 != nil:
    section.add "X-Amz-Date", valid_614808
  var valid_614809 = header.getOrDefault("X-Amz-Credential")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "X-Amz-Credential", valid_614809
  var valid_614810 = header.getOrDefault("X-Amz-Security-Token")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Security-Token", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Algorithm")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Algorithm", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-SignedHeaders", valid_614812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614814: Call_PutEvents_614802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_614814.validator(path, query, header, formData, body)
  let scheme = call_614814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614814.url(scheme.get, call_614814.host, call_614814.base,
                         call_614814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614814, url, valid)

proc call*(call_614815: Call_PutEvents_614802; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614816 = newJObject()
  var body_614817 = newJObject()
  add(path_614816, "application-id", newJString(applicationId))
  if body != nil:
    body_614817 = body
  result = call_614815.call(path_614816, nil, nil, nil, body_614817)

var putEvents* = Call_PutEvents_614802(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_614803,
                                    base: "/", url: url_PutEvents_614804,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_614818 = ref object of OpenApiRestCall_612642
proc url_RemoveAttributes_614820(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveAttributes_614819(path: JsonNode; query: JsonNode;
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
  var valid_614821 = path.getOrDefault("attribute-type")
  valid_614821 = validateParameter(valid_614821, JString, required = true,
                                 default = nil)
  if valid_614821 != nil:
    section.add "attribute-type", valid_614821
  var valid_614822 = path.getOrDefault("application-id")
  valid_614822 = validateParameter(valid_614822, JString, required = true,
                                 default = nil)
  if valid_614822 != nil:
    section.add "application-id", valid_614822
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
  var valid_614823 = header.getOrDefault("X-Amz-Signature")
  valid_614823 = validateParameter(valid_614823, JString, required = false,
                                 default = nil)
  if valid_614823 != nil:
    section.add "X-Amz-Signature", valid_614823
  var valid_614824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614824 = validateParameter(valid_614824, JString, required = false,
                                 default = nil)
  if valid_614824 != nil:
    section.add "X-Amz-Content-Sha256", valid_614824
  var valid_614825 = header.getOrDefault("X-Amz-Date")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Date", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-Credential")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-Credential", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Security-Token")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Security-Token", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Algorithm")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Algorithm", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-SignedHeaders", valid_614829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614831: Call_RemoveAttributes_614818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_614831.validator(path, query, header, formData, body)
  let scheme = call_614831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614831.url(scheme.get, call_614831.host, call_614831.base,
                         call_614831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614831, url, valid)

proc call*(call_614832: Call_RemoveAttributes_614818; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614833 = newJObject()
  var body_614834 = newJObject()
  add(path_614833, "attribute-type", newJString(attributeType))
  add(path_614833, "application-id", newJString(applicationId))
  if body != nil:
    body_614834 = body
  result = call_614832.call(path_614833, nil, nil, nil, body_614834)

var removeAttributes* = Call_RemoveAttributes_614818(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_614819, base: "/",
    url: url_RemoveAttributes_614820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_614835 = ref object of OpenApiRestCall_612642
proc url_SendMessages_614837(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SendMessages_614836(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614838 = path.getOrDefault("application-id")
  valid_614838 = validateParameter(valid_614838, JString, required = true,
                                 default = nil)
  if valid_614838 != nil:
    section.add "application-id", valid_614838
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
  var valid_614839 = header.getOrDefault("X-Amz-Signature")
  valid_614839 = validateParameter(valid_614839, JString, required = false,
                                 default = nil)
  if valid_614839 != nil:
    section.add "X-Amz-Signature", valid_614839
  var valid_614840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "X-Amz-Content-Sha256", valid_614840
  var valid_614841 = header.getOrDefault("X-Amz-Date")
  valid_614841 = validateParameter(valid_614841, JString, required = false,
                                 default = nil)
  if valid_614841 != nil:
    section.add "X-Amz-Date", valid_614841
  var valid_614842 = header.getOrDefault("X-Amz-Credential")
  valid_614842 = validateParameter(valid_614842, JString, required = false,
                                 default = nil)
  if valid_614842 != nil:
    section.add "X-Amz-Credential", valid_614842
  var valid_614843 = header.getOrDefault("X-Amz-Security-Token")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Security-Token", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-Algorithm")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-Algorithm", valid_614844
  var valid_614845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "X-Amz-SignedHeaders", valid_614845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614847: Call_SendMessages_614835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_614847.validator(path, query, header, formData, body)
  let scheme = call_614847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614847.url(scheme.get, call_614847.host, call_614847.base,
                         call_614847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614847, url, valid)

proc call*(call_614848: Call_SendMessages_614835; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614849 = newJObject()
  var body_614850 = newJObject()
  add(path_614849, "application-id", newJString(applicationId))
  if body != nil:
    body_614850 = body
  result = call_614848.call(path_614849, nil, nil, nil, body_614850)

var sendMessages* = Call_SendMessages_614835(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_614836,
    base: "/", url: url_SendMessages_614837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_614851 = ref object of OpenApiRestCall_612642
proc url_SendUsersMessages_614853(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SendUsersMessages_614852(path: JsonNode; query: JsonNode;
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
  var valid_614854 = path.getOrDefault("application-id")
  valid_614854 = validateParameter(valid_614854, JString, required = true,
                                 default = nil)
  if valid_614854 != nil:
    section.add "application-id", valid_614854
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
  var valid_614855 = header.getOrDefault("X-Amz-Signature")
  valid_614855 = validateParameter(valid_614855, JString, required = false,
                                 default = nil)
  if valid_614855 != nil:
    section.add "X-Amz-Signature", valid_614855
  var valid_614856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614856 = validateParameter(valid_614856, JString, required = false,
                                 default = nil)
  if valid_614856 != nil:
    section.add "X-Amz-Content-Sha256", valid_614856
  var valid_614857 = header.getOrDefault("X-Amz-Date")
  valid_614857 = validateParameter(valid_614857, JString, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "X-Amz-Date", valid_614857
  var valid_614858 = header.getOrDefault("X-Amz-Credential")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-Credential", valid_614858
  var valid_614859 = header.getOrDefault("X-Amz-Security-Token")
  valid_614859 = validateParameter(valid_614859, JString, required = false,
                                 default = nil)
  if valid_614859 != nil:
    section.add "X-Amz-Security-Token", valid_614859
  var valid_614860 = header.getOrDefault("X-Amz-Algorithm")
  valid_614860 = validateParameter(valid_614860, JString, required = false,
                                 default = nil)
  if valid_614860 != nil:
    section.add "X-Amz-Algorithm", valid_614860
  var valid_614861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614861 = validateParameter(valid_614861, JString, required = false,
                                 default = nil)
  if valid_614861 != nil:
    section.add "X-Amz-SignedHeaders", valid_614861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614863: Call_SendUsersMessages_614851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_614863.validator(path, query, header, formData, body)
  let scheme = call_614863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614863.url(scheme.get, call_614863.host, call_614863.base,
                         call_614863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614863, url, valid)

proc call*(call_614864: Call_SendUsersMessages_614851; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614865 = newJObject()
  var body_614866 = newJObject()
  add(path_614865, "application-id", newJString(applicationId))
  if body != nil:
    body_614866 = body
  result = call_614864.call(path_614865, nil, nil, nil, body_614866)

var sendUsersMessages* = Call_SendUsersMessages_614851(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_614852, base: "/",
    url: url_SendUsersMessages_614853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614867 = ref object of OpenApiRestCall_612642
proc url_UntagResource_614869(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_614868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614870 = path.getOrDefault("resource-arn")
  valid_614870 = validateParameter(valid_614870, JString, required = true,
                                 default = nil)
  if valid_614870 != nil:
    section.add "resource-arn", valid_614870
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_614871 = query.getOrDefault("tagKeys")
  valid_614871 = validateParameter(valid_614871, JArray, required = true, default = nil)
  if valid_614871 != nil:
    section.add "tagKeys", valid_614871
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
  var valid_614872 = header.getOrDefault("X-Amz-Signature")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Signature", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Content-Sha256", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Date")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Date", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-Credential")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-Credential", valid_614875
  var valid_614876 = header.getOrDefault("X-Amz-Security-Token")
  valid_614876 = validateParameter(valid_614876, JString, required = false,
                                 default = nil)
  if valid_614876 != nil:
    section.add "X-Amz-Security-Token", valid_614876
  var valid_614877 = header.getOrDefault("X-Amz-Algorithm")
  valid_614877 = validateParameter(valid_614877, JString, required = false,
                                 default = nil)
  if valid_614877 != nil:
    section.add "X-Amz-Algorithm", valid_614877
  var valid_614878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614878 = validateParameter(valid_614878, JString, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "X-Amz-SignedHeaders", valid_614878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614879: Call_UntagResource_614867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_614879.validator(path, query, header, formData, body)
  let scheme = call_614879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614879.url(scheme.get, call_614879.host, call_614879.base,
                         call_614879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614879, url, valid)

proc call*(call_614880: Call_UntagResource_614867; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_614881 = newJObject()
  var query_614882 = newJObject()
  add(path_614881, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_614882.add "tagKeys", tagKeys
  result = call_614880.call(path_614881, query_614882, nil, nil, nil)

var untagResource* = Call_UntagResource_614867(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_614868,
    base: "/", url: url_UntagResource_614869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_614883 = ref object of OpenApiRestCall_612642
proc url_UpdateEndpointsBatch_614885(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEndpointsBatch_614884(path: JsonNode; query: JsonNode;
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
  var valid_614886 = path.getOrDefault("application-id")
  valid_614886 = validateParameter(valid_614886, JString, required = true,
                                 default = nil)
  if valid_614886 != nil:
    section.add "application-id", valid_614886
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
  var valid_614887 = header.getOrDefault("X-Amz-Signature")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Signature", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Content-Sha256", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-Date")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-Date", valid_614889
  var valid_614890 = header.getOrDefault("X-Amz-Credential")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "X-Amz-Credential", valid_614890
  var valid_614891 = header.getOrDefault("X-Amz-Security-Token")
  valid_614891 = validateParameter(valid_614891, JString, required = false,
                                 default = nil)
  if valid_614891 != nil:
    section.add "X-Amz-Security-Token", valid_614891
  var valid_614892 = header.getOrDefault("X-Amz-Algorithm")
  valid_614892 = validateParameter(valid_614892, JString, required = false,
                                 default = nil)
  if valid_614892 != nil:
    section.add "X-Amz-Algorithm", valid_614892
  var valid_614893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614893 = validateParameter(valid_614893, JString, required = false,
                                 default = nil)
  if valid_614893 != nil:
    section.add "X-Amz-SignedHeaders", valid_614893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614895: Call_UpdateEndpointsBatch_614883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_614895.validator(path, query, header, formData, body)
  let scheme = call_614895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614895.url(scheme.get, call_614895.host, call_614895.base,
                         call_614895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614895, url, valid)

proc call*(call_614896: Call_UpdateEndpointsBatch_614883; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_614897 = newJObject()
  var body_614898 = newJObject()
  add(path_614897, "application-id", newJString(applicationId))
  if body != nil:
    body_614898 = body
  result = call_614896.call(path_614897, nil, nil, nil, body_614898)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_614883(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_614884, base: "/",
    url: url_UpdateEndpointsBatch_614885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_614899 = ref object of OpenApiRestCall_612642
proc url_UpdateJourneyState_614901(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJourneyState_614900(path: JsonNode; query: JsonNode;
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
  var valid_614902 = path.getOrDefault("application-id")
  valid_614902 = validateParameter(valid_614902, JString, required = true,
                                 default = nil)
  if valid_614902 != nil:
    section.add "application-id", valid_614902
  var valid_614903 = path.getOrDefault("journey-id")
  valid_614903 = validateParameter(valid_614903, JString, required = true,
                                 default = nil)
  if valid_614903 != nil:
    section.add "journey-id", valid_614903
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
  var valid_614904 = header.getOrDefault("X-Amz-Signature")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Signature", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Content-Sha256", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Date")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Date", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-Credential")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-Credential", valid_614907
  var valid_614908 = header.getOrDefault("X-Amz-Security-Token")
  valid_614908 = validateParameter(valid_614908, JString, required = false,
                                 default = nil)
  if valid_614908 != nil:
    section.add "X-Amz-Security-Token", valid_614908
  var valid_614909 = header.getOrDefault("X-Amz-Algorithm")
  valid_614909 = validateParameter(valid_614909, JString, required = false,
                                 default = nil)
  if valid_614909 != nil:
    section.add "X-Amz-Algorithm", valid_614909
  var valid_614910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614910 = validateParameter(valid_614910, JString, required = false,
                                 default = nil)
  if valid_614910 != nil:
    section.add "X-Amz-SignedHeaders", valid_614910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614912: Call_UpdateJourneyState_614899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_614912.validator(path, query, header, formData, body)
  let scheme = call_614912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614912.url(scheme.get, call_614912.host, call_614912.base,
                         call_614912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614912, url, valid)

proc call*(call_614913: Call_UpdateJourneyState_614899; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_614914 = newJObject()
  var body_614915 = newJObject()
  add(path_614914, "application-id", newJString(applicationId))
  if body != nil:
    body_614915 = body
  add(path_614914, "journey-id", newJString(journeyId))
  result = call_614913.call(path_614914, nil, nil, nil, body_614915)

var updateJourneyState* = Call_UpdateJourneyState_614899(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_614900, base: "/",
    url: url_UpdateJourneyState_614901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_614916 = ref object of OpenApiRestCall_612642
proc url_UpdateTemplateActiveVersion_614918(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateActiveVersion_614917(path: JsonNode; query: JsonNode;
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
  var valid_614919 = path.getOrDefault("template-type")
  valid_614919 = validateParameter(valid_614919, JString, required = true,
                                 default = nil)
  if valid_614919 != nil:
    section.add "template-type", valid_614919
  var valid_614920 = path.getOrDefault("template-name")
  valid_614920 = validateParameter(valid_614920, JString, required = true,
                                 default = nil)
  if valid_614920 != nil:
    section.add "template-name", valid_614920
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
  var valid_614921 = header.getOrDefault("X-Amz-Signature")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Signature", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Content-Sha256", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-Date")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-Date", valid_614923
  var valid_614924 = header.getOrDefault("X-Amz-Credential")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "X-Amz-Credential", valid_614924
  var valid_614925 = header.getOrDefault("X-Amz-Security-Token")
  valid_614925 = validateParameter(valid_614925, JString, required = false,
                                 default = nil)
  if valid_614925 != nil:
    section.add "X-Amz-Security-Token", valid_614925
  var valid_614926 = header.getOrDefault("X-Amz-Algorithm")
  valid_614926 = validateParameter(valid_614926, JString, required = false,
                                 default = nil)
  if valid_614926 != nil:
    section.add "X-Amz-Algorithm", valid_614926
  var valid_614927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614927 = validateParameter(valid_614927, JString, required = false,
                                 default = nil)
  if valid_614927 != nil:
    section.add "X-Amz-SignedHeaders", valid_614927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614929: Call_UpdateTemplateActiveVersion_614916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_614929.validator(path, query, header, formData, body)
  let scheme = call_614929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614929.url(scheme.get, call_614929.host, call_614929.base,
                         call_614929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614929, url, valid)

proc call*(call_614930: Call_UpdateTemplateActiveVersion_614916;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_614931 = newJObject()
  var body_614932 = newJObject()
  add(path_614931, "template-type", newJString(templateType))
  add(path_614931, "template-name", newJString(templateName))
  if body != nil:
    body_614932 = body
  result = call_614930.call(path_614931, nil, nil, nil, body_614932)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_614916(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_614917, base: "/",
    url: url_UpdateTemplateActiveVersion_614918,
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
