
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_CreateApp_606168 = ref object of OpenApiRestCall_605573
proc url_CreateApp_606170(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_606169(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606171 = header.getOrDefault("X-Amz-Signature")
  valid_606171 = validateParameter(valid_606171, JString, required = false,
                                 default = nil)
  if valid_606171 != nil:
    section.add "X-Amz-Signature", valid_606171
  var valid_606172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606172 = validateParameter(valid_606172, JString, required = false,
                                 default = nil)
  if valid_606172 != nil:
    section.add "X-Amz-Content-Sha256", valid_606172
  var valid_606173 = header.getOrDefault("X-Amz-Date")
  valid_606173 = validateParameter(valid_606173, JString, required = false,
                                 default = nil)
  if valid_606173 != nil:
    section.add "X-Amz-Date", valid_606173
  var valid_606174 = header.getOrDefault("X-Amz-Credential")
  valid_606174 = validateParameter(valid_606174, JString, required = false,
                                 default = nil)
  if valid_606174 != nil:
    section.add "X-Amz-Credential", valid_606174
  var valid_606175 = header.getOrDefault("X-Amz-Security-Token")
  valid_606175 = validateParameter(valid_606175, JString, required = false,
                                 default = nil)
  if valid_606175 != nil:
    section.add "X-Amz-Security-Token", valid_606175
  var valid_606176 = header.getOrDefault("X-Amz-Algorithm")
  valid_606176 = validateParameter(valid_606176, JString, required = false,
                                 default = nil)
  if valid_606176 != nil:
    section.add "X-Amz-Algorithm", valid_606176
  var valid_606177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606177 = validateParameter(valid_606177, JString, required = false,
                                 default = nil)
  if valid_606177 != nil:
    section.add "X-Amz-SignedHeaders", valid_606177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606179: Call_CreateApp_606168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_606179.validator(path, query, header, formData, body)
  let scheme = call_606179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606179.url(scheme.get, call_606179.host, call_606179.base,
                         call_606179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606179, url, valid)

proc call*(call_606180: Call_CreateApp_606168; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_606181 = newJObject()
  if body != nil:
    body_606181 = body
  result = call_606180.call(nil, nil, nil, nil, body_606181)

var createApp* = Call_CreateApp_606168(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_606169,
                                    base: "/", url: url_CreateApp_606170,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_605911 = ref object of OpenApiRestCall_605573
proc url_GetApps_605913(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApps_605912(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606025 = query.getOrDefault("page-size")
  valid_606025 = validateParameter(valid_606025, JString, required = false,
                                 default = nil)
  if valid_606025 != nil:
    section.add "page-size", valid_606025
  var valid_606026 = query.getOrDefault("token")
  valid_606026 = validateParameter(valid_606026, JString, required = false,
                                 default = nil)
  if valid_606026 != nil:
    section.add "token", valid_606026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606027 = header.getOrDefault("X-Amz-Signature")
  valid_606027 = validateParameter(valid_606027, JString, required = false,
                                 default = nil)
  if valid_606027 != nil:
    section.add "X-Amz-Signature", valid_606027
  var valid_606028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606028 = validateParameter(valid_606028, JString, required = false,
                                 default = nil)
  if valid_606028 != nil:
    section.add "X-Amz-Content-Sha256", valid_606028
  var valid_606029 = header.getOrDefault("X-Amz-Date")
  valid_606029 = validateParameter(valid_606029, JString, required = false,
                                 default = nil)
  if valid_606029 != nil:
    section.add "X-Amz-Date", valid_606029
  var valid_606030 = header.getOrDefault("X-Amz-Credential")
  valid_606030 = validateParameter(valid_606030, JString, required = false,
                                 default = nil)
  if valid_606030 != nil:
    section.add "X-Amz-Credential", valid_606030
  var valid_606031 = header.getOrDefault("X-Amz-Security-Token")
  valid_606031 = validateParameter(valid_606031, JString, required = false,
                                 default = nil)
  if valid_606031 != nil:
    section.add "X-Amz-Security-Token", valid_606031
  var valid_606032 = header.getOrDefault("X-Amz-Algorithm")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "X-Amz-Algorithm", valid_606032
  var valid_606033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "X-Amz-SignedHeaders", valid_606033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606056: Call_GetApps_605911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_606056.validator(path, query, header, formData, body)
  let scheme = call_606056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606056.url(scheme.get, call_606056.host, call_606056.base,
                         call_606056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606056, url, valid)

proc call*(call_606127: Call_GetApps_605911; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_606128 = newJObject()
  add(query_606128, "page-size", newJString(pageSize))
  add(query_606128, "token", newJString(token))
  result = call_606127.call(nil, query_606128, nil, nil, nil)

var getApps* = Call_GetApps_605911(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_605912, base: "/",
                                url: url_GetApps_605913,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_606213 = ref object of OpenApiRestCall_605573
proc url_CreateCampaign_606215(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_606214(path: JsonNode; query: JsonNode;
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
  var valid_606216 = path.getOrDefault("application-id")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "application-id", valid_606216
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
  var valid_606217 = header.getOrDefault("X-Amz-Signature")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Signature", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Content-Sha256", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Date")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Date", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Credential")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Credential", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Security-Token")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Security-Token", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Algorithm")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Algorithm", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-SignedHeaders", valid_606223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606225: Call_CreateCampaign_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_606225.validator(path, query, header, formData, body)
  let scheme = call_606225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606225.url(scheme.get, call_606225.host, call_606225.base,
                         call_606225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606225, url, valid)

proc call*(call_606226: Call_CreateCampaign_606213; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606227 = newJObject()
  var body_606228 = newJObject()
  add(path_606227, "application-id", newJString(applicationId))
  if body != nil:
    body_606228 = body
  result = call_606226.call(path_606227, nil, nil, nil, body_606228)

var createCampaign* = Call_CreateCampaign_606213(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_606214, base: "/", url: url_CreateCampaign_606215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_606182 = ref object of OpenApiRestCall_605573
proc url_GetCampaigns_606184(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_606183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606199 = path.getOrDefault("application-id")
  valid_606199 = validateParameter(valid_606199, JString, required = true,
                                 default = nil)
  if valid_606199 != nil:
    section.add "application-id", valid_606199
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_606200 = query.getOrDefault("page-size")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "page-size", valid_606200
  var valid_606201 = query.getOrDefault("token")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "token", valid_606201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606202 = header.getOrDefault("X-Amz-Signature")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Signature", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Content-Sha256", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Date")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Date", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Credential")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Credential", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Security-Token")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Security-Token", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Algorithm")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Algorithm", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-SignedHeaders", valid_606208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_GetCampaigns_606182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_GetCampaigns_606182; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_606211 = newJObject()
  var query_606212 = newJObject()
  add(path_606211, "application-id", newJString(applicationId))
  add(query_606212, "page-size", newJString(pageSize))
  add(query_606212, "token", newJString(token))
  result = call_606210.call(path_606211, query_606212, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_606182(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_606183, base: "/", url: url_GetCampaigns_606184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_606245 = ref object of OpenApiRestCall_605573
proc url_UpdateEmailTemplate_606247(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_606246(path: JsonNode; query: JsonNode;
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
  var valid_606248 = path.getOrDefault("template-name")
  valid_606248 = validateParameter(valid_606248, JString, required = true,
                                 default = nil)
  if valid_606248 != nil:
    section.add "template-name", valid_606248
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_606249 = query.getOrDefault("version")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "version", valid_606249
  var valid_606250 = query.getOrDefault("create-new-version")
  valid_606250 = validateParameter(valid_606250, JBool, required = false, default = nil)
  if valid_606250 != nil:
    section.add "create-new-version", valid_606250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606251 = header.getOrDefault("X-Amz-Signature")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Signature", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Content-Sha256", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Date")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Date", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Credential")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Credential", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Security-Token")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Security-Token", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Algorithm")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Algorithm", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-SignedHeaders", valid_606257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606259: Call_UpdateEmailTemplate_606245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_606259.validator(path, query, header, formData, body)
  let scheme = call_606259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606259.url(scheme.get, call_606259.host, call_606259.base,
                         call_606259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606259, url, valid)

proc call*(call_606260: Call_UpdateEmailTemplate_606245; templateName: string;
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
  var path_606261 = newJObject()
  var query_606262 = newJObject()
  var body_606263 = newJObject()
  add(path_606261, "template-name", newJString(templateName))
  add(query_606262, "version", newJString(version))
  add(query_606262, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_606263 = body
  result = call_606260.call(path_606261, query_606262, nil, nil, body_606263)

var updateEmailTemplate* = Call_UpdateEmailTemplate_606245(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_606246, base: "/",
    url: url_UpdateEmailTemplate_606247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_606264 = ref object of OpenApiRestCall_605573
proc url_CreateEmailTemplate_606266(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_606265(path: JsonNode; query: JsonNode;
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
  var valid_606267 = path.getOrDefault("template-name")
  valid_606267 = validateParameter(valid_606267, JString, required = true,
                                 default = nil)
  if valid_606267 != nil:
    section.add "template-name", valid_606267
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
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606276: Call_CreateEmailTemplate_606264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateEmailTemplate_606264; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_606278 = newJObject()
  var body_606279 = newJObject()
  add(path_606278, "template-name", newJString(templateName))
  if body != nil:
    body_606279 = body
  result = call_606277.call(path_606278, nil, nil, nil, body_606279)

var createEmailTemplate* = Call_CreateEmailTemplate_606264(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_606265, base: "/",
    url: url_CreateEmailTemplate_606266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_606229 = ref object of OpenApiRestCall_605573
proc url_GetEmailTemplate_606231(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_606230(path: JsonNode; query: JsonNode;
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
  var valid_606232 = path.getOrDefault("template-name")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "template-name", valid_606232
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606233 = query.getOrDefault("version")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "version", valid_606233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_GetEmailTemplate_606229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_GetEmailTemplate_606229; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606243 = newJObject()
  var query_606244 = newJObject()
  add(path_606243, "template-name", newJString(templateName))
  add(query_606244, "version", newJString(version))
  result = call_606242.call(path_606243, query_606244, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_606229(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_606230, base: "/",
    url: url_GetEmailTemplate_606231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_606280 = ref object of OpenApiRestCall_605573
proc url_DeleteEmailTemplate_606282(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_606281(path: JsonNode; query: JsonNode;
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
  var valid_606283 = path.getOrDefault("template-name")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "template-name", valid_606283
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606284 = query.getOrDefault("version")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "version", valid_606284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606285 = header.getOrDefault("X-Amz-Signature")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Signature", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Content-Sha256", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Date")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Date", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Credential")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Credential", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Security-Token")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Security-Token", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Algorithm")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Algorithm", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-SignedHeaders", valid_606291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_DeleteEmailTemplate_606280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_DeleteEmailTemplate_606280; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606294 = newJObject()
  var query_606295 = newJObject()
  add(path_606294, "template-name", newJString(templateName))
  add(query_606295, "version", newJString(version))
  result = call_606293.call(path_606294, query_606295, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_606280(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_606281, base: "/",
    url: url_DeleteEmailTemplate_606282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_606313 = ref object of OpenApiRestCall_605573
proc url_CreateExportJob_606315(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_606314(path: JsonNode; query: JsonNode;
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
  var valid_606316 = path.getOrDefault("application-id")
  valid_606316 = validateParameter(valid_606316, JString, required = true,
                                 default = nil)
  if valid_606316 != nil:
    section.add "application-id", valid_606316
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
  var valid_606317 = header.getOrDefault("X-Amz-Signature")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Signature", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Content-Sha256", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Date")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Date", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Credential")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Credential", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Security-Token")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Security-Token", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Algorithm")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Algorithm", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-SignedHeaders", valid_606323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606325: Call_CreateExportJob_606313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_606325.validator(path, query, header, formData, body)
  let scheme = call_606325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606325.url(scheme.get, call_606325.host, call_606325.base,
                         call_606325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606325, url, valid)

proc call*(call_606326: Call_CreateExportJob_606313; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606327 = newJObject()
  var body_606328 = newJObject()
  add(path_606327, "application-id", newJString(applicationId))
  if body != nil:
    body_606328 = body
  result = call_606326.call(path_606327, nil, nil, nil, body_606328)

var createExportJob* = Call_CreateExportJob_606313(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_606314, base: "/", url: url_CreateExportJob_606315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_606296 = ref object of OpenApiRestCall_605573
proc url_GetExportJobs_606298(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_606297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606299 = path.getOrDefault("application-id")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = nil)
  if valid_606299 != nil:
    section.add "application-id", valid_606299
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_606300 = query.getOrDefault("page-size")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "page-size", valid_606300
  var valid_606301 = query.getOrDefault("token")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "token", valid_606301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606302 = header.getOrDefault("X-Amz-Signature")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Signature", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Content-Sha256", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Date")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Date", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Credential")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Credential", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Security-Token")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Security-Token", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Algorithm")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Algorithm", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-SignedHeaders", valid_606308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606309: Call_GetExportJobs_606296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_606309.validator(path, query, header, formData, body)
  let scheme = call_606309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606309.url(scheme.get, call_606309.host, call_606309.base,
                         call_606309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606309, url, valid)

proc call*(call_606310: Call_GetExportJobs_606296; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_606311 = newJObject()
  var query_606312 = newJObject()
  add(path_606311, "application-id", newJString(applicationId))
  add(query_606312, "page-size", newJString(pageSize))
  add(query_606312, "token", newJString(token))
  result = call_606310.call(path_606311, query_606312, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_606296(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_606297, base: "/", url: url_GetExportJobs_606298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_606346 = ref object of OpenApiRestCall_605573
proc url_CreateImportJob_606348(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_606347(path: JsonNode; query: JsonNode;
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
  var valid_606349 = path.getOrDefault("application-id")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = nil)
  if valid_606349 != nil:
    section.add "application-id", valid_606349
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_CreateImportJob_606346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_CreateImportJob_606346; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606360 = newJObject()
  var body_606361 = newJObject()
  add(path_606360, "application-id", newJString(applicationId))
  if body != nil:
    body_606361 = body
  result = call_606359.call(path_606360, nil, nil, nil, body_606361)

var createImportJob* = Call_CreateImportJob_606346(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_606347, base: "/", url: url_CreateImportJob_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_606329 = ref object of OpenApiRestCall_605573
proc url_GetImportJobs_606331(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_606330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606332 = path.getOrDefault("application-id")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "application-id", valid_606332
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_606333 = query.getOrDefault("page-size")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "page-size", valid_606333
  var valid_606334 = query.getOrDefault("token")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "token", valid_606334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606342: Call_GetImportJobs_606329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_606342.validator(path, query, header, formData, body)
  let scheme = call_606342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606342.url(scheme.get, call_606342.host, call_606342.base,
                         call_606342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606342, url, valid)

proc call*(call_606343: Call_GetImportJobs_606329; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_606344 = newJObject()
  var query_606345 = newJObject()
  add(path_606344, "application-id", newJString(applicationId))
  add(query_606345, "page-size", newJString(pageSize))
  add(query_606345, "token", newJString(token))
  result = call_606343.call(path_606344, query_606345, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_606329(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_606330, base: "/", url: url_GetImportJobs_606331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_606379 = ref object of OpenApiRestCall_605573
proc url_CreateJourney_606381(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_606380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606382 = path.getOrDefault("application-id")
  valid_606382 = validateParameter(valid_606382, JString, required = true,
                                 default = nil)
  if valid_606382 != nil:
    section.add "application-id", valid_606382
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
  var valid_606383 = header.getOrDefault("X-Amz-Signature")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Signature", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Content-Sha256", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Date")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Date", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Credential")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Credential", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Security-Token")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Security-Token", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Algorithm")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Algorithm", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-SignedHeaders", valid_606389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606391: Call_CreateJourney_606379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_606391.validator(path, query, header, formData, body)
  let scheme = call_606391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606391.url(scheme.get, call_606391.host, call_606391.base,
                         call_606391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606391, url, valid)

proc call*(call_606392: Call_CreateJourney_606379; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606393 = newJObject()
  var body_606394 = newJObject()
  add(path_606393, "application-id", newJString(applicationId))
  if body != nil:
    body_606394 = body
  result = call_606392.call(path_606393, nil, nil, nil, body_606394)

var createJourney* = Call_CreateJourney_606379(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_606380, base: "/", url: url_CreateJourney_606381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_606362 = ref object of OpenApiRestCall_605573
proc url_ListJourneys_606364(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_606363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606365 = path.getOrDefault("application-id")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = nil)
  if valid_606365 != nil:
    section.add "application-id", valid_606365
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_606366 = query.getOrDefault("page-size")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "page-size", valid_606366
  var valid_606367 = query.getOrDefault("token")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "token", valid_606367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606368 = header.getOrDefault("X-Amz-Signature")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Signature", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Content-Sha256", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Date")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Date", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Credential")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Credential", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Security-Token")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Security-Token", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Algorithm")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Algorithm", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-SignedHeaders", valid_606374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606375: Call_ListJourneys_606362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_606375.validator(path, query, header, formData, body)
  let scheme = call_606375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606375.url(scheme.get, call_606375.host, call_606375.base,
                         call_606375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606375, url, valid)

proc call*(call_606376: Call_ListJourneys_606362; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_606377 = newJObject()
  var query_606378 = newJObject()
  add(path_606377, "application-id", newJString(applicationId))
  add(query_606378, "page-size", newJString(pageSize))
  add(query_606378, "token", newJString(token))
  result = call_606376.call(path_606377, query_606378, nil, nil, nil)

var listJourneys* = Call_ListJourneys_606362(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_606363,
    base: "/", url: url_ListJourneys_606364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_606411 = ref object of OpenApiRestCall_605573
proc url_UpdatePushTemplate_606413(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_606412(path: JsonNode; query: JsonNode;
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
  var valid_606414 = path.getOrDefault("template-name")
  valid_606414 = validateParameter(valid_606414, JString, required = true,
                                 default = nil)
  if valid_606414 != nil:
    section.add "template-name", valid_606414
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_606415 = query.getOrDefault("version")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "version", valid_606415
  var valid_606416 = query.getOrDefault("create-new-version")
  valid_606416 = validateParameter(valid_606416, JBool, required = false, default = nil)
  if valid_606416 != nil:
    section.add "create-new-version", valid_606416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606417 = header.getOrDefault("X-Amz-Signature")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Signature", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Content-Sha256", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Date")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Date", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Credential")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Credential", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Security-Token")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Security-Token", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Algorithm")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Algorithm", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-SignedHeaders", valid_606423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606425: Call_UpdatePushTemplate_606411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_606425.validator(path, query, header, formData, body)
  let scheme = call_606425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606425.url(scheme.get, call_606425.host, call_606425.base,
                         call_606425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606425, url, valid)

proc call*(call_606426: Call_UpdatePushTemplate_606411; templateName: string;
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
  var path_606427 = newJObject()
  var query_606428 = newJObject()
  var body_606429 = newJObject()
  add(path_606427, "template-name", newJString(templateName))
  add(query_606428, "version", newJString(version))
  add(query_606428, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_606429 = body
  result = call_606426.call(path_606427, query_606428, nil, nil, body_606429)

var updatePushTemplate* = Call_UpdatePushTemplate_606411(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_606412, base: "/",
    url: url_UpdatePushTemplate_606413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_606430 = ref object of OpenApiRestCall_605573
proc url_CreatePushTemplate_606432(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_606431(path: JsonNode; query: JsonNode;
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
  var valid_606433 = path.getOrDefault("template-name")
  valid_606433 = validateParameter(valid_606433, JString, required = true,
                                 default = nil)
  if valid_606433 != nil:
    section.add "template-name", valid_606433
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
  var valid_606434 = header.getOrDefault("X-Amz-Signature")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Signature", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Content-Sha256", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Date")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Date", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Credential")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Credential", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Security-Token")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Security-Token", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Algorithm")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Algorithm", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-SignedHeaders", valid_606440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606442: Call_CreatePushTemplate_606430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_606442.validator(path, query, header, formData, body)
  let scheme = call_606442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606442.url(scheme.get, call_606442.host, call_606442.base,
                         call_606442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606442, url, valid)

proc call*(call_606443: Call_CreatePushTemplate_606430; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_606444 = newJObject()
  var body_606445 = newJObject()
  add(path_606444, "template-name", newJString(templateName))
  if body != nil:
    body_606445 = body
  result = call_606443.call(path_606444, nil, nil, nil, body_606445)

var createPushTemplate* = Call_CreatePushTemplate_606430(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_606431, base: "/",
    url: url_CreatePushTemplate_606432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_606395 = ref object of OpenApiRestCall_605573
proc url_GetPushTemplate_606397(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_606396(path: JsonNode; query: JsonNode;
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
  var valid_606398 = path.getOrDefault("template-name")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = nil)
  if valid_606398 != nil:
    section.add "template-name", valid_606398
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606399 = query.getOrDefault("version")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "version", valid_606399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606400 = header.getOrDefault("X-Amz-Signature")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Signature", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Content-Sha256", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Date")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Date", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Credential")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Credential", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Security-Token")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Security-Token", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Algorithm")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Algorithm", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-SignedHeaders", valid_606406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_GetPushTemplate_606395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_GetPushTemplate_606395; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606409 = newJObject()
  var query_606410 = newJObject()
  add(path_606409, "template-name", newJString(templateName))
  add(query_606410, "version", newJString(version))
  result = call_606408.call(path_606409, query_606410, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_606395(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_606396, base: "/", url: url_GetPushTemplate_606397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_606446 = ref object of OpenApiRestCall_605573
proc url_DeletePushTemplate_606448(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_606447(path: JsonNode; query: JsonNode;
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
  var valid_606449 = path.getOrDefault("template-name")
  valid_606449 = validateParameter(valid_606449, JString, required = true,
                                 default = nil)
  if valid_606449 != nil:
    section.add "template-name", valid_606449
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606450 = query.getOrDefault("version")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "version", valid_606450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606451 = header.getOrDefault("X-Amz-Signature")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Signature", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Content-Sha256", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Date")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Date", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Credential")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Credential", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Security-Token")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Security-Token", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Algorithm")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Algorithm", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-SignedHeaders", valid_606457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606458: Call_DeletePushTemplate_606446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_606458.validator(path, query, header, formData, body)
  let scheme = call_606458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606458.url(scheme.get, call_606458.host, call_606458.base,
                         call_606458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606458, url, valid)

proc call*(call_606459: Call_DeletePushTemplate_606446; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606460 = newJObject()
  var query_606461 = newJObject()
  add(path_606460, "template-name", newJString(templateName))
  add(query_606461, "version", newJString(version))
  result = call_606459.call(path_606460, query_606461, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_606446(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_606447, base: "/",
    url: url_DeletePushTemplate_606448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_606479 = ref object of OpenApiRestCall_605573
proc url_CreateSegment_606481(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_606480(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606482 = path.getOrDefault("application-id")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = nil)
  if valid_606482 != nil:
    section.add "application-id", valid_606482
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
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Security-Token")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Security-Token", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Algorithm")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Algorithm", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-SignedHeaders", valid_606489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_CreateSegment_606479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_CreateSegment_606479; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606493 = newJObject()
  var body_606494 = newJObject()
  add(path_606493, "application-id", newJString(applicationId))
  if body != nil:
    body_606494 = body
  result = call_606492.call(path_606493, nil, nil, nil, body_606494)

var createSegment* = Call_CreateSegment_606479(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_606480, base: "/", url: url_CreateSegment_606481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_606462 = ref object of OpenApiRestCall_605573
proc url_GetSegments_606464(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_606463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606465 = path.getOrDefault("application-id")
  valid_606465 = validateParameter(valid_606465, JString, required = true,
                                 default = nil)
  if valid_606465 != nil:
    section.add "application-id", valid_606465
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_606466 = query.getOrDefault("page-size")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "page-size", valid_606466
  var valid_606467 = query.getOrDefault("token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "token", valid_606467
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606468 = header.getOrDefault("X-Amz-Signature")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Signature", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Content-Sha256", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Date")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Date", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Credential")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Credential", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Security-Token")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Security-Token", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Algorithm")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Algorithm", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-SignedHeaders", valid_606474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606475: Call_GetSegments_606462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_606475.validator(path, query, header, formData, body)
  let scheme = call_606475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606475.url(scheme.get, call_606475.host, call_606475.base,
                         call_606475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606475, url, valid)

proc call*(call_606476: Call_GetSegments_606462; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_606477 = newJObject()
  var query_606478 = newJObject()
  add(path_606477, "application-id", newJString(applicationId))
  add(query_606478, "page-size", newJString(pageSize))
  add(query_606478, "token", newJString(token))
  result = call_606476.call(path_606477, query_606478, nil, nil, nil)

var getSegments* = Call_GetSegments_606462(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_606463,
                                        base: "/", url: url_GetSegments_606464,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_606511 = ref object of OpenApiRestCall_605573
proc url_UpdateSmsTemplate_606513(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_606512(path: JsonNode; query: JsonNode;
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
  var valid_606514 = path.getOrDefault("template-name")
  valid_606514 = validateParameter(valid_606514, JString, required = true,
                                 default = nil)
  if valid_606514 != nil:
    section.add "template-name", valid_606514
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_606515 = query.getOrDefault("version")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "version", valid_606515
  var valid_606516 = query.getOrDefault("create-new-version")
  valid_606516 = validateParameter(valid_606516, JBool, required = false, default = nil)
  if valid_606516 != nil:
    section.add "create-new-version", valid_606516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606517 = header.getOrDefault("X-Amz-Signature")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Signature", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Content-Sha256", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Date")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Date", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Credential")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Credential", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Security-Token")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Security-Token", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Algorithm")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Algorithm", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-SignedHeaders", valid_606523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606525: Call_UpdateSmsTemplate_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_606525.validator(path, query, header, formData, body)
  let scheme = call_606525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606525.url(scheme.get, call_606525.host, call_606525.base,
                         call_606525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606525, url, valid)

proc call*(call_606526: Call_UpdateSmsTemplate_606511; templateName: string;
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
  var path_606527 = newJObject()
  var query_606528 = newJObject()
  var body_606529 = newJObject()
  add(path_606527, "template-name", newJString(templateName))
  add(query_606528, "version", newJString(version))
  add(query_606528, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_606529 = body
  result = call_606526.call(path_606527, query_606528, nil, nil, body_606529)

var updateSmsTemplate* = Call_UpdateSmsTemplate_606511(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_606512, base: "/",
    url: url_UpdateSmsTemplate_606513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_606530 = ref object of OpenApiRestCall_605573
proc url_CreateSmsTemplate_606532(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_606531(path: JsonNode; query: JsonNode;
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
  var valid_606533 = path.getOrDefault("template-name")
  valid_606533 = validateParameter(valid_606533, JString, required = true,
                                 default = nil)
  if valid_606533 != nil:
    section.add "template-name", valid_606533
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
  var valid_606534 = header.getOrDefault("X-Amz-Signature")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Signature", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Content-Sha256", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Date")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Date", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Credential")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Credential", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Security-Token")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Security-Token", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Algorithm")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Algorithm", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-SignedHeaders", valid_606540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606542: Call_CreateSmsTemplate_606530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_606542.validator(path, query, header, formData, body)
  let scheme = call_606542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606542.url(scheme.get, call_606542.host, call_606542.base,
                         call_606542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606542, url, valid)

proc call*(call_606543: Call_CreateSmsTemplate_606530; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_606544 = newJObject()
  var body_606545 = newJObject()
  add(path_606544, "template-name", newJString(templateName))
  if body != nil:
    body_606545 = body
  result = call_606543.call(path_606544, nil, nil, nil, body_606545)

var createSmsTemplate* = Call_CreateSmsTemplate_606530(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_606531, base: "/",
    url: url_CreateSmsTemplate_606532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_606495 = ref object of OpenApiRestCall_605573
proc url_GetSmsTemplate_606497(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_606496(path: JsonNode; query: JsonNode;
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
  var valid_606498 = path.getOrDefault("template-name")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = nil)
  if valid_606498 != nil:
    section.add "template-name", valid_606498
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606499 = query.getOrDefault("version")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "version", valid_606499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606507: Call_GetSmsTemplate_606495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_606507.validator(path, query, header, formData, body)
  let scheme = call_606507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606507.url(scheme.get, call_606507.host, call_606507.base,
                         call_606507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606507, url, valid)

proc call*(call_606508: Call_GetSmsTemplate_606495; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606509 = newJObject()
  var query_606510 = newJObject()
  add(path_606509, "template-name", newJString(templateName))
  add(query_606510, "version", newJString(version))
  result = call_606508.call(path_606509, query_606510, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_606495(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_606496, base: "/", url: url_GetSmsTemplate_606497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_606546 = ref object of OpenApiRestCall_605573
proc url_DeleteSmsTemplate_606548(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_606547(path: JsonNode; query: JsonNode;
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
  var valid_606549 = path.getOrDefault("template-name")
  valid_606549 = validateParameter(valid_606549, JString, required = true,
                                 default = nil)
  if valid_606549 != nil:
    section.add "template-name", valid_606549
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606550 = query.getOrDefault("version")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "version", valid_606550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606551 = header.getOrDefault("X-Amz-Signature")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Signature", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Content-Sha256", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Date")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Date", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Credential")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Credential", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Security-Token")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Security-Token", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Algorithm")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Algorithm", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-SignedHeaders", valid_606557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606558: Call_DeleteSmsTemplate_606546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_606558.validator(path, query, header, formData, body)
  let scheme = call_606558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606558.url(scheme.get, call_606558.host, call_606558.base,
                         call_606558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606558, url, valid)

proc call*(call_606559: Call_DeleteSmsTemplate_606546; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606560 = newJObject()
  var query_606561 = newJObject()
  add(path_606560, "template-name", newJString(templateName))
  add(query_606561, "version", newJString(version))
  result = call_606559.call(path_606560, query_606561, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_606546(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_606547, base: "/",
    url: url_DeleteSmsTemplate_606548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_606578 = ref object of OpenApiRestCall_605573
proc url_UpdateVoiceTemplate_606580(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceTemplate_606579(path: JsonNode; query: JsonNode;
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
  var valid_606581 = path.getOrDefault("template-name")
  valid_606581 = validateParameter(valid_606581, JString, required = true,
                                 default = nil)
  if valid_606581 != nil:
    section.add "template-name", valid_606581
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_606582 = query.getOrDefault("version")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "version", valid_606582
  var valid_606583 = query.getOrDefault("create-new-version")
  valid_606583 = validateParameter(valid_606583, JBool, required = false, default = nil)
  if valid_606583 != nil:
    section.add "create-new-version", valid_606583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606584 = header.getOrDefault("X-Amz-Signature")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Signature", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Content-Sha256", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Date")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Date", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Credential")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Credential", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Security-Token")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Security-Token", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Algorithm")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Algorithm", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-SignedHeaders", valid_606590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606592: Call_UpdateVoiceTemplate_606578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_606592.validator(path, query, header, formData, body)
  let scheme = call_606592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606592.url(scheme.get, call_606592.host, call_606592.base,
                         call_606592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606592, url, valid)

proc call*(call_606593: Call_UpdateVoiceTemplate_606578; templateName: string;
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
  var path_606594 = newJObject()
  var query_606595 = newJObject()
  var body_606596 = newJObject()
  add(path_606594, "template-name", newJString(templateName))
  add(query_606595, "version", newJString(version))
  add(query_606595, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_606596 = body
  result = call_606593.call(path_606594, query_606595, nil, nil, body_606596)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_606578(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_606579, base: "/",
    url: url_UpdateVoiceTemplate_606580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_606597 = ref object of OpenApiRestCall_605573
proc url_CreateVoiceTemplate_606599(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceTemplate_606598(path: JsonNode; query: JsonNode;
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
  var valid_606600 = path.getOrDefault("template-name")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = nil)
  if valid_606600 != nil:
    section.add "template-name", valid_606600
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
  var valid_606601 = header.getOrDefault("X-Amz-Signature")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Signature", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Content-Sha256", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Date")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Date", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Credential")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Credential", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Security-Token")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Security-Token", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Algorithm")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Algorithm", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-SignedHeaders", valid_606607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606609: Call_CreateVoiceTemplate_606597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_606609.validator(path, query, header, formData, body)
  let scheme = call_606609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606609.url(scheme.get, call_606609.host, call_606609.base,
                         call_606609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606609, url, valid)

proc call*(call_606610: Call_CreateVoiceTemplate_606597; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_606611 = newJObject()
  var body_606612 = newJObject()
  add(path_606611, "template-name", newJString(templateName))
  if body != nil:
    body_606612 = body
  result = call_606610.call(path_606611, nil, nil, nil, body_606612)

var createVoiceTemplate* = Call_CreateVoiceTemplate_606597(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_606598, base: "/",
    url: url_CreateVoiceTemplate_606599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_606562 = ref object of OpenApiRestCall_605573
proc url_GetVoiceTemplate_606564(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceTemplate_606563(path: JsonNode; query: JsonNode;
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
  var valid_606565 = path.getOrDefault("template-name")
  valid_606565 = validateParameter(valid_606565, JString, required = true,
                                 default = nil)
  if valid_606565 != nil:
    section.add "template-name", valid_606565
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606566 = query.getOrDefault("version")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "version", valid_606566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606567 = header.getOrDefault("X-Amz-Signature")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Signature", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Content-Sha256", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Date")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Date", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Credential")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Credential", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Security-Token")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Security-Token", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Algorithm")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Algorithm", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-SignedHeaders", valid_606573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606574: Call_GetVoiceTemplate_606562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_606574.validator(path, query, header, formData, body)
  let scheme = call_606574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606574.url(scheme.get, call_606574.host, call_606574.base,
                         call_606574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606574, url, valid)

proc call*(call_606575: Call_GetVoiceTemplate_606562; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606576 = newJObject()
  var query_606577 = newJObject()
  add(path_606576, "template-name", newJString(templateName))
  add(query_606577, "version", newJString(version))
  result = call_606575.call(path_606576, query_606577, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_606562(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_606563, base: "/",
    url: url_GetVoiceTemplate_606564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_606613 = ref object of OpenApiRestCall_605573
proc url_DeleteVoiceTemplate_606615(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceTemplate_606614(path: JsonNode; query: JsonNode;
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
  var valid_606616 = path.getOrDefault("template-name")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = nil)
  if valid_606616 != nil:
    section.add "template-name", valid_606616
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_606617 = query.getOrDefault("version")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "version", valid_606617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606618 = header.getOrDefault("X-Amz-Signature")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Signature", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Content-Sha256", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Date")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Date", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Credential")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Credential", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Security-Token")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Security-Token", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Algorithm")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Algorithm", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-SignedHeaders", valid_606624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_DeleteVoiceTemplate_606613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_DeleteVoiceTemplate_606613; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_606627 = newJObject()
  var query_606628 = newJObject()
  add(path_606627, "template-name", newJString(templateName))
  add(query_606628, "version", newJString(version))
  result = call_606626.call(path_606627, query_606628, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_606613(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_606614, base: "/",
    url: url_DeleteVoiceTemplate_606615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_606643 = ref object of OpenApiRestCall_605573
proc url_UpdateAdmChannel_606645(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_606644(path: JsonNode; query: JsonNode;
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
  var valid_606646 = path.getOrDefault("application-id")
  valid_606646 = validateParameter(valid_606646, JString, required = true,
                                 default = nil)
  if valid_606646 != nil:
    section.add "application-id", valid_606646
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
  var valid_606647 = header.getOrDefault("X-Amz-Signature")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Signature", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Content-Sha256", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Date")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Date", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Credential")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Credential", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Security-Token")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Security-Token", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Algorithm")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Algorithm", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-SignedHeaders", valid_606653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606655: Call_UpdateAdmChannel_606643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_606655.validator(path, query, header, formData, body)
  let scheme = call_606655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606655.url(scheme.get, call_606655.host, call_606655.base,
                         call_606655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606655, url, valid)

proc call*(call_606656: Call_UpdateAdmChannel_606643; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606657 = newJObject()
  var body_606658 = newJObject()
  add(path_606657, "application-id", newJString(applicationId))
  if body != nil:
    body_606658 = body
  result = call_606656.call(path_606657, nil, nil, nil, body_606658)

var updateAdmChannel* = Call_UpdateAdmChannel_606643(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_606644, base: "/",
    url: url_UpdateAdmChannel_606645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_606629 = ref object of OpenApiRestCall_605573
proc url_GetAdmChannel_606631(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_606630(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606632 = path.getOrDefault("application-id")
  valid_606632 = validateParameter(valid_606632, JString, required = true,
                                 default = nil)
  if valid_606632 != nil:
    section.add "application-id", valid_606632
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
  var valid_606633 = header.getOrDefault("X-Amz-Signature")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Signature", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Content-Sha256", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Date")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Date", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Credential")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Credential", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Security-Token")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Security-Token", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Algorithm")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Algorithm", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-SignedHeaders", valid_606639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606640: Call_GetAdmChannel_606629; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_606640.validator(path, query, header, formData, body)
  let scheme = call_606640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606640.url(scheme.get, call_606640.host, call_606640.base,
                         call_606640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606640, url, valid)

proc call*(call_606641: Call_GetAdmChannel_606629; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606642 = newJObject()
  add(path_606642, "application-id", newJString(applicationId))
  result = call_606641.call(path_606642, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_606629(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_606630, base: "/", url: url_GetAdmChannel_606631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_606659 = ref object of OpenApiRestCall_605573
proc url_DeleteAdmChannel_606661(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_606660(path: JsonNode; query: JsonNode;
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
  var valid_606662 = path.getOrDefault("application-id")
  valid_606662 = validateParameter(valid_606662, JString, required = true,
                                 default = nil)
  if valid_606662 != nil:
    section.add "application-id", valid_606662
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
  var valid_606663 = header.getOrDefault("X-Amz-Signature")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Signature", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Content-Sha256", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Date")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Date", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Credential")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Credential", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Security-Token")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Security-Token", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Algorithm")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Algorithm", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-SignedHeaders", valid_606669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606670: Call_DeleteAdmChannel_606659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606670.validator(path, query, header, formData, body)
  let scheme = call_606670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606670.url(scheme.get, call_606670.host, call_606670.base,
                         call_606670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606670, url, valid)

proc call*(call_606671: Call_DeleteAdmChannel_606659; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606672 = newJObject()
  add(path_606672, "application-id", newJString(applicationId))
  result = call_606671.call(path_606672, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_606659(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_606660, base: "/",
    url: url_DeleteAdmChannel_606661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_606687 = ref object of OpenApiRestCall_605573
proc url_UpdateApnsChannel_606689(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_606688(path: JsonNode; query: JsonNode;
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
  var valid_606690 = path.getOrDefault("application-id")
  valid_606690 = validateParameter(valid_606690, JString, required = true,
                                 default = nil)
  if valid_606690 != nil:
    section.add "application-id", valid_606690
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
  var valid_606691 = header.getOrDefault("X-Amz-Signature")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Signature", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Content-Sha256", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Date")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Date", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Credential")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Credential", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Security-Token")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Security-Token", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Algorithm")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Algorithm", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-SignedHeaders", valid_606697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606699: Call_UpdateApnsChannel_606687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_606699.validator(path, query, header, formData, body)
  let scheme = call_606699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606699.url(scheme.get, call_606699.host, call_606699.base,
                         call_606699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606699, url, valid)

proc call*(call_606700: Call_UpdateApnsChannel_606687; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606701 = newJObject()
  var body_606702 = newJObject()
  add(path_606701, "application-id", newJString(applicationId))
  if body != nil:
    body_606702 = body
  result = call_606700.call(path_606701, nil, nil, nil, body_606702)

var updateApnsChannel* = Call_UpdateApnsChannel_606687(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_606688, base: "/",
    url: url_UpdateApnsChannel_606689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_606673 = ref object of OpenApiRestCall_605573
proc url_GetApnsChannel_606675(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_606674(path: JsonNode; query: JsonNode;
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
  var valid_606676 = path.getOrDefault("application-id")
  valid_606676 = validateParameter(valid_606676, JString, required = true,
                                 default = nil)
  if valid_606676 != nil:
    section.add "application-id", valid_606676
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
  var valid_606677 = header.getOrDefault("X-Amz-Signature")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Signature", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Content-Sha256", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Date")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Date", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Credential")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Credential", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Security-Token")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Security-Token", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Algorithm")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Algorithm", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-SignedHeaders", valid_606683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606684: Call_GetApnsChannel_606673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_606684.validator(path, query, header, formData, body)
  let scheme = call_606684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606684.url(scheme.get, call_606684.host, call_606684.base,
                         call_606684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606684, url, valid)

proc call*(call_606685: Call_GetApnsChannel_606673; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606686 = newJObject()
  add(path_606686, "application-id", newJString(applicationId))
  result = call_606685.call(path_606686, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_606673(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_606674, base: "/", url: url_GetApnsChannel_606675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_606703 = ref object of OpenApiRestCall_605573
proc url_DeleteApnsChannel_606705(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_606704(path: JsonNode; query: JsonNode;
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
  var valid_606706 = path.getOrDefault("application-id")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = nil)
  if valid_606706 != nil:
    section.add "application-id", valid_606706
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
  var valid_606707 = header.getOrDefault("X-Amz-Signature")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Signature", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Content-Sha256", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Date")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Date", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Credential")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Credential", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Security-Token")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Security-Token", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Algorithm")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Algorithm", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-SignedHeaders", valid_606713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606714: Call_DeleteApnsChannel_606703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606714.validator(path, query, header, formData, body)
  let scheme = call_606714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606714.url(scheme.get, call_606714.host, call_606714.base,
                         call_606714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606714, url, valid)

proc call*(call_606715: Call_DeleteApnsChannel_606703; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606716 = newJObject()
  add(path_606716, "application-id", newJString(applicationId))
  result = call_606715.call(path_606716, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_606703(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_606704, base: "/",
    url: url_DeleteApnsChannel_606705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_606731 = ref object of OpenApiRestCall_605573
proc url_UpdateApnsSandboxChannel_606733(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_606732(path: JsonNode; query: JsonNode;
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
  var valid_606734 = path.getOrDefault("application-id")
  valid_606734 = validateParameter(valid_606734, JString, required = true,
                                 default = nil)
  if valid_606734 != nil:
    section.add "application-id", valid_606734
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
  var valid_606735 = header.getOrDefault("X-Amz-Signature")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Signature", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Content-Sha256", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Date")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Date", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Credential")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Credential", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Security-Token")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Security-Token", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Algorithm")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Algorithm", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-SignedHeaders", valid_606741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606743: Call_UpdateApnsSandboxChannel_606731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_606743.validator(path, query, header, formData, body)
  let scheme = call_606743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606743.url(scheme.get, call_606743.host, call_606743.base,
                         call_606743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606743, url, valid)

proc call*(call_606744: Call_UpdateApnsSandboxChannel_606731;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606745 = newJObject()
  var body_606746 = newJObject()
  add(path_606745, "application-id", newJString(applicationId))
  if body != nil:
    body_606746 = body
  result = call_606744.call(path_606745, nil, nil, nil, body_606746)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_606731(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_606732, base: "/",
    url: url_UpdateApnsSandboxChannel_606733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_606717 = ref object of OpenApiRestCall_605573
proc url_GetApnsSandboxChannel_606719(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_606718(path: JsonNode; query: JsonNode;
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
  var valid_606720 = path.getOrDefault("application-id")
  valid_606720 = validateParameter(valid_606720, JString, required = true,
                                 default = nil)
  if valid_606720 != nil:
    section.add "application-id", valid_606720
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
  var valid_606721 = header.getOrDefault("X-Amz-Signature")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Signature", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Content-Sha256", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Date")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Date", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Credential")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Credential", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Security-Token")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Security-Token", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Algorithm")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Algorithm", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-SignedHeaders", valid_606727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606728: Call_GetApnsSandboxChannel_606717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_606728.validator(path, query, header, formData, body)
  let scheme = call_606728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606728.url(scheme.get, call_606728.host, call_606728.base,
                         call_606728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606728, url, valid)

proc call*(call_606729: Call_GetApnsSandboxChannel_606717; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606730 = newJObject()
  add(path_606730, "application-id", newJString(applicationId))
  result = call_606729.call(path_606730, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_606717(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_606718, base: "/",
    url: url_GetApnsSandboxChannel_606719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_606747 = ref object of OpenApiRestCall_605573
proc url_DeleteApnsSandboxChannel_606749(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_606748(path: JsonNode; query: JsonNode;
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
  var valid_606750 = path.getOrDefault("application-id")
  valid_606750 = validateParameter(valid_606750, JString, required = true,
                                 default = nil)
  if valid_606750 != nil:
    section.add "application-id", valid_606750
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
  var valid_606751 = header.getOrDefault("X-Amz-Signature")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Signature", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Content-Sha256", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Date")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Date", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Credential")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Credential", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Security-Token")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Security-Token", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Algorithm")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Algorithm", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-SignedHeaders", valid_606757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606758: Call_DeleteApnsSandboxChannel_606747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606758.validator(path, query, header, formData, body)
  let scheme = call_606758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606758.url(scheme.get, call_606758.host, call_606758.base,
                         call_606758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606758, url, valid)

proc call*(call_606759: Call_DeleteApnsSandboxChannel_606747; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606760 = newJObject()
  add(path_606760, "application-id", newJString(applicationId))
  result = call_606759.call(path_606760, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_606747(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_606748, base: "/",
    url: url_DeleteApnsSandboxChannel_606749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_606775 = ref object of OpenApiRestCall_605573
proc url_UpdateApnsVoipChannel_606777(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_606776(path: JsonNode; query: JsonNode;
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
  var valid_606778 = path.getOrDefault("application-id")
  valid_606778 = validateParameter(valid_606778, JString, required = true,
                                 default = nil)
  if valid_606778 != nil:
    section.add "application-id", valid_606778
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
  var valid_606779 = header.getOrDefault("X-Amz-Signature")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Signature", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Content-Sha256", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Date")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Date", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Credential")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Credential", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Security-Token")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Security-Token", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Algorithm")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Algorithm", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-SignedHeaders", valid_606785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606787: Call_UpdateApnsVoipChannel_606775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_606787.validator(path, query, header, formData, body)
  let scheme = call_606787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606787.url(scheme.get, call_606787.host, call_606787.base,
                         call_606787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606787, url, valid)

proc call*(call_606788: Call_UpdateApnsVoipChannel_606775; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606789 = newJObject()
  var body_606790 = newJObject()
  add(path_606789, "application-id", newJString(applicationId))
  if body != nil:
    body_606790 = body
  result = call_606788.call(path_606789, nil, nil, nil, body_606790)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_606775(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_606776, base: "/",
    url: url_UpdateApnsVoipChannel_606777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_606761 = ref object of OpenApiRestCall_605573
proc url_GetApnsVoipChannel_606763(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_606762(path: JsonNode; query: JsonNode;
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
  var valid_606764 = path.getOrDefault("application-id")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "application-id", valid_606764
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
  var valid_606765 = header.getOrDefault("X-Amz-Signature")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Signature", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Content-Sha256", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Date")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Date", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Credential")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Credential", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Security-Token")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Security-Token", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Algorithm")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Algorithm", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-SignedHeaders", valid_606771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606772: Call_GetApnsVoipChannel_606761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_606772.validator(path, query, header, formData, body)
  let scheme = call_606772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606772.url(scheme.get, call_606772.host, call_606772.base,
                         call_606772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606772, url, valid)

proc call*(call_606773: Call_GetApnsVoipChannel_606761; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606774 = newJObject()
  add(path_606774, "application-id", newJString(applicationId))
  result = call_606773.call(path_606774, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_606761(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_606762, base: "/",
    url: url_GetApnsVoipChannel_606763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_606791 = ref object of OpenApiRestCall_605573
proc url_DeleteApnsVoipChannel_606793(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_606792(path: JsonNode; query: JsonNode;
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
  var valid_606794 = path.getOrDefault("application-id")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = nil)
  if valid_606794 != nil:
    section.add "application-id", valid_606794
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
  var valid_606795 = header.getOrDefault("X-Amz-Signature")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Signature", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Content-Sha256", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Date")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Date", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Credential")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Credential", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Security-Token")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Security-Token", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Algorithm")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Algorithm", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-SignedHeaders", valid_606801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_DeleteApnsVoipChannel_606791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_DeleteApnsVoipChannel_606791; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606804 = newJObject()
  add(path_606804, "application-id", newJString(applicationId))
  result = call_606803.call(path_606804, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_606791(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_606792, base: "/",
    url: url_DeleteApnsVoipChannel_606793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_606819 = ref object of OpenApiRestCall_605573
proc url_UpdateApnsVoipSandboxChannel_606821(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_606820(path: JsonNode; query: JsonNode;
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
  var valid_606822 = path.getOrDefault("application-id")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = nil)
  if valid_606822 != nil:
    section.add "application-id", valid_606822
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
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Algorithm")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Algorithm", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-SignedHeaders", valid_606829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606831: Call_UpdateApnsVoipSandboxChannel_606819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_606831.validator(path, query, header, formData, body)
  let scheme = call_606831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606831.url(scheme.get, call_606831.host, call_606831.base,
                         call_606831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606831, url, valid)

proc call*(call_606832: Call_UpdateApnsVoipSandboxChannel_606819;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606833 = newJObject()
  var body_606834 = newJObject()
  add(path_606833, "application-id", newJString(applicationId))
  if body != nil:
    body_606834 = body
  result = call_606832.call(path_606833, nil, nil, nil, body_606834)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_606819(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_606820, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_606821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_606805 = ref object of OpenApiRestCall_605573
proc url_GetApnsVoipSandboxChannel_606807(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_606806(path: JsonNode; query: JsonNode;
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
  var valid_606808 = path.getOrDefault("application-id")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = nil)
  if valid_606808 != nil:
    section.add "application-id", valid_606808
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
  var valid_606809 = header.getOrDefault("X-Amz-Signature")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Signature", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Content-Sha256", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Date")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Date", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Credential")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Credential", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Security-Token")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Security-Token", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Algorithm")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Algorithm", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-SignedHeaders", valid_606815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606816: Call_GetApnsVoipSandboxChannel_606805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_606816.validator(path, query, header, formData, body)
  let scheme = call_606816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606816.url(scheme.get, call_606816.host, call_606816.base,
                         call_606816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606816, url, valid)

proc call*(call_606817: Call_GetApnsVoipSandboxChannel_606805;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606818 = newJObject()
  add(path_606818, "application-id", newJString(applicationId))
  result = call_606817.call(path_606818, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_606805(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_606806, base: "/",
    url: url_GetApnsVoipSandboxChannel_606807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_606835 = ref object of OpenApiRestCall_605573
proc url_DeleteApnsVoipSandboxChannel_606837(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_606836(path: JsonNode; query: JsonNode;
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
  var valid_606838 = path.getOrDefault("application-id")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "application-id", valid_606838
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
  var valid_606839 = header.getOrDefault("X-Amz-Signature")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Signature", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Content-Sha256", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Date")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Date", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Credential")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Credential", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Security-Token")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Security-Token", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Algorithm")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Algorithm", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-SignedHeaders", valid_606845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606846: Call_DeleteApnsVoipSandboxChannel_606835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606846.validator(path, query, header, formData, body)
  let scheme = call_606846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606846.url(scheme.get, call_606846.host, call_606846.base,
                         call_606846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606846, url, valid)

proc call*(call_606847: Call_DeleteApnsVoipSandboxChannel_606835;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606848 = newJObject()
  add(path_606848, "application-id", newJString(applicationId))
  result = call_606847.call(path_606848, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_606835(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_606836, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_606837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_606849 = ref object of OpenApiRestCall_605573
proc url_GetApp_606851(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_606850(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606852 = path.getOrDefault("application-id")
  valid_606852 = validateParameter(valid_606852, JString, required = true,
                                 default = nil)
  if valid_606852 != nil:
    section.add "application-id", valid_606852
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
  var valid_606853 = header.getOrDefault("X-Amz-Signature")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Signature", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Content-Sha256", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Date")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Date", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Credential")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Credential", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Security-Token")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Security-Token", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Algorithm")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Algorithm", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-SignedHeaders", valid_606859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606860: Call_GetApp_606849; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_606860.validator(path, query, header, formData, body)
  let scheme = call_606860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606860.url(scheme.get, call_606860.host, call_606860.base,
                         call_606860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606860, url, valid)

proc call*(call_606861: Call_GetApp_606849; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606862 = newJObject()
  add(path_606862, "application-id", newJString(applicationId))
  result = call_606861.call(path_606862, nil, nil, nil, nil)

var getApp* = Call_GetApp_606849(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_606850, base: "/",
                              url: url_GetApp_606851,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_606863 = ref object of OpenApiRestCall_605573
proc url_DeleteApp_606865(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_606864(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606866 = path.getOrDefault("application-id")
  valid_606866 = validateParameter(valid_606866, JString, required = true,
                                 default = nil)
  if valid_606866 != nil:
    section.add "application-id", valid_606866
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
  var valid_606867 = header.getOrDefault("X-Amz-Signature")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Signature", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Content-Sha256", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Date")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Date", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Credential")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Credential", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Security-Token")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Security-Token", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Algorithm")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Algorithm", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-SignedHeaders", valid_606873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606874: Call_DeleteApp_606863; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_606874.validator(path, query, header, formData, body)
  let scheme = call_606874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606874.url(scheme.get, call_606874.host, call_606874.base,
                         call_606874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606874, url, valid)

proc call*(call_606875: Call_DeleteApp_606863; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606876 = newJObject()
  add(path_606876, "application-id", newJString(applicationId))
  result = call_606875.call(path_606876, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_606863(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_606864,
                                    base: "/", url: url_DeleteApp_606865,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_606891 = ref object of OpenApiRestCall_605573
proc url_UpdateBaiduChannel_606893(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_606892(path: JsonNode; query: JsonNode;
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
  var valid_606894 = path.getOrDefault("application-id")
  valid_606894 = validateParameter(valid_606894, JString, required = true,
                                 default = nil)
  if valid_606894 != nil:
    section.add "application-id", valid_606894
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
  var valid_606895 = header.getOrDefault("X-Amz-Signature")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Signature", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Content-Sha256", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Date")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Date", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Credential")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Credential", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Security-Token")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Security-Token", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Algorithm")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Algorithm", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-SignedHeaders", valid_606901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606903: Call_UpdateBaiduChannel_606891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_606903.validator(path, query, header, formData, body)
  let scheme = call_606903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606903.url(scheme.get, call_606903.host, call_606903.base,
                         call_606903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606903, url, valid)

proc call*(call_606904: Call_UpdateBaiduChannel_606891; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606905 = newJObject()
  var body_606906 = newJObject()
  add(path_606905, "application-id", newJString(applicationId))
  if body != nil:
    body_606906 = body
  result = call_606904.call(path_606905, nil, nil, nil, body_606906)

var updateBaiduChannel* = Call_UpdateBaiduChannel_606891(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_606892, base: "/",
    url: url_UpdateBaiduChannel_606893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_606877 = ref object of OpenApiRestCall_605573
proc url_GetBaiduChannel_606879(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_606878(path: JsonNode; query: JsonNode;
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
  var valid_606880 = path.getOrDefault("application-id")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = nil)
  if valid_606880 != nil:
    section.add "application-id", valid_606880
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
  var valid_606881 = header.getOrDefault("X-Amz-Signature")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Signature", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Content-Sha256", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Date")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Date", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Credential")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Credential", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606888: Call_GetBaiduChannel_606877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_606888.validator(path, query, header, formData, body)
  let scheme = call_606888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606888.url(scheme.get, call_606888.host, call_606888.base,
                         call_606888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606888, url, valid)

proc call*(call_606889: Call_GetBaiduChannel_606877; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606890 = newJObject()
  add(path_606890, "application-id", newJString(applicationId))
  result = call_606889.call(path_606890, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_606877(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_606878, base: "/", url: url_GetBaiduChannel_606879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_606907 = ref object of OpenApiRestCall_605573
proc url_DeleteBaiduChannel_606909(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_606908(path: JsonNode; query: JsonNode;
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
  var valid_606910 = path.getOrDefault("application-id")
  valid_606910 = validateParameter(valid_606910, JString, required = true,
                                 default = nil)
  if valid_606910 != nil:
    section.add "application-id", valid_606910
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
  var valid_606911 = header.getOrDefault("X-Amz-Signature")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Signature", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Content-Sha256", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Date")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Date", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Credential")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Credential", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Security-Token")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Security-Token", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Algorithm")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Algorithm", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-SignedHeaders", valid_606917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606918: Call_DeleteBaiduChannel_606907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_606918.validator(path, query, header, formData, body)
  let scheme = call_606918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606918.url(scheme.get, call_606918.host, call_606918.base,
                         call_606918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606918, url, valid)

proc call*(call_606919: Call_DeleteBaiduChannel_606907; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606920 = newJObject()
  add(path_606920, "application-id", newJString(applicationId))
  result = call_606919.call(path_606920, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_606907(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_606908, base: "/",
    url: url_DeleteBaiduChannel_606909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_606936 = ref object of OpenApiRestCall_605573
proc url_UpdateCampaign_606938(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_606937(path: JsonNode; query: JsonNode;
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
  var valid_606939 = path.getOrDefault("application-id")
  valid_606939 = validateParameter(valid_606939, JString, required = true,
                                 default = nil)
  if valid_606939 != nil:
    section.add "application-id", valid_606939
  var valid_606940 = path.getOrDefault("campaign-id")
  valid_606940 = validateParameter(valid_606940, JString, required = true,
                                 default = nil)
  if valid_606940 != nil:
    section.add "campaign-id", valid_606940
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
  var valid_606941 = header.getOrDefault("X-Amz-Signature")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Signature", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Content-Sha256", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Date")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Date", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Credential")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Credential", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Security-Token")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Security-Token", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Algorithm")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Algorithm", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-SignedHeaders", valid_606947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606949: Call_UpdateCampaign_606936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_606949.validator(path, query, header, formData, body)
  let scheme = call_606949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606949.url(scheme.get, call_606949.host, call_606949.base,
                         call_606949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606949, url, valid)

proc call*(call_606950: Call_UpdateCampaign_606936; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_606951 = newJObject()
  var body_606952 = newJObject()
  add(path_606951, "application-id", newJString(applicationId))
  if body != nil:
    body_606952 = body
  add(path_606951, "campaign-id", newJString(campaignId))
  result = call_606950.call(path_606951, nil, nil, nil, body_606952)

var updateCampaign* = Call_UpdateCampaign_606936(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_606937, base: "/", url: url_UpdateCampaign_606938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_606921 = ref object of OpenApiRestCall_605573
proc url_GetCampaign_606923(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_606922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606924 = path.getOrDefault("application-id")
  valid_606924 = validateParameter(valid_606924, JString, required = true,
                                 default = nil)
  if valid_606924 != nil:
    section.add "application-id", valid_606924
  var valid_606925 = path.getOrDefault("campaign-id")
  valid_606925 = validateParameter(valid_606925, JString, required = true,
                                 default = nil)
  if valid_606925 != nil:
    section.add "campaign-id", valid_606925
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
  var valid_606926 = header.getOrDefault("X-Amz-Signature")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Signature", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Content-Sha256", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Date")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Date", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Credential")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Credential", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Security-Token")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Security-Token", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Algorithm")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Algorithm", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-SignedHeaders", valid_606932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606933: Call_GetCampaign_606921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_606933.validator(path, query, header, formData, body)
  let scheme = call_606933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606933.url(scheme.get, call_606933.host, call_606933.base,
                         call_606933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606933, url, valid)

proc call*(call_606934: Call_GetCampaign_606921; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_606935 = newJObject()
  add(path_606935, "application-id", newJString(applicationId))
  add(path_606935, "campaign-id", newJString(campaignId))
  result = call_606934.call(path_606935, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_606921(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_606922,
                                        base: "/", url: url_GetCampaign_606923,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_606953 = ref object of OpenApiRestCall_605573
proc url_DeleteCampaign_606955(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_606954(path: JsonNode; query: JsonNode;
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
  var valid_606956 = path.getOrDefault("application-id")
  valid_606956 = validateParameter(valid_606956, JString, required = true,
                                 default = nil)
  if valid_606956 != nil:
    section.add "application-id", valid_606956
  var valid_606957 = path.getOrDefault("campaign-id")
  valid_606957 = validateParameter(valid_606957, JString, required = true,
                                 default = nil)
  if valid_606957 != nil:
    section.add "campaign-id", valid_606957
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
  var valid_606958 = header.getOrDefault("X-Amz-Signature")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Signature", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Content-Sha256", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Date")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Date", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Credential")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Credential", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Security-Token")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Security-Token", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Algorithm")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Algorithm", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-SignedHeaders", valid_606964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606965: Call_DeleteCampaign_606953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_606965.validator(path, query, header, formData, body)
  let scheme = call_606965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606965.url(scheme.get, call_606965.host, call_606965.base,
                         call_606965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606965, url, valid)

proc call*(call_606966: Call_DeleteCampaign_606953; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_606967 = newJObject()
  add(path_606967, "application-id", newJString(applicationId))
  add(path_606967, "campaign-id", newJString(campaignId))
  result = call_606966.call(path_606967, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_606953(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_606954, base: "/", url: url_DeleteCampaign_606955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_606982 = ref object of OpenApiRestCall_605573
proc url_UpdateEmailChannel_606984(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_606983(path: JsonNode; query: JsonNode;
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
  var valid_606985 = path.getOrDefault("application-id")
  valid_606985 = validateParameter(valid_606985, JString, required = true,
                                 default = nil)
  if valid_606985 != nil:
    section.add "application-id", valid_606985
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
  var valid_606986 = header.getOrDefault("X-Amz-Signature")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Signature", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Content-Sha256", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Date")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Date", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Credential")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Credential", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Security-Token")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Security-Token", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Algorithm")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Algorithm", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-SignedHeaders", valid_606992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606994: Call_UpdateEmailChannel_606982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_606994.validator(path, query, header, formData, body)
  let scheme = call_606994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606994.url(scheme.get, call_606994.host, call_606994.base,
                         call_606994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606994, url, valid)

proc call*(call_606995: Call_UpdateEmailChannel_606982; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_606996 = newJObject()
  var body_606997 = newJObject()
  add(path_606996, "application-id", newJString(applicationId))
  if body != nil:
    body_606997 = body
  result = call_606995.call(path_606996, nil, nil, nil, body_606997)

var updateEmailChannel* = Call_UpdateEmailChannel_606982(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_606983, base: "/",
    url: url_UpdateEmailChannel_606984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_606968 = ref object of OpenApiRestCall_605573
proc url_GetEmailChannel_606970(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_606969(path: JsonNode; query: JsonNode;
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
  var valid_606971 = path.getOrDefault("application-id")
  valid_606971 = validateParameter(valid_606971, JString, required = true,
                                 default = nil)
  if valid_606971 != nil:
    section.add "application-id", valid_606971
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
  var valid_606972 = header.getOrDefault("X-Amz-Signature")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Signature", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Content-Sha256", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Date")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Date", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Credential")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Credential", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Security-Token")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Security-Token", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Algorithm")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Algorithm", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-SignedHeaders", valid_606978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606979: Call_GetEmailChannel_606968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_606979.validator(path, query, header, formData, body)
  let scheme = call_606979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606979.url(scheme.get, call_606979.host, call_606979.base,
                         call_606979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606979, url, valid)

proc call*(call_606980: Call_GetEmailChannel_606968; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_606981 = newJObject()
  add(path_606981, "application-id", newJString(applicationId))
  result = call_606980.call(path_606981, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_606968(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_606969, base: "/", url: url_GetEmailChannel_606970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_606998 = ref object of OpenApiRestCall_605573
proc url_DeleteEmailChannel_607000(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_606999(path: JsonNode; query: JsonNode;
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
  var valid_607001 = path.getOrDefault("application-id")
  valid_607001 = validateParameter(valid_607001, JString, required = true,
                                 default = nil)
  if valid_607001 != nil:
    section.add "application-id", valid_607001
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
  var valid_607002 = header.getOrDefault("X-Amz-Signature")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Signature", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Content-Sha256", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-Date")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-Date", valid_607004
  var valid_607005 = header.getOrDefault("X-Amz-Credential")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Credential", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Security-Token")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Security-Token", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Algorithm")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Algorithm", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-SignedHeaders", valid_607008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607009: Call_DeleteEmailChannel_606998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_607009.validator(path, query, header, formData, body)
  let scheme = call_607009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607009.url(scheme.get, call_607009.host, call_607009.base,
                         call_607009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607009, url, valid)

proc call*(call_607010: Call_DeleteEmailChannel_606998; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607011 = newJObject()
  add(path_607011, "application-id", newJString(applicationId))
  result = call_607010.call(path_607011, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_606998(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_606999, base: "/",
    url: url_DeleteEmailChannel_607000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_607027 = ref object of OpenApiRestCall_605573
proc url_UpdateEndpoint_607029(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_607028(path: JsonNode; query: JsonNode;
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
  var valid_607030 = path.getOrDefault("application-id")
  valid_607030 = validateParameter(valid_607030, JString, required = true,
                                 default = nil)
  if valid_607030 != nil:
    section.add "application-id", valid_607030
  var valid_607031 = path.getOrDefault("endpoint-id")
  valid_607031 = validateParameter(valid_607031, JString, required = true,
                                 default = nil)
  if valid_607031 != nil:
    section.add "endpoint-id", valid_607031
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
  var valid_607032 = header.getOrDefault("X-Amz-Signature")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Signature", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Content-Sha256", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Date")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Date", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Credential")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Credential", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Security-Token")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Security-Token", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Algorithm")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Algorithm", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-SignedHeaders", valid_607038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607040: Call_UpdateEndpoint_607027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_607040.validator(path, query, header, formData, body)
  let scheme = call_607040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607040.url(scheme.get, call_607040.host, call_607040.base,
                         call_607040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607040, url, valid)

proc call*(call_607041: Call_UpdateEndpoint_607027; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_607042 = newJObject()
  var body_607043 = newJObject()
  add(path_607042, "application-id", newJString(applicationId))
  if body != nil:
    body_607043 = body
  add(path_607042, "endpoint-id", newJString(endpointId))
  result = call_607041.call(path_607042, nil, nil, nil, body_607043)

var updateEndpoint* = Call_UpdateEndpoint_607027(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_607028, base: "/", url: url_UpdateEndpoint_607029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_607012 = ref object of OpenApiRestCall_605573
proc url_GetEndpoint_607014(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_607013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607015 = path.getOrDefault("application-id")
  valid_607015 = validateParameter(valid_607015, JString, required = true,
                                 default = nil)
  if valid_607015 != nil:
    section.add "application-id", valid_607015
  var valid_607016 = path.getOrDefault("endpoint-id")
  valid_607016 = validateParameter(valid_607016, JString, required = true,
                                 default = nil)
  if valid_607016 != nil:
    section.add "endpoint-id", valid_607016
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
  var valid_607017 = header.getOrDefault("X-Amz-Signature")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "X-Amz-Signature", valid_607017
  var valid_607018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Content-Sha256", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Date")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Date", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Credential")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Credential", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Security-Token")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Security-Token", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Algorithm")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Algorithm", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-SignedHeaders", valid_607023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607024: Call_GetEndpoint_607012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_607024.validator(path, query, header, formData, body)
  let scheme = call_607024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607024.url(scheme.get, call_607024.host, call_607024.base,
                         call_607024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607024, url, valid)

proc call*(call_607025: Call_GetEndpoint_607012; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_607026 = newJObject()
  add(path_607026, "application-id", newJString(applicationId))
  add(path_607026, "endpoint-id", newJString(endpointId))
  result = call_607025.call(path_607026, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_607012(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_607013,
                                        base: "/", url: url_GetEndpoint_607014,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_607044 = ref object of OpenApiRestCall_605573
proc url_DeleteEndpoint_607046(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_607045(path: JsonNode; query: JsonNode;
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
  var valid_607047 = path.getOrDefault("application-id")
  valid_607047 = validateParameter(valid_607047, JString, required = true,
                                 default = nil)
  if valid_607047 != nil:
    section.add "application-id", valid_607047
  var valid_607048 = path.getOrDefault("endpoint-id")
  valid_607048 = validateParameter(valid_607048, JString, required = true,
                                 default = nil)
  if valid_607048 != nil:
    section.add "endpoint-id", valid_607048
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
  var valid_607049 = header.getOrDefault("X-Amz-Signature")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Signature", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Content-Sha256", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Date")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Date", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Credential")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Credential", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-Security-Token")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-Security-Token", valid_607053
  var valid_607054 = header.getOrDefault("X-Amz-Algorithm")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "X-Amz-Algorithm", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-SignedHeaders", valid_607055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607056: Call_DeleteEndpoint_607044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_607056.validator(path, query, header, formData, body)
  let scheme = call_607056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607056.url(scheme.get, call_607056.host, call_607056.base,
                         call_607056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607056, url, valid)

proc call*(call_607057: Call_DeleteEndpoint_607044; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_607058 = newJObject()
  add(path_607058, "application-id", newJString(applicationId))
  add(path_607058, "endpoint-id", newJString(endpointId))
  result = call_607057.call(path_607058, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_607044(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_607045, base: "/", url: url_DeleteEndpoint_607046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_607073 = ref object of OpenApiRestCall_605573
proc url_PutEventStream_607075(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_607074(path: JsonNode; query: JsonNode;
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
  var valid_607076 = path.getOrDefault("application-id")
  valid_607076 = validateParameter(valid_607076, JString, required = true,
                                 default = nil)
  if valid_607076 != nil:
    section.add "application-id", valid_607076
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
  var valid_607077 = header.getOrDefault("X-Amz-Signature")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Signature", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Content-Sha256", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Date")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Date", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Credential")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Credential", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Security-Token")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Security-Token", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Algorithm")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Algorithm", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-SignedHeaders", valid_607083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_PutEventStream_607073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607086: Call_PutEventStream_607073; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607087 = newJObject()
  var body_607088 = newJObject()
  add(path_607087, "application-id", newJString(applicationId))
  if body != nil:
    body_607088 = body
  result = call_607086.call(path_607087, nil, nil, nil, body_607088)

var putEventStream* = Call_PutEventStream_607073(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_607074, base: "/", url: url_PutEventStream_607075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_607059 = ref object of OpenApiRestCall_605573
proc url_GetEventStream_607061(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_607060(path: JsonNode; query: JsonNode;
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
  var valid_607062 = path.getOrDefault("application-id")
  valid_607062 = validateParameter(valid_607062, JString, required = true,
                                 default = nil)
  if valid_607062 != nil:
    section.add "application-id", valid_607062
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
  var valid_607063 = header.getOrDefault("X-Amz-Signature")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Signature", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Content-Sha256", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Date")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Date", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Credential")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Credential", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Security-Token")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Security-Token", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Algorithm")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Algorithm", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-SignedHeaders", valid_607069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607070: Call_GetEventStream_607059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_607070.validator(path, query, header, formData, body)
  let scheme = call_607070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607070.url(scheme.get, call_607070.host, call_607070.base,
                         call_607070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607070, url, valid)

proc call*(call_607071: Call_GetEventStream_607059; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607072 = newJObject()
  add(path_607072, "application-id", newJString(applicationId))
  result = call_607071.call(path_607072, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_607059(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_607060, base: "/", url: url_GetEventStream_607061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_607089 = ref object of OpenApiRestCall_605573
proc url_DeleteEventStream_607091(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_607090(path: JsonNode; query: JsonNode;
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
  var valid_607092 = path.getOrDefault("application-id")
  valid_607092 = validateParameter(valid_607092, JString, required = true,
                                 default = nil)
  if valid_607092 != nil:
    section.add "application-id", valid_607092
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
  var valid_607093 = header.getOrDefault("X-Amz-Signature")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Signature", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Content-Sha256", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Date")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Date", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Credential")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Credential", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Security-Token")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Security-Token", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Algorithm")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Algorithm", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-SignedHeaders", valid_607099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607100: Call_DeleteEventStream_607089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_607100.validator(path, query, header, formData, body)
  let scheme = call_607100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607100.url(scheme.get, call_607100.host, call_607100.base,
                         call_607100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607100, url, valid)

proc call*(call_607101: Call_DeleteEventStream_607089; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607102 = newJObject()
  add(path_607102, "application-id", newJString(applicationId))
  result = call_607101.call(path_607102, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_607089(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_607090, base: "/",
    url: url_DeleteEventStream_607091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_607117 = ref object of OpenApiRestCall_605573
proc url_UpdateGcmChannel_607119(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_607118(path: JsonNode; query: JsonNode;
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
  var valid_607120 = path.getOrDefault("application-id")
  valid_607120 = validateParameter(valid_607120, JString, required = true,
                                 default = nil)
  if valid_607120 != nil:
    section.add "application-id", valid_607120
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
  var valid_607121 = header.getOrDefault("X-Amz-Signature")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Signature", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Content-Sha256", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Date")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Date", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Credential")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Credential", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Security-Token")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Security-Token", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Algorithm")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Algorithm", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-SignedHeaders", valid_607127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607129: Call_UpdateGcmChannel_607117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_607129.validator(path, query, header, formData, body)
  let scheme = call_607129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607129.url(scheme.get, call_607129.host, call_607129.base,
                         call_607129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607129, url, valid)

proc call*(call_607130: Call_UpdateGcmChannel_607117; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607131 = newJObject()
  var body_607132 = newJObject()
  add(path_607131, "application-id", newJString(applicationId))
  if body != nil:
    body_607132 = body
  result = call_607130.call(path_607131, nil, nil, nil, body_607132)

var updateGcmChannel* = Call_UpdateGcmChannel_607117(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_607118, base: "/",
    url: url_UpdateGcmChannel_607119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_607103 = ref object of OpenApiRestCall_605573
proc url_GetGcmChannel_607105(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_607104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607106 = path.getOrDefault("application-id")
  valid_607106 = validateParameter(valid_607106, JString, required = true,
                                 default = nil)
  if valid_607106 != nil:
    section.add "application-id", valid_607106
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
  var valid_607107 = header.getOrDefault("X-Amz-Signature")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Signature", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Content-Sha256", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Date")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Date", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Credential")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Credential", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Security-Token")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Security-Token", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Algorithm")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Algorithm", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-SignedHeaders", valid_607113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607114: Call_GetGcmChannel_607103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_607114.validator(path, query, header, formData, body)
  let scheme = call_607114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607114.url(scheme.get, call_607114.host, call_607114.base,
                         call_607114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607114, url, valid)

proc call*(call_607115: Call_GetGcmChannel_607103; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607116 = newJObject()
  add(path_607116, "application-id", newJString(applicationId))
  result = call_607115.call(path_607116, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_607103(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_607104, base: "/", url: url_GetGcmChannel_607105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_607133 = ref object of OpenApiRestCall_605573
proc url_DeleteGcmChannel_607135(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_607134(path: JsonNode; query: JsonNode;
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
  var valid_607136 = path.getOrDefault("application-id")
  valid_607136 = validateParameter(valid_607136, JString, required = true,
                                 default = nil)
  if valid_607136 != nil:
    section.add "application-id", valid_607136
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
  var valid_607137 = header.getOrDefault("X-Amz-Signature")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-Signature", valid_607137
  var valid_607138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Content-Sha256", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Date")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Date", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Credential")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Credential", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Security-Token")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Security-Token", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Algorithm")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Algorithm", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-SignedHeaders", valid_607143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607144: Call_DeleteGcmChannel_607133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_607144.validator(path, query, header, formData, body)
  let scheme = call_607144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607144.url(scheme.get, call_607144.host, call_607144.base,
                         call_607144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607144, url, valid)

proc call*(call_607145: Call_DeleteGcmChannel_607133; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607146 = newJObject()
  add(path_607146, "application-id", newJString(applicationId))
  result = call_607145.call(path_607146, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_607133(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_607134, base: "/",
    url: url_DeleteGcmChannel_607135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_607162 = ref object of OpenApiRestCall_605573
proc url_UpdateJourney_607164(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_607163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607165 = path.getOrDefault("application-id")
  valid_607165 = validateParameter(valid_607165, JString, required = true,
                                 default = nil)
  if valid_607165 != nil:
    section.add "application-id", valid_607165
  var valid_607166 = path.getOrDefault("journey-id")
  valid_607166 = validateParameter(valid_607166, JString, required = true,
                                 default = nil)
  if valid_607166 != nil:
    section.add "journey-id", valid_607166
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
  var valid_607167 = header.getOrDefault("X-Amz-Signature")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Signature", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Content-Sha256", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Date")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Date", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Credential")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Credential", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-Security-Token")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-Security-Token", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Algorithm")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Algorithm", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-SignedHeaders", valid_607173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607175: Call_UpdateJourney_607162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_607175.validator(path, query, header, formData, body)
  let scheme = call_607175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607175.url(scheme.get, call_607175.host, call_607175.base,
                         call_607175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607175, url, valid)

proc call*(call_607176: Call_UpdateJourney_607162; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_607177 = newJObject()
  var body_607178 = newJObject()
  add(path_607177, "application-id", newJString(applicationId))
  if body != nil:
    body_607178 = body
  add(path_607177, "journey-id", newJString(journeyId))
  result = call_607176.call(path_607177, nil, nil, nil, body_607178)

var updateJourney* = Call_UpdateJourney_607162(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_607163, base: "/", url: url_UpdateJourney_607164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_607147 = ref object of OpenApiRestCall_605573
proc url_GetJourney_607149(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJourney_607148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607150 = path.getOrDefault("application-id")
  valid_607150 = validateParameter(valid_607150, JString, required = true,
                                 default = nil)
  if valid_607150 != nil:
    section.add "application-id", valid_607150
  var valid_607151 = path.getOrDefault("journey-id")
  valid_607151 = validateParameter(valid_607151, JString, required = true,
                                 default = nil)
  if valid_607151 != nil:
    section.add "journey-id", valid_607151
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
  var valid_607152 = header.getOrDefault("X-Amz-Signature")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Signature", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Content-Sha256", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Date")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Date", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Credential")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Credential", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-Security-Token")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Security-Token", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Algorithm")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Algorithm", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-SignedHeaders", valid_607158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607159: Call_GetJourney_607147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_607159.validator(path, query, header, formData, body)
  let scheme = call_607159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607159.url(scheme.get, call_607159.host, call_607159.base,
                         call_607159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607159, url, valid)

proc call*(call_607160: Call_GetJourney_607147; applicationId: string;
          journeyId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_607161 = newJObject()
  add(path_607161, "application-id", newJString(applicationId))
  add(path_607161, "journey-id", newJString(journeyId))
  result = call_607160.call(path_607161, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_607147(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_607148,
                                      base: "/", url: url_GetJourney_607149,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_607179 = ref object of OpenApiRestCall_605573
proc url_DeleteJourney_607181(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_607180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607182 = path.getOrDefault("application-id")
  valid_607182 = validateParameter(valid_607182, JString, required = true,
                                 default = nil)
  if valid_607182 != nil:
    section.add "application-id", valid_607182
  var valid_607183 = path.getOrDefault("journey-id")
  valid_607183 = validateParameter(valid_607183, JString, required = true,
                                 default = nil)
  if valid_607183 != nil:
    section.add "journey-id", valid_607183
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
  var valid_607184 = header.getOrDefault("X-Amz-Signature")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Signature", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Content-Sha256", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Date")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Date", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Credential")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Credential", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Security-Token")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Security-Token", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Algorithm")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Algorithm", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-SignedHeaders", valid_607190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607191: Call_DeleteJourney_607179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_607191.validator(path, query, header, formData, body)
  let scheme = call_607191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607191.url(scheme.get, call_607191.host, call_607191.base,
                         call_607191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607191, url, valid)

proc call*(call_607192: Call_DeleteJourney_607179; applicationId: string;
          journeyId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_607193 = newJObject()
  add(path_607193, "application-id", newJString(applicationId))
  add(path_607193, "journey-id", newJString(journeyId))
  result = call_607192.call(path_607193, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_607179(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_607180, base: "/", url: url_DeleteJourney_607181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_607209 = ref object of OpenApiRestCall_605573
proc url_UpdateSegment_607211(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_607210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607212 = path.getOrDefault("application-id")
  valid_607212 = validateParameter(valid_607212, JString, required = true,
                                 default = nil)
  if valid_607212 != nil:
    section.add "application-id", valid_607212
  var valid_607213 = path.getOrDefault("segment-id")
  valid_607213 = validateParameter(valid_607213, JString, required = true,
                                 default = nil)
  if valid_607213 != nil:
    section.add "segment-id", valid_607213
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
  var valid_607214 = header.getOrDefault("X-Amz-Signature")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Signature", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Content-Sha256", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Date")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Date", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Credential")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Credential", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Security-Token")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Security-Token", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Algorithm")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Algorithm", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-SignedHeaders", valid_607220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607222: Call_UpdateSegment_607209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_607222.validator(path, query, header, formData, body)
  let scheme = call_607222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607222.url(scheme.get, call_607222.host, call_607222.base,
                         call_607222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607222, url, valid)

proc call*(call_607223: Call_UpdateSegment_607209; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_607224 = newJObject()
  var body_607225 = newJObject()
  add(path_607224, "application-id", newJString(applicationId))
  add(path_607224, "segment-id", newJString(segmentId))
  if body != nil:
    body_607225 = body
  result = call_607223.call(path_607224, nil, nil, nil, body_607225)

var updateSegment* = Call_UpdateSegment_607209(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_607210, base: "/", url: url_UpdateSegment_607211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_607194 = ref object of OpenApiRestCall_605573
proc url_GetSegment_607196(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_607195(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607197 = path.getOrDefault("application-id")
  valid_607197 = validateParameter(valid_607197, JString, required = true,
                                 default = nil)
  if valid_607197 != nil:
    section.add "application-id", valid_607197
  var valid_607198 = path.getOrDefault("segment-id")
  valid_607198 = validateParameter(valid_607198, JString, required = true,
                                 default = nil)
  if valid_607198 != nil:
    section.add "segment-id", valid_607198
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
  var valid_607199 = header.getOrDefault("X-Amz-Signature")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Signature", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Content-Sha256", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Date")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Date", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Credential")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Credential", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Security-Token")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Security-Token", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Algorithm")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Algorithm", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-SignedHeaders", valid_607205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607206: Call_GetSegment_607194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_607206.validator(path, query, header, formData, body)
  let scheme = call_607206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607206.url(scheme.get, call_607206.host, call_607206.base,
                         call_607206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607206, url, valid)

proc call*(call_607207: Call_GetSegment_607194; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_607208 = newJObject()
  add(path_607208, "application-id", newJString(applicationId))
  add(path_607208, "segment-id", newJString(segmentId))
  result = call_607207.call(path_607208, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_607194(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_607195,
                                      base: "/", url: url_GetSegment_607196,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_607226 = ref object of OpenApiRestCall_605573
proc url_DeleteSegment_607228(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_607227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607229 = path.getOrDefault("application-id")
  valid_607229 = validateParameter(valid_607229, JString, required = true,
                                 default = nil)
  if valid_607229 != nil:
    section.add "application-id", valid_607229
  var valid_607230 = path.getOrDefault("segment-id")
  valid_607230 = validateParameter(valid_607230, JString, required = true,
                                 default = nil)
  if valid_607230 != nil:
    section.add "segment-id", valid_607230
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
  var valid_607231 = header.getOrDefault("X-Amz-Signature")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Signature", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Content-Sha256", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Date")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Date", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Credential")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Credential", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Security-Token")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Security-Token", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Algorithm")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Algorithm", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-SignedHeaders", valid_607237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607238: Call_DeleteSegment_607226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_607238.validator(path, query, header, formData, body)
  let scheme = call_607238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607238.url(scheme.get, call_607238.host, call_607238.base,
                         call_607238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607238, url, valid)

proc call*(call_607239: Call_DeleteSegment_607226; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_607240 = newJObject()
  add(path_607240, "application-id", newJString(applicationId))
  add(path_607240, "segment-id", newJString(segmentId))
  result = call_607239.call(path_607240, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_607226(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_607227, base: "/", url: url_DeleteSegment_607228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_607255 = ref object of OpenApiRestCall_605573
proc url_UpdateSmsChannel_607257(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_607256(path: JsonNode; query: JsonNode;
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
  var valid_607258 = path.getOrDefault("application-id")
  valid_607258 = validateParameter(valid_607258, JString, required = true,
                                 default = nil)
  if valid_607258 != nil:
    section.add "application-id", valid_607258
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
  var valid_607259 = header.getOrDefault("X-Amz-Signature")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "X-Amz-Signature", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Content-Sha256", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Date")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Date", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Credential")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Credential", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Security-Token")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Security-Token", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Algorithm")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Algorithm", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-SignedHeaders", valid_607265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607267: Call_UpdateSmsChannel_607255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_607267.validator(path, query, header, formData, body)
  let scheme = call_607267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607267.url(scheme.get, call_607267.host, call_607267.base,
                         call_607267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607267, url, valid)

proc call*(call_607268: Call_UpdateSmsChannel_607255; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607269 = newJObject()
  var body_607270 = newJObject()
  add(path_607269, "application-id", newJString(applicationId))
  if body != nil:
    body_607270 = body
  result = call_607268.call(path_607269, nil, nil, nil, body_607270)

var updateSmsChannel* = Call_UpdateSmsChannel_607255(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_607256, base: "/",
    url: url_UpdateSmsChannel_607257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_607241 = ref object of OpenApiRestCall_605573
proc url_GetSmsChannel_607243(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_607242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607244 = path.getOrDefault("application-id")
  valid_607244 = validateParameter(valid_607244, JString, required = true,
                                 default = nil)
  if valid_607244 != nil:
    section.add "application-id", valid_607244
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
  var valid_607245 = header.getOrDefault("X-Amz-Signature")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Signature", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Content-Sha256", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Date")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Date", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Credential")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Credential", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Security-Token")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Security-Token", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Algorithm")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Algorithm", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-SignedHeaders", valid_607251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607252: Call_GetSmsChannel_607241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_607252.validator(path, query, header, formData, body)
  let scheme = call_607252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607252.url(scheme.get, call_607252.host, call_607252.base,
                         call_607252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607252, url, valid)

proc call*(call_607253: Call_GetSmsChannel_607241; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607254 = newJObject()
  add(path_607254, "application-id", newJString(applicationId))
  result = call_607253.call(path_607254, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_607241(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_607242, base: "/", url: url_GetSmsChannel_607243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_607271 = ref object of OpenApiRestCall_605573
proc url_DeleteSmsChannel_607273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_607272(path: JsonNode; query: JsonNode;
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
  var valid_607274 = path.getOrDefault("application-id")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = nil)
  if valid_607274 != nil:
    section.add "application-id", valid_607274
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
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607282: Call_DeleteSmsChannel_607271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_607282.validator(path, query, header, formData, body)
  let scheme = call_607282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607282.url(scheme.get, call_607282.host, call_607282.base,
                         call_607282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607282, url, valid)

proc call*(call_607283: Call_DeleteSmsChannel_607271; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607284 = newJObject()
  add(path_607284, "application-id", newJString(applicationId))
  result = call_607283.call(path_607284, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_607271(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_607272, base: "/",
    url: url_DeleteSmsChannel_607273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_607285 = ref object of OpenApiRestCall_605573
proc url_GetUserEndpoints_607287(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_607286(path: JsonNode; query: JsonNode;
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
  var valid_607288 = path.getOrDefault("application-id")
  valid_607288 = validateParameter(valid_607288, JString, required = true,
                                 default = nil)
  if valid_607288 != nil:
    section.add "application-id", valid_607288
  var valid_607289 = path.getOrDefault("user-id")
  valid_607289 = validateParameter(valid_607289, JString, required = true,
                                 default = nil)
  if valid_607289 != nil:
    section.add "user-id", valid_607289
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
  var valid_607290 = header.getOrDefault("X-Amz-Signature")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Signature", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Content-Sha256", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Date")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Date", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Credential")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Credential", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Security-Token")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Security-Token", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Algorithm")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Algorithm", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-SignedHeaders", valid_607296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607297: Call_GetUserEndpoints_607285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_607297.validator(path, query, header, formData, body)
  let scheme = call_607297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607297.url(scheme.get, call_607297.host, call_607297.base,
                         call_607297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607297, url, valid)

proc call*(call_607298: Call_GetUserEndpoints_607285; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_607299 = newJObject()
  add(path_607299, "application-id", newJString(applicationId))
  add(path_607299, "user-id", newJString(userId))
  result = call_607298.call(path_607299, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_607285(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_607286, base: "/",
    url: url_GetUserEndpoints_607287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_607300 = ref object of OpenApiRestCall_605573
proc url_DeleteUserEndpoints_607302(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_607301(path: JsonNode; query: JsonNode;
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
  var valid_607303 = path.getOrDefault("application-id")
  valid_607303 = validateParameter(valid_607303, JString, required = true,
                                 default = nil)
  if valid_607303 != nil:
    section.add "application-id", valid_607303
  var valid_607304 = path.getOrDefault("user-id")
  valid_607304 = validateParameter(valid_607304, JString, required = true,
                                 default = nil)
  if valid_607304 != nil:
    section.add "user-id", valid_607304
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
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607312: Call_DeleteUserEndpoints_607300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_607312.validator(path, query, header, formData, body)
  let scheme = call_607312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607312.url(scheme.get, call_607312.host, call_607312.base,
                         call_607312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607312, url, valid)

proc call*(call_607313: Call_DeleteUserEndpoints_607300; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_607314 = newJObject()
  add(path_607314, "application-id", newJString(applicationId))
  add(path_607314, "user-id", newJString(userId))
  result = call_607313.call(path_607314, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_607300(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_607301, base: "/",
    url: url_DeleteUserEndpoints_607302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_607329 = ref object of OpenApiRestCall_605573
proc url_UpdateVoiceChannel_607331(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_607330(path: JsonNode; query: JsonNode;
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
  var valid_607332 = path.getOrDefault("application-id")
  valid_607332 = validateParameter(valid_607332, JString, required = true,
                                 default = nil)
  if valid_607332 != nil:
    section.add "application-id", valid_607332
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
  var valid_607333 = header.getOrDefault("X-Amz-Signature")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Signature", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Content-Sha256", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Date")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Date", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Credential")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Credential", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Security-Token")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Security-Token", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Algorithm")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Algorithm", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-SignedHeaders", valid_607339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607341: Call_UpdateVoiceChannel_607329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_607341.validator(path, query, header, formData, body)
  let scheme = call_607341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607341.url(scheme.get, call_607341.host, call_607341.base,
                         call_607341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607341, url, valid)

proc call*(call_607342: Call_UpdateVoiceChannel_607329; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607343 = newJObject()
  var body_607344 = newJObject()
  add(path_607343, "application-id", newJString(applicationId))
  if body != nil:
    body_607344 = body
  result = call_607342.call(path_607343, nil, nil, nil, body_607344)

var updateVoiceChannel* = Call_UpdateVoiceChannel_607329(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_607330, base: "/",
    url: url_UpdateVoiceChannel_607331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_607315 = ref object of OpenApiRestCall_605573
proc url_GetVoiceChannel_607317(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_607316(path: JsonNode; query: JsonNode;
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
  var valid_607318 = path.getOrDefault("application-id")
  valid_607318 = validateParameter(valid_607318, JString, required = true,
                                 default = nil)
  if valid_607318 != nil:
    section.add "application-id", valid_607318
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
  var valid_607319 = header.getOrDefault("X-Amz-Signature")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Signature", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Content-Sha256", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Date")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Date", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Credential")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Credential", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Security-Token")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Security-Token", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Algorithm")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Algorithm", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-SignedHeaders", valid_607325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607326: Call_GetVoiceChannel_607315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_607326.validator(path, query, header, formData, body)
  let scheme = call_607326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607326.url(scheme.get, call_607326.host, call_607326.base,
                         call_607326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607326, url, valid)

proc call*(call_607327: Call_GetVoiceChannel_607315; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607328 = newJObject()
  add(path_607328, "application-id", newJString(applicationId))
  result = call_607327.call(path_607328, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_607315(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_607316, base: "/", url: url_GetVoiceChannel_607317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_607345 = ref object of OpenApiRestCall_605573
proc url_DeleteVoiceChannel_607347(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_607346(path: JsonNode; query: JsonNode;
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
  var valid_607348 = path.getOrDefault("application-id")
  valid_607348 = validateParameter(valid_607348, JString, required = true,
                                 default = nil)
  if valid_607348 != nil:
    section.add "application-id", valid_607348
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
  var valid_607349 = header.getOrDefault("X-Amz-Signature")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Signature", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Content-Sha256", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Date")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Date", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Credential")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Credential", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Security-Token")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Security-Token", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Algorithm")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Algorithm", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-SignedHeaders", valid_607355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607356: Call_DeleteVoiceChannel_607345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_607356.validator(path, query, header, formData, body)
  let scheme = call_607356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607356.url(scheme.get, call_607356.host, call_607356.base,
                         call_607356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607356, url, valid)

proc call*(call_607357: Call_DeleteVoiceChannel_607345; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607358 = newJObject()
  add(path_607358, "application-id", newJString(applicationId))
  result = call_607357.call(path_607358, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_607345(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_607346, base: "/",
    url: url_DeleteVoiceChannel_607347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_607359 = ref object of OpenApiRestCall_605573
proc url_GetApplicationDateRangeKpi_607361(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_607360(path: JsonNode; query: JsonNode;
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
  var valid_607362 = path.getOrDefault("kpi-name")
  valid_607362 = validateParameter(valid_607362, JString, required = true,
                                 default = nil)
  if valid_607362 != nil:
    section.add "kpi-name", valid_607362
  var valid_607363 = path.getOrDefault("application-id")
  valid_607363 = validateParameter(valid_607363, JString, required = true,
                                 default = nil)
  if valid_607363 != nil:
    section.add "application-id", valid_607363
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
  var valid_607364 = query.getOrDefault("end-time")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "end-time", valid_607364
  var valid_607365 = query.getOrDefault("page-size")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "page-size", valid_607365
  var valid_607366 = query.getOrDefault("start-time")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "start-time", valid_607366
  var valid_607367 = query.getOrDefault("next-token")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "next-token", valid_607367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607368 = header.getOrDefault("X-Amz-Signature")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Signature", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Content-Sha256", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Date")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Date", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Credential")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Credential", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Security-Token")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Security-Token", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Algorithm")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Algorithm", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-SignedHeaders", valid_607374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607375: Call_GetApplicationDateRangeKpi_607359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_607375.validator(path, query, header, formData, body)
  let scheme = call_607375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607375.url(scheme.get, call_607375.host, call_607375.base,
                         call_607375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607375, url, valid)

proc call*(call_607376: Call_GetApplicationDateRangeKpi_607359; kpiName: string;
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
  var path_607377 = newJObject()
  var query_607378 = newJObject()
  add(path_607377, "kpi-name", newJString(kpiName))
  add(path_607377, "application-id", newJString(applicationId))
  add(query_607378, "end-time", newJString(endTime))
  add(query_607378, "page-size", newJString(pageSize))
  add(query_607378, "start-time", newJString(startTime))
  add(query_607378, "next-token", newJString(nextToken))
  result = call_607376.call(path_607377, query_607378, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_607359(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_607360, base: "/",
    url: url_GetApplicationDateRangeKpi_607361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_607393 = ref object of OpenApiRestCall_605573
proc url_UpdateApplicationSettings_607395(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_607394(path: JsonNode; query: JsonNode;
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
  var valid_607396 = path.getOrDefault("application-id")
  valid_607396 = validateParameter(valid_607396, JString, required = true,
                                 default = nil)
  if valid_607396 != nil:
    section.add "application-id", valid_607396
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
  var valid_607397 = header.getOrDefault("X-Amz-Signature")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Signature", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Content-Sha256", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Date")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Date", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Credential")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Credential", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Security-Token")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Security-Token", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Algorithm")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Algorithm", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-SignedHeaders", valid_607403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607405: Call_UpdateApplicationSettings_607393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_607405.validator(path, query, header, formData, body)
  let scheme = call_607405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607405.url(scheme.get, call_607405.host, call_607405.base,
                         call_607405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607405, url, valid)

proc call*(call_607406: Call_UpdateApplicationSettings_607393;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607407 = newJObject()
  var body_607408 = newJObject()
  add(path_607407, "application-id", newJString(applicationId))
  if body != nil:
    body_607408 = body
  result = call_607406.call(path_607407, nil, nil, nil, body_607408)

var updateApplicationSettings* = Call_UpdateApplicationSettings_607393(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_607394, base: "/",
    url: url_UpdateApplicationSettings_607395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_607379 = ref object of OpenApiRestCall_605573
proc url_GetApplicationSettings_607381(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_607380(path: JsonNode; query: JsonNode;
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
  var valid_607382 = path.getOrDefault("application-id")
  valid_607382 = validateParameter(valid_607382, JString, required = true,
                                 default = nil)
  if valid_607382 != nil:
    section.add "application-id", valid_607382
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
  var valid_607383 = header.getOrDefault("X-Amz-Signature")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Signature", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Content-Sha256", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Date")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Date", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Credential")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Credential", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Security-Token")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Security-Token", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Algorithm")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Algorithm", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-SignedHeaders", valid_607389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607390: Call_GetApplicationSettings_607379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_607390.validator(path, query, header, formData, body)
  let scheme = call_607390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607390.url(scheme.get, call_607390.host, call_607390.base,
                         call_607390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607390, url, valid)

proc call*(call_607391: Call_GetApplicationSettings_607379; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607392 = newJObject()
  add(path_607392, "application-id", newJString(applicationId))
  result = call_607391.call(path_607392, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_607379(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_607380, base: "/",
    url: url_GetApplicationSettings_607381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_607409 = ref object of OpenApiRestCall_605573
proc url_GetCampaignActivities_607411(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_607410(path: JsonNode; query: JsonNode;
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
  var valid_607412 = path.getOrDefault("application-id")
  valid_607412 = validateParameter(valid_607412, JString, required = true,
                                 default = nil)
  if valid_607412 != nil:
    section.add "application-id", valid_607412
  var valid_607413 = path.getOrDefault("campaign-id")
  valid_607413 = validateParameter(valid_607413, JString, required = true,
                                 default = nil)
  if valid_607413 != nil:
    section.add "campaign-id", valid_607413
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_607414 = query.getOrDefault("page-size")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "page-size", valid_607414
  var valid_607415 = query.getOrDefault("token")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "token", valid_607415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607416 = header.getOrDefault("X-Amz-Signature")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Signature", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Content-Sha256", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Date")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Date", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Credential")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Credential", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Security-Token")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Security-Token", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Algorithm")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Algorithm", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-SignedHeaders", valid_607422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607423: Call_GetCampaignActivities_607409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_607423.validator(path, query, header, formData, body)
  let scheme = call_607423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607423.url(scheme.get, call_607423.host, call_607423.base,
                         call_607423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607423, url, valid)

proc call*(call_607424: Call_GetCampaignActivities_607409; applicationId: string;
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
  var path_607425 = newJObject()
  var query_607426 = newJObject()
  add(path_607425, "application-id", newJString(applicationId))
  add(query_607426, "page-size", newJString(pageSize))
  add(path_607425, "campaign-id", newJString(campaignId))
  add(query_607426, "token", newJString(token))
  result = call_607424.call(path_607425, query_607426, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_607409(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_607410, base: "/",
    url: url_GetCampaignActivities_607411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_607427 = ref object of OpenApiRestCall_605573
proc url_GetCampaignDateRangeKpi_607429(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_607428(path: JsonNode; query: JsonNode;
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
  var valid_607430 = path.getOrDefault("kpi-name")
  valid_607430 = validateParameter(valid_607430, JString, required = true,
                                 default = nil)
  if valid_607430 != nil:
    section.add "kpi-name", valid_607430
  var valid_607431 = path.getOrDefault("application-id")
  valid_607431 = validateParameter(valid_607431, JString, required = true,
                                 default = nil)
  if valid_607431 != nil:
    section.add "application-id", valid_607431
  var valid_607432 = path.getOrDefault("campaign-id")
  valid_607432 = validateParameter(valid_607432, JString, required = true,
                                 default = nil)
  if valid_607432 != nil:
    section.add "campaign-id", valid_607432
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
  var valid_607433 = query.getOrDefault("end-time")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "end-time", valid_607433
  var valid_607434 = query.getOrDefault("page-size")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "page-size", valid_607434
  var valid_607435 = query.getOrDefault("start-time")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "start-time", valid_607435
  var valid_607436 = query.getOrDefault("next-token")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "next-token", valid_607436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607437 = header.getOrDefault("X-Amz-Signature")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Signature", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Content-Sha256", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Date")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Date", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Credential")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Credential", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Security-Token")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Security-Token", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Algorithm")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Algorithm", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-SignedHeaders", valid_607443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607444: Call_GetCampaignDateRangeKpi_607427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_607444.validator(path, query, header, formData, body)
  let scheme = call_607444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607444.url(scheme.get, call_607444.host, call_607444.base,
                         call_607444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607444, url, valid)

proc call*(call_607445: Call_GetCampaignDateRangeKpi_607427; kpiName: string;
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
  var path_607446 = newJObject()
  var query_607447 = newJObject()
  add(path_607446, "kpi-name", newJString(kpiName))
  add(path_607446, "application-id", newJString(applicationId))
  add(query_607447, "end-time", newJString(endTime))
  add(query_607447, "page-size", newJString(pageSize))
  add(path_607446, "campaign-id", newJString(campaignId))
  add(query_607447, "start-time", newJString(startTime))
  add(query_607447, "next-token", newJString(nextToken))
  result = call_607445.call(path_607446, query_607447, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_607427(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_607428, base: "/",
    url: url_GetCampaignDateRangeKpi_607429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_607448 = ref object of OpenApiRestCall_605573
proc url_GetCampaignVersion_607450(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_607449(path: JsonNode; query: JsonNode;
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
  var valid_607451 = path.getOrDefault("version")
  valid_607451 = validateParameter(valid_607451, JString, required = true,
                                 default = nil)
  if valid_607451 != nil:
    section.add "version", valid_607451
  var valid_607452 = path.getOrDefault("application-id")
  valid_607452 = validateParameter(valid_607452, JString, required = true,
                                 default = nil)
  if valid_607452 != nil:
    section.add "application-id", valid_607452
  var valid_607453 = path.getOrDefault("campaign-id")
  valid_607453 = validateParameter(valid_607453, JString, required = true,
                                 default = nil)
  if valid_607453 != nil:
    section.add "campaign-id", valid_607453
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
  var valid_607454 = header.getOrDefault("X-Amz-Signature")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-Signature", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Content-Sha256", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Date")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Date", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Credential")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Credential", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Security-Token")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Security-Token", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-Algorithm")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-Algorithm", valid_607459
  var valid_607460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-SignedHeaders", valid_607460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607461: Call_GetCampaignVersion_607448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_607461.validator(path, query, header, formData, body)
  let scheme = call_607461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607461.url(scheme.get, call_607461.host, call_607461.base,
                         call_607461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607461, url, valid)

proc call*(call_607462: Call_GetCampaignVersion_607448; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_607463 = newJObject()
  add(path_607463, "version", newJString(version))
  add(path_607463, "application-id", newJString(applicationId))
  add(path_607463, "campaign-id", newJString(campaignId))
  result = call_607462.call(path_607463, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_607448(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_607449, base: "/",
    url: url_GetCampaignVersion_607450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_607464 = ref object of OpenApiRestCall_605573
proc url_GetCampaignVersions_607466(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_607465(path: JsonNode; query: JsonNode;
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
  var valid_607467 = path.getOrDefault("application-id")
  valid_607467 = validateParameter(valid_607467, JString, required = true,
                                 default = nil)
  if valid_607467 != nil:
    section.add "application-id", valid_607467
  var valid_607468 = path.getOrDefault("campaign-id")
  valid_607468 = validateParameter(valid_607468, JString, required = true,
                                 default = nil)
  if valid_607468 != nil:
    section.add "campaign-id", valid_607468
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_607469 = query.getOrDefault("page-size")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "page-size", valid_607469
  var valid_607470 = query.getOrDefault("token")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "token", valid_607470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607471 = header.getOrDefault("X-Amz-Signature")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Signature", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Content-Sha256", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Date")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Date", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Credential")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Credential", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Security-Token")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Security-Token", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-Algorithm")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Algorithm", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-SignedHeaders", valid_607477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607478: Call_GetCampaignVersions_607464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_607478.validator(path, query, header, formData, body)
  let scheme = call_607478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607478.url(scheme.get, call_607478.host, call_607478.base,
                         call_607478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607478, url, valid)

proc call*(call_607479: Call_GetCampaignVersions_607464; applicationId: string;
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
  var path_607480 = newJObject()
  var query_607481 = newJObject()
  add(path_607480, "application-id", newJString(applicationId))
  add(query_607481, "page-size", newJString(pageSize))
  add(path_607480, "campaign-id", newJString(campaignId))
  add(query_607481, "token", newJString(token))
  result = call_607479.call(path_607480, query_607481, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_607464(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_607465, base: "/",
    url: url_GetCampaignVersions_607466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_607482 = ref object of OpenApiRestCall_605573
proc url_GetChannels_607484(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_607483(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607485 = path.getOrDefault("application-id")
  valid_607485 = validateParameter(valid_607485, JString, required = true,
                                 default = nil)
  if valid_607485 != nil:
    section.add "application-id", valid_607485
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
  var valid_607486 = header.getOrDefault("X-Amz-Signature")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Signature", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Content-Sha256", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Date")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Date", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Credential")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Credential", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Security-Token")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Security-Token", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-Algorithm")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-Algorithm", valid_607491
  var valid_607492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-SignedHeaders", valid_607492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607493: Call_GetChannels_607482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_607493.validator(path, query, header, formData, body)
  let scheme = call_607493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607493.url(scheme.get, call_607493.host, call_607493.base,
                         call_607493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607493, url, valid)

proc call*(call_607494: Call_GetChannels_607482; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607495 = newJObject()
  add(path_607495, "application-id", newJString(applicationId))
  result = call_607494.call(path_607495, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_607482(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_607483,
                                        base: "/", url: url_GetChannels_607484,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_607496 = ref object of OpenApiRestCall_605573
proc url_GetExportJob_607498(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_607497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607499 = path.getOrDefault("job-id")
  valid_607499 = validateParameter(valid_607499, JString, required = true,
                                 default = nil)
  if valid_607499 != nil:
    section.add "job-id", valid_607499
  var valid_607500 = path.getOrDefault("application-id")
  valid_607500 = validateParameter(valid_607500, JString, required = true,
                                 default = nil)
  if valid_607500 != nil:
    section.add "application-id", valid_607500
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
  var valid_607501 = header.getOrDefault("X-Amz-Signature")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Signature", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Content-Sha256", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Date")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Date", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Credential")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Credential", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Security-Token")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Security-Token", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-Algorithm")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-Algorithm", valid_607506
  var valid_607507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "X-Amz-SignedHeaders", valid_607507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607508: Call_GetExportJob_607496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_607508.validator(path, query, header, formData, body)
  let scheme = call_607508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607508.url(scheme.get, call_607508.host, call_607508.base,
                         call_607508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607508, url, valid)

proc call*(call_607509: Call_GetExportJob_607496; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607510 = newJObject()
  add(path_607510, "job-id", newJString(jobId))
  add(path_607510, "application-id", newJString(applicationId))
  result = call_607509.call(path_607510, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_607496(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_607497, base: "/", url: url_GetExportJob_607498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_607511 = ref object of OpenApiRestCall_605573
proc url_GetImportJob_607513(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_607512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607514 = path.getOrDefault("job-id")
  valid_607514 = validateParameter(valid_607514, JString, required = true,
                                 default = nil)
  if valid_607514 != nil:
    section.add "job-id", valid_607514
  var valid_607515 = path.getOrDefault("application-id")
  valid_607515 = validateParameter(valid_607515, JString, required = true,
                                 default = nil)
  if valid_607515 != nil:
    section.add "application-id", valid_607515
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
  var valid_607516 = header.getOrDefault("X-Amz-Signature")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Signature", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Content-Sha256", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Date")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Date", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Credential")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Credential", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Security-Token")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Security-Token", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-Algorithm")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-Algorithm", valid_607521
  var valid_607522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-SignedHeaders", valid_607522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607523: Call_GetImportJob_607511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_607523.validator(path, query, header, formData, body)
  let scheme = call_607523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607523.url(scheme.get, call_607523.host, call_607523.base,
                         call_607523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607523, url, valid)

proc call*(call_607524: Call_GetImportJob_607511; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_607525 = newJObject()
  add(path_607525, "job-id", newJString(jobId))
  add(path_607525, "application-id", newJString(applicationId))
  result = call_607524.call(path_607525, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_607511(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_607512, base: "/", url: url_GetImportJob_607513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_607526 = ref object of OpenApiRestCall_605573
proc url_GetJourneyDateRangeKpi_607528(protocol: Scheme; host: string; base: string;
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

proc validate_GetJourneyDateRangeKpi_607527(path: JsonNode; query: JsonNode;
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
  var valid_607529 = path.getOrDefault("kpi-name")
  valid_607529 = validateParameter(valid_607529, JString, required = true,
                                 default = nil)
  if valid_607529 != nil:
    section.add "kpi-name", valid_607529
  var valid_607530 = path.getOrDefault("application-id")
  valid_607530 = validateParameter(valid_607530, JString, required = true,
                                 default = nil)
  if valid_607530 != nil:
    section.add "application-id", valid_607530
  var valid_607531 = path.getOrDefault("journey-id")
  valid_607531 = validateParameter(valid_607531, JString, required = true,
                                 default = nil)
  if valid_607531 != nil:
    section.add "journey-id", valid_607531
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
  var valid_607532 = query.getOrDefault("end-time")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "end-time", valid_607532
  var valid_607533 = query.getOrDefault("page-size")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "page-size", valid_607533
  var valid_607534 = query.getOrDefault("start-time")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "start-time", valid_607534
  var valid_607535 = query.getOrDefault("next-token")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "next-token", valid_607535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607536 = header.getOrDefault("X-Amz-Signature")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Signature", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Content-Sha256", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-Date")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Date", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-Credential")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-Credential", valid_607539
  var valid_607540 = header.getOrDefault("X-Amz-Security-Token")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "X-Amz-Security-Token", valid_607540
  var valid_607541 = header.getOrDefault("X-Amz-Algorithm")
  valid_607541 = validateParameter(valid_607541, JString, required = false,
                                 default = nil)
  if valid_607541 != nil:
    section.add "X-Amz-Algorithm", valid_607541
  var valid_607542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607542 = validateParameter(valid_607542, JString, required = false,
                                 default = nil)
  if valid_607542 != nil:
    section.add "X-Amz-SignedHeaders", valid_607542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607543: Call_GetJourneyDateRangeKpi_607526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_607543.validator(path, query, header, formData, body)
  let scheme = call_607543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607543.url(scheme.get, call_607543.host, call_607543.base,
                         call_607543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607543, url, valid)

proc call*(call_607544: Call_GetJourneyDateRangeKpi_607526; kpiName: string;
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
  var path_607545 = newJObject()
  var query_607546 = newJObject()
  add(path_607545, "kpi-name", newJString(kpiName))
  add(path_607545, "application-id", newJString(applicationId))
  add(query_607546, "end-time", newJString(endTime))
  add(query_607546, "page-size", newJString(pageSize))
  add(path_607545, "journey-id", newJString(journeyId))
  add(query_607546, "start-time", newJString(startTime))
  add(query_607546, "next-token", newJString(nextToken))
  result = call_607544.call(path_607545, query_607546, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_607526(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_607527, base: "/",
    url: url_GetJourneyDateRangeKpi_607528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_607547 = ref object of OpenApiRestCall_605573
proc url_GetJourneyExecutionActivityMetrics_607549(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionActivityMetrics_607548(path: JsonNode;
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
  var valid_607550 = path.getOrDefault("application-id")
  valid_607550 = validateParameter(valid_607550, JString, required = true,
                                 default = nil)
  if valid_607550 != nil:
    section.add "application-id", valid_607550
  var valid_607551 = path.getOrDefault("journey-activity-id")
  valid_607551 = validateParameter(valid_607551, JString, required = true,
                                 default = nil)
  if valid_607551 != nil:
    section.add "journey-activity-id", valid_607551
  var valid_607552 = path.getOrDefault("journey-id")
  valid_607552 = validateParameter(valid_607552, JString, required = true,
                                 default = nil)
  if valid_607552 != nil:
    section.add "journey-id", valid_607552
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_607553 = query.getOrDefault("page-size")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "page-size", valid_607553
  var valid_607554 = query.getOrDefault("next-token")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "next-token", valid_607554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607555 = header.getOrDefault("X-Amz-Signature")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-Signature", valid_607555
  var valid_607556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "X-Amz-Content-Sha256", valid_607556
  var valid_607557 = header.getOrDefault("X-Amz-Date")
  valid_607557 = validateParameter(valid_607557, JString, required = false,
                                 default = nil)
  if valid_607557 != nil:
    section.add "X-Amz-Date", valid_607557
  var valid_607558 = header.getOrDefault("X-Amz-Credential")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-Credential", valid_607558
  var valid_607559 = header.getOrDefault("X-Amz-Security-Token")
  valid_607559 = validateParameter(valid_607559, JString, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "X-Amz-Security-Token", valid_607559
  var valid_607560 = header.getOrDefault("X-Amz-Algorithm")
  valid_607560 = validateParameter(valid_607560, JString, required = false,
                                 default = nil)
  if valid_607560 != nil:
    section.add "X-Amz-Algorithm", valid_607560
  var valid_607561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-SignedHeaders", valid_607561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607562: Call_GetJourneyExecutionActivityMetrics_607547;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_607562.validator(path, query, header, formData, body)
  let scheme = call_607562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607562.url(scheme.get, call_607562.host, call_607562.base,
                         call_607562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607562, url, valid)

proc call*(call_607563: Call_GetJourneyExecutionActivityMetrics_607547;
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
  var path_607564 = newJObject()
  var query_607565 = newJObject()
  add(path_607564, "application-id", newJString(applicationId))
  add(query_607565, "page-size", newJString(pageSize))
  add(path_607564, "journey-activity-id", newJString(journeyActivityId))
  add(path_607564, "journey-id", newJString(journeyId))
  add(query_607565, "next-token", newJString(nextToken))
  result = call_607563.call(path_607564, query_607565, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_607547(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_607548, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_607549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_607566 = ref object of OpenApiRestCall_605573
proc url_GetJourneyExecutionMetrics_607568(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_607567(path: JsonNode; query: JsonNode;
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
  var valid_607569 = path.getOrDefault("application-id")
  valid_607569 = validateParameter(valid_607569, JString, required = true,
                                 default = nil)
  if valid_607569 != nil:
    section.add "application-id", valid_607569
  var valid_607570 = path.getOrDefault("journey-id")
  valid_607570 = validateParameter(valid_607570, JString, required = true,
                                 default = nil)
  if valid_607570 != nil:
    section.add "journey-id", valid_607570
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_607571 = query.getOrDefault("page-size")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "page-size", valid_607571
  var valid_607572 = query.getOrDefault("next-token")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "next-token", valid_607572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607573 = header.getOrDefault("X-Amz-Signature")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "X-Amz-Signature", valid_607573
  var valid_607574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = nil)
  if valid_607574 != nil:
    section.add "X-Amz-Content-Sha256", valid_607574
  var valid_607575 = header.getOrDefault("X-Amz-Date")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "X-Amz-Date", valid_607575
  var valid_607576 = header.getOrDefault("X-Amz-Credential")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-Credential", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Security-Token")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Security-Token", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Algorithm")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Algorithm", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-SignedHeaders", valid_607579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607580: Call_GetJourneyExecutionMetrics_607566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_607580.validator(path, query, header, formData, body)
  let scheme = call_607580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607580.url(scheme.get, call_607580.host, call_607580.base,
                         call_607580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607580, url, valid)

proc call*(call_607581: Call_GetJourneyExecutionMetrics_607566;
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
  var path_607582 = newJObject()
  var query_607583 = newJObject()
  add(path_607582, "application-id", newJString(applicationId))
  add(query_607583, "page-size", newJString(pageSize))
  add(path_607582, "journey-id", newJString(journeyId))
  add(query_607583, "next-token", newJString(nextToken))
  result = call_607581.call(path_607582, query_607583, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_607566(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_607567, base: "/",
    url: url_GetJourneyExecutionMetrics_607568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_607584 = ref object of OpenApiRestCall_605573
proc url_GetSegmentExportJobs_607586(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_607585(path: JsonNode; query: JsonNode;
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
  var valid_607587 = path.getOrDefault("application-id")
  valid_607587 = validateParameter(valid_607587, JString, required = true,
                                 default = nil)
  if valid_607587 != nil:
    section.add "application-id", valid_607587
  var valid_607588 = path.getOrDefault("segment-id")
  valid_607588 = validateParameter(valid_607588, JString, required = true,
                                 default = nil)
  if valid_607588 != nil:
    section.add "segment-id", valid_607588
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_607589 = query.getOrDefault("page-size")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "page-size", valid_607589
  var valid_607590 = query.getOrDefault("token")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "token", valid_607590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607591 = header.getOrDefault("X-Amz-Signature")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Signature", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Content-Sha256", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Date")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Date", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Credential")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Credential", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Security-Token")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Security-Token", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-Algorithm")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-Algorithm", valid_607596
  var valid_607597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "X-Amz-SignedHeaders", valid_607597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607598: Call_GetSegmentExportJobs_607584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_607598.validator(path, query, header, formData, body)
  let scheme = call_607598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607598.url(scheme.get, call_607598.host, call_607598.base,
                         call_607598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607598, url, valid)

proc call*(call_607599: Call_GetSegmentExportJobs_607584; applicationId: string;
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
  var path_607600 = newJObject()
  var query_607601 = newJObject()
  add(path_607600, "application-id", newJString(applicationId))
  add(path_607600, "segment-id", newJString(segmentId))
  add(query_607601, "page-size", newJString(pageSize))
  add(query_607601, "token", newJString(token))
  result = call_607599.call(path_607600, query_607601, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_607584(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_607585, base: "/",
    url: url_GetSegmentExportJobs_607586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_607602 = ref object of OpenApiRestCall_605573
proc url_GetSegmentImportJobs_607604(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_607603(path: JsonNode; query: JsonNode;
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
  var valid_607605 = path.getOrDefault("application-id")
  valid_607605 = validateParameter(valid_607605, JString, required = true,
                                 default = nil)
  if valid_607605 != nil:
    section.add "application-id", valid_607605
  var valid_607606 = path.getOrDefault("segment-id")
  valid_607606 = validateParameter(valid_607606, JString, required = true,
                                 default = nil)
  if valid_607606 != nil:
    section.add "segment-id", valid_607606
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_607607 = query.getOrDefault("page-size")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "page-size", valid_607607
  var valid_607608 = query.getOrDefault("token")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "token", valid_607608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607609 = header.getOrDefault("X-Amz-Signature")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Signature", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Content-Sha256", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-Date")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Date", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Credential")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Credential", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-Security-Token")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-Security-Token", valid_607613
  var valid_607614 = header.getOrDefault("X-Amz-Algorithm")
  valid_607614 = validateParameter(valid_607614, JString, required = false,
                                 default = nil)
  if valid_607614 != nil:
    section.add "X-Amz-Algorithm", valid_607614
  var valid_607615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607615 = validateParameter(valid_607615, JString, required = false,
                                 default = nil)
  if valid_607615 != nil:
    section.add "X-Amz-SignedHeaders", valid_607615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607616: Call_GetSegmentImportJobs_607602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_607616.validator(path, query, header, formData, body)
  let scheme = call_607616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607616.url(scheme.get, call_607616.host, call_607616.base,
                         call_607616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607616, url, valid)

proc call*(call_607617: Call_GetSegmentImportJobs_607602; applicationId: string;
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
  var path_607618 = newJObject()
  var query_607619 = newJObject()
  add(path_607618, "application-id", newJString(applicationId))
  add(path_607618, "segment-id", newJString(segmentId))
  add(query_607619, "page-size", newJString(pageSize))
  add(query_607619, "token", newJString(token))
  result = call_607617.call(path_607618, query_607619, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_607602(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_607603, base: "/",
    url: url_GetSegmentImportJobs_607604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_607620 = ref object of OpenApiRestCall_605573
proc url_GetSegmentVersion_607622(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_607621(path: JsonNode; query: JsonNode;
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
  var valid_607623 = path.getOrDefault("version")
  valid_607623 = validateParameter(valid_607623, JString, required = true,
                                 default = nil)
  if valid_607623 != nil:
    section.add "version", valid_607623
  var valid_607624 = path.getOrDefault("application-id")
  valid_607624 = validateParameter(valid_607624, JString, required = true,
                                 default = nil)
  if valid_607624 != nil:
    section.add "application-id", valid_607624
  var valid_607625 = path.getOrDefault("segment-id")
  valid_607625 = validateParameter(valid_607625, JString, required = true,
                                 default = nil)
  if valid_607625 != nil:
    section.add "segment-id", valid_607625
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
  var valid_607626 = header.getOrDefault("X-Amz-Signature")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Signature", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Content-Sha256", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Date")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Date", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-Credential")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-Credential", valid_607629
  var valid_607630 = header.getOrDefault("X-Amz-Security-Token")
  valid_607630 = validateParameter(valid_607630, JString, required = false,
                                 default = nil)
  if valid_607630 != nil:
    section.add "X-Amz-Security-Token", valid_607630
  var valid_607631 = header.getOrDefault("X-Amz-Algorithm")
  valid_607631 = validateParameter(valid_607631, JString, required = false,
                                 default = nil)
  if valid_607631 != nil:
    section.add "X-Amz-Algorithm", valid_607631
  var valid_607632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "X-Amz-SignedHeaders", valid_607632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607633: Call_GetSegmentVersion_607620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_607633.validator(path, query, header, formData, body)
  let scheme = call_607633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607633.url(scheme.get, call_607633.host, call_607633.base,
                         call_607633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607633, url, valid)

proc call*(call_607634: Call_GetSegmentVersion_607620; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_607635 = newJObject()
  add(path_607635, "version", newJString(version))
  add(path_607635, "application-id", newJString(applicationId))
  add(path_607635, "segment-id", newJString(segmentId))
  result = call_607634.call(path_607635, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_607620(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_607621, base: "/",
    url: url_GetSegmentVersion_607622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_607636 = ref object of OpenApiRestCall_605573
proc url_GetSegmentVersions_607638(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_607637(path: JsonNode; query: JsonNode;
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
  var valid_607639 = path.getOrDefault("application-id")
  valid_607639 = validateParameter(valid_607639, JString, required = true,
                                 default = nil)
  if valid_607639 != nil:
    section.add "application-id", valid_607639
  var valid_607640 = path.getOrDefault("segment-id")
  valid_607640 = validateParameter(valid_607640, JString, required = true,
                                 default = nil)
  if valid_607640 != nil:
    section.add "segment-id", valid_607640
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_607641 = query.getOrDefault("page-size")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "page-size", valid_607641
  var valid_607642 = query.getOrDefault("token")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "token", valid_607642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607643 = header.getOrDefault("X-Amz-Signature")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-Signature", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-Content-Sha256", valid_607644
  var valid_607645 = header.getOrDefault("X-Amz-Date")
  valid_607645 = validateParameter(valid_607645, JString, required = false,
                                 default = nil)
  if valid_607645 != nil:
    section.add "X-Amz-Date", valid_607645
  var valid_607646 = header.getOrDefault("X-Amz-Credential")
  valid_607646 = validateParameter(valid_607646, JString, required = false,
                                 default = nil)
  if valid_607646 != nil:
    section.add "X-Amz-Credential", valid_607646
  var valid_607647 = header.getOrDefault("X-Amz-Security-Token")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Security-Token", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-Algorithm")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-Algorithm", valid_607648
  var valid_607649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "X-Amz-SignedHeaders", valid_607649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607650: Call_GetSegmentVersions_607636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_607650.validator(path, query, header, formData, body)
  let scheme = call_607650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607650.url(scheme.get, call_607650.host, call_607650.base,
                         call_607650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607650, url, valid)

proc call*(call_607651: Call_GetSegmentVersions_607636; applicationId: string;
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
  var path_607652 = newJObject()
  var query_607653 = newJObject()
  add(path_607652, "application-id", newJString(applicationId))
  add(path_607652, "segment-id", newJString(segmentId))
  add(query_607653, "page-size", newJString(pageSize))
  add(query_607653, "token", newJString(token))
  result = call_607651.call(path_607652, query_607653, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_607636(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_607637, base: "/",
    url: url_GetSegmentVersions_607638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607668 = ref object of OpenApiRestCall_605573
proc url_TagResource_607670(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607669(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607671 = path.getOrDefault("resource-arn")
  valid_607671 = validateParameter(valid_607671, JString, required = true,
                                 default = nil)
  if valid_607671 != nil:
    section.add "resource-arn", valid_607671
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
  var valid_607672 = header.getOrDefault("X-Amz-Signature")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "X-Amz-Signature", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-Content-Sha256", valid_607673
  var valid_607674 = header.getOrDefault("X-Amz-Date")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-Date", valid_607674
  var valid_607675 = header.getOrDefault("X-Amz-Credential")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Credential", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Security-Token")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Security-Token", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-Algorithm")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-Algorithm", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-SignedHeaders", valid_607678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607680: Call_TagResource_607668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_607680.validator(path, query, header, formData, body)
  let scheme = call_607680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607680.url(scheme.get, call_607680.host, call_607680.base,
                         call_607680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607680, url, valid)

proc call*(call_607681: Call_TagResource_607668; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_607682 = newJObject()
  var body_607683 = newJObject()
  add(path_607682, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_607683 = body
  result = call_607681.call(path_607682, nil, nil, nil, body_607683)

var tagResource* = Call_TagResource_607668(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_607669,
                                        base: "/", url: url_TagResource_607670,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607654 = ref object of OpenApiRestCall_605573
proc url_ListTagsForResource_607656(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_607655(path: JsonNode; query: JsonNode;
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
  var valid_607657 = path.getOrDefault("resource-arn")
  valid_607657 = validateParameter(valid_607657, JString, required = true,
                                 default = nil)
  if valid_607657 != nil:
    section.add "resource-arn", valid_607657
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
  var valid_607658 = header.getOrDefault("X-Amz-Signature")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-Signature", valid_607658
  var valid_607659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Content-Sha256", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Date")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Date", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-Credential")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-Credential", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Security-Token")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Security-Token", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Algorithm")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Algorithm", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-SignedHeaders", valid_607664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607665: Call_ListTagsForResource_607654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_607665.validator(path, query, header, formData, body)
  let scheme = call_607665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607665.url(scheme.get, call_607665.host, call_607665.base,
                         call_607665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607665, url, valid)

proc call*(call_607666: Call_ListTagsForResource_607654; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_607667 = newJObject()
  add(path_607667, "resource-arn", newJString(resourceArn))
  result = call_607666.call(path_607667, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_607654(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_607655, base: "/",
    url: url_ListTagsForResource_607656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_607684 = ref object of OpenApiRestCall_605573
proc url_ListTemplateVersions_607686(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_607685(path: JsonNode; query: JsonNode;
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
  var valid_607687 = path.getOrDefault("template-type")
  valid_607687 = validateParameter(valid_607687, JString, required = true,
                                 default = nil)
  if valid_607687 != nil:
    section.add "template-type", valid_607687
  var valid_607688 = path.getOrDefault("template-name")
  valid_607688 = validateParameter(valid_607688, JString, required = true,
                                 default = nil)
  if valid_607688 != nil:
    section.add "template-name", valid_607688
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_607689 = query.getOrDefault("page-size")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "page-size", valid_607689
  var valid_607690 = query.getOrDefault("next-token")
  valid_607690 = validateParameter(valid_607690, JString, required = false,
                                 default = nil)
  if valid_607690 != nil:
    section.add "next-token", valid_607690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607691 = header.getOrDefault("X-Amz-Signature")
  valid_607691 = validateParameter(valid_607691, JString, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "X-Amz-Signature", valid_607691
  var valid_607692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "X-Amz-Content-Sha256", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-Date")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-Date", valid_607693
  var valid_607694 = header.getOrDefault("X-Amz-Credential")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "X-Amz-Credential", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Security-Token")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Security-Token", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Algorithm")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Algorithm", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-SignedHeaders", valid_607697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607698: Call_ListTemplateVersions_607684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_607698.validator(path, query, header, formData, body)
  let scheme = call_607698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607698.url(scheme.get, call_607698.host, call_607698.base,
                         call_607698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607698, url, valid)

proc call*(call_607699: Call_ListTemplateVersions_607684; templateType: string;
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
  var path_607700 = newJObject()
  var query_607701 = newJObject()
  add(path_607700, "template-type", newJString(templateType))
  add(path_607700, "template-name", newJString(templateName))
  add(query_607701, "page-size", newJString(pageSize))
  add(query_607701, "next-token", newJString(nextToken))
  result = call_607699.call(path_607700, query_607701, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_607684(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_607685, base: "/",
    url: url_ListTemplateVersions_607686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_607702 = ref object of OpenApiRestCall_605573
proc url_ListTemplates_607704(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_607703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607705 = query.getOrDefault("prefix")
  valid_607705 = validateParameter(valid_607705, JString, required = false,
                                 default = nil)
  if valid_607705 != nil:
    section.add "prefix", valid_607705
  var valid_607706 = query.getOrDefault("page-size")
  valid_607706 = validateParameter(valid_607706, JString, required = false,
                                 default = nil)
  if valid_607706 != nil:
    section.add "page-size", valid_607706
  var valid_607707 = query.getOrDefault("template-type")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "template-type", valid_607707
  var valid_607708 = query.getOrDefault("next-token")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "next-token", valid_607708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607709 = header.getOrDefault("X-Amz-Signature")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Signature", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Content-Sha256", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Date")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Date", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Credential")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Credential", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Security-Token")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Security-Token", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Algorithm")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Algorithm", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-SignedHeaders", valid_607715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607716: Call_ListTemplates_607702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_607716.validator(path, query, header, formData, body)
  let scheme = call_607716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607716.url(scheme.get, call_607716.host, call_607716.base,
                         call_607716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607716, url, valid)

proc call*(call_607717: Call_ListTemplates_607702; prefix: string = "";
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
  var query_607718 = newJObject()
  add(query_607718, "prefix", newJString(prefix))
  add(query_607718, "page-size", newJString(pageSize))
  add(query_607718, "template-type", newJString(templateType))
  add(query_607718, "next-token", newJString(nextToken))
  result = call_607717.call(nil, query_607718, nil, nil, nil)

var listTemplates* = Call_ListTemplates_607702(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_607703, base: "/",
    url: url_ListTemplates_607704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_607719 = ref object of OpenApiRestCall_605573
proc url_PhoneNumberValidate_607721(protocol: Scheme; host: string; base: string;
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

proc validate_PhoneNumberValidate_607720(path: JsonNode; query: JsonNode;
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
  var valid_607722 = header.getOrDefault("X-Amz-Signature")
  valid_607722 = validateParameter(valid_607722, JString, required = false,
                                 default = nil)
  if valid_607722 != nil:
    section.add "X-Amz-Signature", valid_607722
  var valid_607723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "X-Amz-Content-Sha256", valid_607723
  var valid_607724 = header.getOrDefault("X-Amz-Date")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "X-Amz-Date", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-Credential")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-Credential", valid_607725
  var valid_607726 = header.getOrDefault("X-Amz-Security-Token")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-Security-Token", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Algorithm")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Algorithm", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-SignedHeaders", valid_607728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607730: Call_PhoneNumberValidate_607719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_607730.validator(path, query, header, formData, body)
  let scheme = call_607730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607730.url(scheme.get, call_607730.host, call_607730.base,
                         call_607730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607730, url, valid)

proc call*(call_607731: Call_PhoneNumberValidate_607719; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_607732 = newJObject()
  if body != nil:
    body_607732 = body
  result = call_607731.call(nil, nil, nil, nil, body_607732)

var phoneNumberValidate* = Call_PhoneNumberValidate_607719(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_607720, base: "/",
    url: url_PhoneNumberValidate_607721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_607733 = ref object of OpenApiRestCall_605573
proc url_PutEvents_607735(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_607734(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607736 = path.getOrDefault("application-id")
  valid_607736 = validateParameter(valid_607736, JString, required = true,
                                 default = nil)
  if valid_607736 != nil:
    section.add "application-id", valid_607736
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
  var valid_607737 = header.getOrDefault("X-Amz-Signature")
  valid_607737 = validateParameter(valid_607737, JString, required = false,
                                 default = nil)
  if valid_607737 != nil:
    section.add "X-Amz-Signature", valid_607737
  var valid_607738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607738 = validateParameter(valid_607738, JString, required = false,
                                 default = nil)
  if valid_607738 != nil:
    section.add "X-Amz-Content-Sha256", valid_607738
  var valid_607739 = header.getOrDefault("X-Amz-Date")
  valid_607739 = validateParameter(valid_607739, JString, required = false,
                                 default = nil)
  if valid_607739 != nil:
    section.add "X-Amz-Date", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Credential")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Credential", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Security-Token")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Security-Token", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Algorithm")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Algorithm", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-SignedHeaders", valid_607743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607745: Call_PutEvents_607733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_607745.validator(path, query, header, formData, body)
  let scheme = call_607745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607745.url(scheme.get, call_607745.host, call_607745.base,
                         call_607745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607745, url, valid)

proc call*(call_607746: Call_PutEvents_607733; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607747 = newJObject()
  var body_607748 = newJObject()
  add(path_607747, "application-id", newJString(applicationId))
  if body != nil:
    body_607748 = body
  result = call_607746.call(path_607747, nil, nil, nil, body_607748)

var putEvents* = Call_PutEvents_607733(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_607734,
                                    base: "/", url: url_PutEvents_607735,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_607749 = ref object of OpenApiRestCall_605573
proc url_RemoveAttributes_607751(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_607750(path: JsonNode; query: JsonNode;
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
  var valid_607752 = path.getOrDefault("attribute-type")
  valid_607752 = validateParameter(valid_607752, JString, required = true,
                                 default = nil)
  if valid_607752 != nil:
    section.add "attribute-type", valid_607752
  var valid_607753 = path.getOrDefault("application-id")
  valid_607753 = validateParameter(valid_607753, JString, required = true,
                                 default = nil)
  if valid_607753 != nil:
    section.add "application-id", valid_607753
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
  var valid_607754 = header.getOrDefault("X-Amz-Signature")
  valid_607754 = validateParameter(valid_607754, JString, required = false,
                                 default = nil)
  if valid_607754 != nil:
    section.add "X-Amz-Signature", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Content-Sha256", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Date")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Date", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Credential")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Credential", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Security-Token")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Security-Token", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Algorithm")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Algorithm", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-SignedHeaders", valid_607760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607762: Call_RemoveAttributes_607749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_607762.validator(path, query, header, formData, body)
  let scheme = call_607762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607762.url(scheme.get, call_607762.host, call_607762.base,
                         call_607762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607762, url, valid)

proc call*(call_607763: Call_RemoveAttributes_607749; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607764 = newJObject()
  var body_607765 = newJObject()
  add(path_607764, "attribute-type", newJString(attributeType))
  add(path_607764, "application-id", newJString(applicationId))
  if body != nil:
    body_607765 = body
  result = call_607763.call(path_607764, nil, nil, nil, body_607765)

var removeAttributes* = Call_RemoveAttributes_607749(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_607750, base: "/",
    url: url_RemoveAttributes_607751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_607766 = ref object of OpenApiRestCall_605573
proc url_SendMessages_607768(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_607767(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607769 = path.getOrDefault("application-id")
  valid_607769 = validateParameter(valid_607769, JString, required = true,
                                 default = nil)
  if valid_607769 != nil:
    section.add "application-id", valid_607769
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
  var valid_607770 = header.getOrDefault("X-Amz-Signature")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "X-Amz-Signature", valid_607770
  var valid_607771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Content-Sha256", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Date")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Date", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Credential")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Credential", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-Security-Token")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Security-Token", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Algorithm")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Algorithm", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-SignedHeaders", valid_607776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607778: Call_SendMessages_607766; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_607778.validator(path, query, header, formData, body)
  let scheme = call_607778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607778.url(scheme.get, call_607778.host, call_607778.base,
                         call_607778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607778, url, valid)

proc call*(call_607779: Call_SendMessages_607766; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607780 = newJObject()
  var body_607781 = newJObject()
  add(path_607780, "application-id", newJString(applicationId))
  if body != nil:
    body_607781 = body
  result = call_607779.call(path_607780, nil, nil, nil, body_607781)

var sendMessages* = Call_SendMessages_607766(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_607767,
    base: "/", url: url_SendMessages_607768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_607782 = ref object of OpenApiRestCall_605573
proc url_SendUsersMessages_607784(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_607783(path: JsonNode; query: JsonNode;
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
  var valid_607785 = path.getOrDefault("application-id")
  valid_607785 = validateParameter(valid_607785, JString, required = true,
                                 default = nil)
  if valid_607785 != nil:
    section.add "application-id", valid_607785
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
  var valid_607786 = header.getOrDefault("X-Amz-Signature")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Signature", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Content-Sha256", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Date")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Date", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-Credential")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Credential", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Security-Token")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Security-Token", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-Algorithm")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-Algorithm", valid_607791
  var valid_607792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607792 = validateParameter(valid_607792, JString, required = false,
                                 default = nil)
  if valid_607792 != nil:
    section.add "X-Amz-SignedHeaders", valid_607792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607794: Call_SendUsersMessages_607782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_607794.validator(path, query, header, formData, body)
  let scheme = call_607794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607794.url(scheme.get, call_607794.host, call_607794.base,
                         call_607794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607794, url, valid)

proc call*(call_607795: Call_SendUsersMessages_607782; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607796 = newJObject()
  var body_607797 = newJObject()
  add(path_607796, "application-id", newJString(applicationId))
  if body != nil:
    body_607797 = body
  result = call_607795.call(path_607796, nil, nil, nil, body_607797)

var sendUsersMessages* = Call_SendUsersMessages_607782(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_607783, base: "/",
    url: url_SendUsersMessages_607784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607798 = ref object of OpenApiRestCall_605573
proc url_UntagResource_607800(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607801 = path.getOrDefault("resource-arn")
  valid_607801 = validateParameter(valid_607801, JString, required = true,
                                 default = nil)
  if valid_607801 != nil:
    section.add "resource-arn", valid_607801
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_607802 = query.getOrDefault("tagKeys")
  valid_607802 = validateParameter(valid_607802, JArray, required = true, default = nil)
  if valid_607802 != nil:
    section.add "tagKeys", valid_607802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607803 = header.getOrDefault("X-Amz-Signature")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Signature", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Content-Sha256", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Date")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Date", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-Credential")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-Credential", valid_607806
  var valid_607807 = header.getOrDefault("X-Amz-Security-Token")
  valid_607807 = validateParameter(valid_607807, JString, required = false,
                                 default = nil)
  if valid_607807 != nil:
    section.add "X-Amz-Security-Token", valid_607807
  var valid_607808 = header.getOrDefault("X-Amz-Algorithm")
  valid_607808 = validateParameter(valid_607808, JString, required = false,
                                 default = nil)
  if valid_607808 != nil:
    section.add "X-Amz-Algorithm", valid_607808
  var valid_607809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "X-Amz-SignedHeaders", valid_607809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607810: Call_UntagResource_607798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_607810.validator(path, query, header, formData, body)
  let scheme = call_607810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607810.url(scheme.get, call_607810.host, call_607810.base,
                         call_607810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607810, url, valid)

proc call*(call_607811: Call_UntagResource_607798; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_607812 = newJObject()
  var query_607813 = newJObject()
  add(path_607812, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_607813.add "tagKeys", tagKeys
  result = call_607811.call(path_607812, query_607813, nil, nil, nil)

var untagResource* = Call_UntagResource_607798(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_607799,
    base: "/", url: url_UntagResource_607800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_607814 = ref object of OpenApiRestCall_605573
proc url_UpdateEndpointsBatch_607816(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_607815(path: JsonNode; query: JsonNode;
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
  var valid_607817 = path.getOrDefault("application-id")
  valid_607817 = validateParameter(valid_607817, JString, required = true,
                                 default = nil)
  if valid_607817 != nil:
    section.add "application-id", valid_607817
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
  var valid_607818 = header.getOrDefault("X-Amz-Signature")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Signature", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Content-Sha256", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Date")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Date", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-Credential")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-Credential", valid_607821
  var valid_607822 = header.getOrDefault("X-Amz-Security-Token")
  valid_607822 = validateParameter(valid_607822, JString, required = false,
                                 default = nil)
  if valid_607822 != nil:
    section.add "X-Amz-Security-Token", valid_607822
  var valid_607823 = header.getOrDefault("X-Amz-Algorithm")
  valid_607823 = validateParameter(valid_607823, JString, required = false,
                                 default = nil)
  if valid_607823 != nil:
    section.add "X-Amz-Algorithm", valid_607823
  var valid_607824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607824 = validateParameter(valid_607824, JString, required = false,
                                 default = nil)
  if valid_607824 != nil:
    section.add "X-Amz-SignedHeaders", valid_607824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607826: Call_UpdateEndpointsBatch_607814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_607826.validator(path, query, header, formData, body)
  let scheme = call_607826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607826.url(scheme.get, call_607826.host, call_607826.base,
                         call_607826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607826, url, valid)

proc call*(call_607827: Call_UpdateEndpointsBatch_607814; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_607828 = newJObject()
  var body_607829 = newJObject()
  add(path_607828, "application-id", newJString(applicationId))
  if body != nil:
    body_607829 = body
  result = call_607827.call(path_607828, nil, nil, nil, body_607829)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_607814(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_607815, base: "/",
    url: url_UpdateEndpointsBatch_607816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_607830 = ref object of OpenApiRestCall_605573
proc url_UpdateJourneyState_607832(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_607831(path: JsonNode; query: JsonNode;
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
  var valid_607833 = path.getOrDefault("application-id")
  valid_607833 = validateParameter(valid_607833, JString, required = true,
                                 default = nil)
  if valid_607833 != nil:
    section.add "application-id", valid_607833
  var valid_607834 = path.getOrDefault("journey-id")
  valid_607834 = validateParameter(valid_607834, JString, required = true,
                                 default = nil)
  if valid_607834 != nil:
    section.add "journey-id", valid_607834
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
  var valid_607835 = header.getOrDefault("X-Amz-Signature")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Signature", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Content-Sha256", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Date")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Date", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-Credential")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-Credential", valid_607838
  var valid_607839 = header.getOrDefault("X-Amz-Security-Token")
  valid_607839 = validateParameter(valid_607839, JString, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "X-Amz-Security-Token", valid_607839
  var valid_607840 = header.getOrDefault("X-Amz-Algorithm")
  valid_607840 = validateParameter(valid_607840, JString, required = false,
                                 default = nil)
  if valid_607840 != nil:
    section.add "X-Amz-Algorithm", valid_607840
  var valid_607841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607841 = validateParameter(valid_607841, JString, required = false,
                                 default = nil)
  if valid_607841 != nil:
    section.add "X-Amz-SignedHeaders", valid_607841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607843: Call_UpdateJourneyState_607830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_607843.validator(path, query, header, formData, body)
  let scheme = call_607843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607843.url(scheme.get, call_607843.host, call_607843.base,
                         call_607843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607843, url, valid)

proc call*(call_607844: Call_UpdateJourneyState_607830; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_607845 = newJObject()
  var body_607846 = newJObject()
  add(path_607845, "application-id", newJString(applicationId))
  if body != nil:
    body_607846 = body
  add(path_607845, "journey-id", newJString(journeyId))
  result = call_607844.call(path_607845, nil, nil, nil, body_607846)

var updateJourneyState* = Call_UpdateJourneyState_607830(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_607831, base: "/",
    url: url_UpdateJourneyState_607832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_607847 = ref object of OpenApiRestCall_605573
proc url_UpdateTemplateActiveVersion_607849(protocol: Scheme; host: string;
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

proc validate_UpdateTemplateActiveVersion_607848(path: JsonNode; query: JsonNode;
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
  var valid_607850 = path.getOrDefault("template-type")
  valid_607850 = validateParameter(valid_607850, JString, required = true,
                                 default = nil)
  if valid_607850 != nil:
    section.add "template-type", valid_607850
  var valid_607851 = path.getOrDefault("template-name")
  valid_607851 = validateParameter(valid_607851, JString, required = true,
                                 default = nil)
  if valid_607851 != nil:
    section.add "template-name", valid_607851
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
  var valid_607852 = header.getOrDefault("X-Amz-Signature")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-Signature", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Content-Sha256", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Date")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Date", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-Credential")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-Credential", valid_607855
  var valid_607856 = header.getOrDefault("X-Amz-Security-Token")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "X-Amz-Security-Token", valid_607856
  var valid_607857 = header.getOrDefault("X-Amz-Algorithm")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "X-Amz-Algorithm", valid_607857
  var valid_607858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607858 = validateParameter(valid_607858, JString, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "X-Amz-SignedHeaders", valid_607858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607860: Call_UpdateTemplateActiveVersion_607847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_607860.validator(path, query, header, formData, body)
  let scheme = call_607860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607860.url(scheme.get, call_607860.host, call_607860.base,
                         call_607860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607860, url, valid)

proc call*(call_607861: Call_UpdateTemplateActiveVersion_607847;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_607862 = newJObject()
  var body_607863 = newJObject()
  add(path_607862, "template-type", newJString(templateType))
  add(path_607862, "template-name", newJString(templateName))
  if body != nil:
    body_607863 = body
  result = call_607861.call(path_607862, nil, nil, nil, body_607863)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_607847(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_607848, base: "/",
    url: url_UpdateTemplateActiveVersion_607849,
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
