
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_603044 = ref object of OpenApiRestCall_602450
proc url_CreateApp_603046(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_603045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603047 = header.getOrDefault("X-Amz-Date")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Date", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Security-Token")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Security-Token", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Content-Sha256", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Algorithm")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Algorithm", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Signature")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Signature", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-SignedHeaders", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603055: Call_CreateApp_603044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_603055.validator(path, query, header, formData, body)
  let scheme = call_603055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603055.url(scheme.get, call_603055.host, call_603055.base,
                         call_603055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603055, url, valid)

proc call*(call_603056: Call_CreateApp_603044; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_603057 = newJObject()
  if body != nil:
    body_603057 = body
  result = call_603056.call(nil, nil, nil, nil, body_603057)

var createApp* = Call_CreateApp_603044(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_603045,
                                    base: "/", url: url_CreateApp_603046,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_602787 = ref object of OpenApiRestCall_602450
proc url_GetApps_602789(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApps_602788(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all of your applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_602901 = query.getOrDefault("token")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "token", valid_602901
  var valid_602902 = query.getOrDefault("page-size")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "page-size", valid_602902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602903 = header.getOrDefault("X-Amz-Date")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Date", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Security-Token")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Security-Token", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Content-Sha256", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Algorithm")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Algorithm", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-SignedHeaders", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Credential")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Credential", valid_602909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602932: Call_GetApps_602787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_602932.validator(path, query, header, formData, body)
  let scheme = call_602932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602932.url(scheme.get, call_602932.host, call_602932.base,
                         call_602932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602932, url, valid)

proc call*(call_603003: Call_GetApps_602787; token: string = ""; pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var query_603004 = newJObject()
  add(query_603004, "token", newJString(token))
  add(query_603004, "page-size", newJString(pageSize))
  result = call_603003.call(nil, query_603004, nil, nil, nil)

var getApps* = Call_GetApps_602787(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_602788, base: "/",
                                url: url_GetApps_602789,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_603089 = ref object of OpenApiRestCall_602450
proc url_CreateCampaign_603091(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateCampaign_603090(path: JsonNode; query: JsonNode;
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
  var valid_603092 = path.getOrDefault("application-id")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "application-id", valid_603092
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
  var valid_603093 = header.getOrDefault("X-Amz-Date")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Date", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Security-Token")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Security-Token", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Content-Sha256", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Algorithm")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Algorithm", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Signature")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Signature", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-SignedHeaders", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Credential")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Credential", valid_603099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_CreateCampaign_603089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603101, url, valid)

proc call*(call_603102: Call_CreateCampaign_603089; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603103 = newJObject()
  var body_603104 = newJObject()
  add(path_603103, "application-id", newJString(applicationId))
  if body != nil:
    body_603104 = body
  result = call_603102.call(path_603103, nil, nil, nil, body_603104)

var createCampaign* = Call_CreateCampaign_603089(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_603090, base: "/", url: url_CreateCampaign_603091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_603058 = ref object of OpenApiRestCall_602450
proc url_GetCampaigns_603060(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaigns_603059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603075 = path.getOrDefault("application-id")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = nil)
  if valid_603075 != nil:
    section.add "application-id", valid_603075
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603076 = query.getOrDefault("token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "token", valid_603076
  var valid_603077 = query.getOrDefault("page-size")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "page-size", valid_603077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603078 = header.getOrDefault("X-Amz-Date")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Date", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Content-Sha256", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Algorithm")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Algorithm", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Signature")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Signature", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Credential")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Credential", valid_603084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_GetCampaigns_603058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603085, url, valid)

proc call*(call_603086: Call_GetCampaigns_603058; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603087 = newJObject()
  var query_603088 = newJObject()
  add(query_603088, "token", newJString(token))
  add(path_603087, "application-id", newJString(applicationId))
  add(query_603088, "page-size", newJString(pageSize))
  result = call_603086.call(path_603087, query_603088, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_603058(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_603059, base: "/", url: url_GetCampaigns_603060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_603122 = ref object of OpenApiRestCall_602450
proc url_CreateExportJob_603124(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateExportJob_603123(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new export job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603125 = path.getOrDefault("application-id")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "application-id", valid_603125
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

proc call*(call_603134: Call_CreateExportJob_603122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new export job for an application.
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_CreateExportJob_603122; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates a new export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603136 = newJObject()
  var body_603137 = newJObject()
  add(path_603136, "application-id", newJString(applicationId))
  if body != nil:
    body_603137 = body
  result = call_603135.call(path_603136, nil, nil, nil, body_603137)

var createExportJob* = Call_CreateExportJob_603122(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_603123, base: "/", url: url_CreateExportJob_603124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_603105 = ref object of OpenApiRestCall_602450
proc url_GetExportJobs_603107(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetExportJobs_603106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603108 = path.getOrDefault("application-id")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "application-id", valid_603108
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603109 = query.getOrDefault("token")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "token", valid_603109
  var valid_603110 = query.getOrDefault("page-size")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "page-size", valid_603110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603111 = header.getOrDefault("X-Amz-Date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Date", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Security-Token")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Security-Token", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Content-Sha256", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Algorithm")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Algorithm", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Credential")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Credential", valid_603117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603118: Call_GetExportJobs_603105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_603118.validator(path, query, header, formData, body)
  let scheme = call_603118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603118.url(scheme.get, call_603118.host, call_603118.base,
                         call_603118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603118, url, valid)

proc call*(call_603119: Call_GetExportJobs_603105; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603120 = newJObject()
  var query_603121 = newJObject()
  add(query_603121, "token", newJString(token))
  add(path_603120, "application-id", newJString(applicationId))
  add(query_603121, "page-size", newJString(pageSize))
  result = call_603119.call(path_603120, query_603121, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_603105(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_603106, base: "/", url: url_GetExportJobs_603107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_603155 = ref object of OpenApiRestCall_602450
proc url_CreateImportJob_603157(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateImportJob_603156(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new import job for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603158 = path.getOrDefault("application-id")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "application-id", valid_603158
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

proc call*(call_603167: Call_CreateImportJob_603155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new import job for an application.
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_CreateImportJob_603155; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates a new import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603169 = newJObject()
  var body_603170 = newJObject()
  add(path_603169, "application-id", newJString(applicationId))
  if body != nil:
    body_603170 = body
  result = call_603168.call(path_603169, nil, nil, nil, body_603170)

var createImportJob* = Call_CreateImportJob_603155(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_603156, base: "/", url: url_CreateImportJob_603157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_603138 = ref object of OpenApiRestCall_602450
proc url_GetImportJobs_603140(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetImportJobs_603139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603141 = path.getOrDefault("application-id")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "application-id", valid_603141
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603142 = query.getOrDefault("token")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "token", valid_603142
  var valid_603143 = query.getOrDefault("page-size")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "page-size", valid_603143
  result.add "query", section
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

proc call*(call_603151: Call_GetImportJobs_603138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_603151.validator(path, query, header, formData, body)
  let scheme = call_603151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603151.url(scheme.get, call_603151.host, call_603151.base,
                         call_603151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603151, url, valid)

proc call*(call_603152: Call_GetImportJobs_603138; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603153 = newJObject()
  var query_603154 = newJObject()
  add(query_603154, "token", newJString(token))
  add(path_603153, "application-id", newJString(applicationId))
  add(query_603154, "page-size", newJString(pageSize))
  result = call_603152.call(path_603153, query_603154, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_603138(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_603139, base: "/", url: url_GetImportJobs_603140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_603188 = ref object of OpenApiRestCall_602450
proc url_CreateSegment_603190(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateSegment_603189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603191 = path.getOrDefault("application-id")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "application-id", valid_603191
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

proc call*(call_603200: Call_CreateSegment_603188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_603200.validator(path, query, header, formData, body)
  let scheme = call_603200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603200.url(scheme.get, call_603200.host, call_603200.base,
                         call_603200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603200, url, valid)

proc call*(call_603201: Call_CreateSegment_603188; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603202 = newJObject()
  var body_603203 = newJObject()
  add(path_603202, "application-id", newJString(applicationId))
  if body != nil:
    body_603203 = body
  result = call_603201.call(path_603202, nil, nil, nil, body_603203)

var createSegment* = Call_CreateSegment_603188(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_603189, base: "/", url: url_CreateSegment_603190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_603171 = ref object of OpenApiRestCall_602450
proc url_GetSegments_603173(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSegments_603172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603174 = path.getOrDefault("application-id")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "application-id", valid_603174
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603175 = query.getOrDefault("token")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "token", valid_603175
  var valid_603176 = query.getOrDefault("page-size")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "page-size", valid_603176
  result.add "query", section
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

proc call*(call_603184: Call_GetSegments_603171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_603184.validator(path, query, header, formData, body)
  let scheme = call_603184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603184.url(scheme.get, call_603184.host, call_603184.base,
                         call_603184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603184, url, valid)

proc call*(call_603185: Call_GetSegments_603171; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603186 = newJObject()
  var query_603187 = newJObject()
  add(query_603187, "token", newJString(token))
  add(path_603186, "application-id", newJString(applicationId))
  add(query_603187, "page-size", newJString(pageSize))
  result = call_603185.call(path_603186, query_603187, nil, nil, nil)

var getSegments* = Call_GetSegments_603171(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_603172,
                                        base: "/", url: url_GetSegments_603173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_603218 = ref object of OpenApiRestCall_602450
proc url_UpdateAdmChannel_603220(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateAdmChannel_603219(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the ADM channel settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603221 = path.getOrDefault("application-id")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "application-id", valid_603221
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

proc call*(call_603230: Call_UpdateAdmChannel_603218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ADM channel settings for an application.
  ## 
  let valid = call_603230.validator(path, query, header, formData, body)
  let scheme = call_603230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603230.url(scheme.get, call_603230.host, call_603230.base,
                         call_603230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603230, url, valid)

proc call*(call_603231: Call_UpdateAdmChannel_603218; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Updates the ADM channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603232 = newJObject()
  var body_603233 = newJObject()
  add(path_603232, "application-id", newJString(applicationId))
  if body != nil:
    body_603233 = body
  result = call_603231.call(path_603232, nil, nil, nil, body_603233)

var updateAdmChannel* = Call_UpdateAdmChannel_603218(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_603219, base: "/",
    url: url_UpdateAdmChannel_603220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_603204 = ref object of OpenApiRestCall_602450
proc url_GetAdmChannel_603206(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetAdmChannel_603205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603207 = path.getOrDefault("application-id")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = nil)
  if valid_603207 != nil:
    section.add "application-id", valid_603207
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

proc call*(call_603215: Call_GetAdmChannel_603204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_603215.validator(path, query, header, formData, body)
  let scheme = call_603215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603215.url(scheme.get, call_603215.host, call_603215.base,
                         call_603215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603215, url, valid)

proc call*(call_603216: Call_GetAdmChannel_603204; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603217 = newJObject()
  add(path_603217, "application-id", newJString(applicationId))
  result = call_603216.call(path_603217, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_603204(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_603205, base: "/", url: url_GetAdmChannel_603206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_603234 = ref object of OpenApiRestCall_602450
proc url_DeleteAdmChannel_603236(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteAdmChannel_603235(path: JsonNode; query: JsonNode;
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
  var valid_603237 = path.getOrDefault("application-id")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "application-id", valid_603237
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

proc call*(call_603245: Call_DeleteAdmChannel_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_DeleteAdmChannel_603234; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603247 = newJObject()
  add(path_603247, "application-id", newJString(applicationId))
  result = call_603246.call(path_603247, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_603234(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_603235, base: "/",
    url: url_DeleteAdmChannel_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_603262 = ref object of OpenApiRestCall_602450
proc url_UpdateApnsChannel_603264(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApnsChannel_603263(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the APNs channel settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603265 = path.getOrDefault("application-id")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = nil)
  if valid_603265 != nil:
    section.add "application-id", valid_603265
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
  var valid_603266 = header.getOrDefault("X-Amz-Date")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Date", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Security-Token")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Security-Token", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Algorithm")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Algorithm", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Signature")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Signature", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-SignedHeaders", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Credential")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Credential", valid_603272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_UpdateApnsChannel_603262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs channel settings for an application.
  ## 
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603274, url, valid)

proc call*(call_603275: Call_UpdateApnsChannel_603262; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Updates the APNs channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603276 = newJObject()
  var body_603277 = newJObject()
  add(path_603276, "application-id", newJString(applicationId))
  if body != nil:
    body_603277 = body
  result = call_603275.call(path_603276, nil, nil, nil, body_603277)

var updateApnsChannel* = Call_UpdateApnsChannel_603262(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_603263, base: "/",
    url: url_UpdateApnsChannel_603264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_603248 = ref object of OpenApiRestCall_602450
proc url_GetApnsChannel_603250(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApnsChannel_603249(path: JsonNode; query: JsonNode;
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
  var valid_603251 = path.getOrDefault("application-id")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "application-id", valid_603251
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
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Content-Sha256", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Algorithm")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Algorithm", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Signature")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Signature", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-SignedHeaders", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Credential")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Credential", valid_603258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_GetApnsChannel_603248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_GetApnsChannel_603248; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603261 = newJObject()
  add(path_603261, "application-id", newJString(applicationId))
  result = call_603260.call(path_603261, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_603248(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_603249, base: "/", url: url_GetApnsChannel_603250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_603278 = ref object of OpenApiRestCall_602450
proc url_DeleteApnsChannel_603280(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApnsChannel_603279(path: JsonNode; query: JsonNode;
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
  var valid_603281 = path.getOrDefault("application-id")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = nil)
  if valid_603281 != nil:
    section.add "application-id", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Content-Sha256", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Algorithm")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Algorithm", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Signature")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Signature", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-SignedHeaders", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Credential")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Credential", valid_603288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603289: Call_DeleteApnsChannel_603278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603289.validator(path, query, header, formData, body)
  let scheme = call_603289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603289.url(scheme.get, call_603289.host, call_603289.base,
                         call_603289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603289, url, valid)

proc call*(call_603290: Call_DeleteApnsChannel_603278; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603291 = newJObject()
  add(path_603291, "application-id", newJString(applicationId))
  result = call_603290.call(path_603291, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_603278(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_603279, base: "/",
    url: url_DeleteApnsChannel_603280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_603306 = ref object of OpenApiRestCall_602450
proc url_UpdateApnsSandboxChannel_603308(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApnsSandboxChannel_603307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the APNs sandbox channel settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603309 = path.getOrDefault("application-id")
  valid_603309 = validateParameter(valid_603309, JString, required = true,
                                 default = nil)
  if valid_603309 != nil:
    section.add "application-id", valid_603309
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
  var valid_603310 = header.getOrDefault("X-Amz-Date")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Date", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Security-Token")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Security-Token", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Content-Sha256", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Algorithm")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Algorithm", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Signature")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Signature", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-SignedHeaders", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Credential")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Credential", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_UpdateApnsSandboxChannel_603306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs sandbox channel settings for an application.
  ## 
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_UpdateApnsSandboxChannel_603306;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Updates the APNs sandbox channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603320 = newJObject()
  var body_603321 = newJObject()
  add(path_603320, "application-id", newJString(applicationId))
  if body != nil:
    body_603321 = body
  result = call_603319.call(path_603320, nil, nil, nil, body_603321)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_603306(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_603307, base: "/",
    url: url_UpdateApnsSandboxChannel_603308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_603292 = ref object of OpenApiRestCall_602450
proc url_GetApnsSandboxChannel_603294(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApnsSandboxChannel_603293(path: JsonNode; query: JsonNode;
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
  var valid_603295 = path.getOrDefault("application-id")
  valid_603295 = validateParameter(valid_603295, JString, required = true,
                                 default = nil)
  if valid_603295 != nil:
    section.add "application-id", valid_603295
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
  var valid_603296 = header.getOrDefault("X-Amz-Date")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Date", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Security-Token")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Security-Token", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Content-Sha256", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Algorithm")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Algorithm", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Signature")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Signature", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-SignedHeaders", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Credential")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Credential", valid_603302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603303: Call_GetApnsSandboxChannel_603292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_603303.validator(path, query, header, formData, body)
  let scheme = call_603303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603303.url(scheme.get, call_603303.host, call_603303.base,
                         call_603303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603303, url, valid)

proc call*(call_603304: Call_GetApnsSandboxChannel_603292; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603305 = newJObject()
  add(path_603305, "application-id", newJString(applicationId))
  result = call_603304.call(path_603305, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_603292(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_603293, base: "/",
    url: url_GetApnsSandboxChannel_603294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_603322 = ref object of OpenApiRestCall_602450
proc url_DeleteApnsSandboxChannel_603324(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApnsSandboxChannel_603323(path: JsonNode; query: JsonNode;
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
  var valid_603325 = path.getOrDefault("application-id")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "application-id", valid_603325
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
  var valid_603326 = header.getOrDefault("X-Amz-Date")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Date", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Security-Token")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Security-Token", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Algorithm")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Algorithm", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603333: Call_DeleteApnsSandboxChannel_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603333.validator(path, query, header, formData, body)
  let scheme = call_603333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603333.url(scheme.get, call_603333.host, call_603333.base,
                         call_603333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603333, url, valid)

proc call*(call_603334: Call_DeleteApnsSandboxChannel_603322; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603335 = newJObject()
  add(path_603335, "application-id", newJString(applicationId))
  result = call_603334.call(path_603335, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_603322(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_603323, base: "/",
    url: url_DeleteApnsSandboxChannel_603324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_603350 = ref object of OpenApiRestCall_602450
proc url_UpdateApnsVoipChannel_603352(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApnsVoipChannel_603351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the APNs VoIP channel settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603353 = path.getOrDefault("application-id")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "application-id", valid_603353
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
  var valid_603354 = header.getOrDefault("X-Amz-Date")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Date", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Security-Token")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Security-Token", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Content-Sha256", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Algorithm")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Algorithm", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Signature")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Signature", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-SignedHeaders", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Credential")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Credential", valid_603360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603362: Call_UpdateApnsVoipChannel_603350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs VoIP channel settings for an application.
  ## 
  let valid = call_603362.validator(path, query, header, formData, body)
  let scheme = call_603362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603362.url(scheme.get, call_603362.host, call_603362.base,
                         call_603362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603362, url, valid)

proc call*(call_603363: Call_UpdateApnsVoipChannel_603350; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Updates the APNs VoIP channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603364 = newJObject()
  var body_603365 = newJObject()
  add(path_603364, "application-id", newJString(applicationId))
  if body != nil:
    body_603365 = body
  result = call_603363.call(path_603364, nil, nil, nil, body_603365)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_603350(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_603351, base: "/",
    url: url_UpdateApnsVoipChannel_603352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_603336 = ref object of OpenApiRestCall_602450
proc url_GetApnsVoipChannel_603338(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApnsVoipChannel_603337(path: JsonNode; query: JsonNode;
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
  var valid_603339 = path.getOrDefault("application-id")
  valid_603339 = validateParameter(valid_603339, JString, required = true,
                                 default = nil)
  if valid_603339 != nil:
    section.add "application-id", valid_603339
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
  var valid_603340 = header.getOrDefault("X-Amz-Date")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Date", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Security-Token")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Security-Token", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Content-Sha256", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Algorithm")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Algorithm", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Signature")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Signature", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-SignedHeaders", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Credential")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Credential", valid_603346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603347: Call_GetApnsVoipChannel_603336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_603347.validator(path, query, header, formData, body)
  let scheme = call_603347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603347.url(scheme.get, call_603347.host, call_603347.base,
                         call_603347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603347, url, valid)

proc call*(call_603348: Call_GetApnsVoipChannel_603336; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603349 = newJObject()
  add(path_603349, "application-id", newJString(applicationId))
  result = call_603348.call(path_603349, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_603336(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_603337, base: "/",
    url: url_GetApnsVoipChannel_603338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_603366 = ref object of OpenApiRestCall_602450
proc url_DeleteApnsVoipChannel_603368(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApnsVoipChannel_603367(path: JsonNode; query: JsonNode;
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
  var valid_603369 = path.getOrDefault("application-id")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = nil)
  if valid_603369 != nil:
    section.add "application-id", valid_603369
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
  var valid_603370 = header.getOrDefault("X-Amz-Date")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Date", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Security-Token")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Security-Token", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Content-Sha256", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Algorithm")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Algorithm", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Signature")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Signature", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-SignedHeaders", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603377: Call_DeleteApnsVoipChannel_603366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603377.validator(path, query, header, formData, body)
  let scheme = call_603377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603377.url(scheme.get, call_603377.host, call_603377.base,
                         call_603377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603377, url, valid)

proc call*(call_603378: Call_DeleteApnsVoipChannel_603366; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603379 = newJObject()
  add(path_603379, "application-id", newJString(applicationId))
  result = call_603378.call(path_603379, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_603366(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_603367, base: "/",
    url: url_DeleteApnsVoipChannel_603368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_603394 = ref object of OpenApiRestCall_602450
proc url_UpdateApnsVoipSandboxChannel_603396(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApnsVoipSandboxChannel_603395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603397 = path.getOrDefault("application-id")
  valid_603397 = validateParameter(valid_603397, JString, required = true,
                                 default = nil)
  if valid_603397 != nil:
    section.add "application-id", valid_603397
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
  var valid_603398 = header.getOrDefault("X-Amz-Date")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Date", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Security-Token")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Security-Token", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Content-Sha256", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Algorithm")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Algorithm", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-SignedHeaders", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603406: Call_UpdateApnsVoipSandboxChannel_603394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_603406.validator(path, query, header, formData, body)
  let scheme = call_603406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603406.url(scheme.get, call_603406.host, call_603406.base,
                         call_603406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603406, url, valid)

proc call*(call_603407: Call_UpdateApnsVoipSandboxChannel_603394;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603408 = newJObject()
  var body_603409 = newJObject()
  add(path_603408, "application-id", newJString(applicationId))
  if body != nil:
    body_603409 = body
  result = call_603407.call(path_603408, nil, nil, nil, body_603409)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_603394(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_603395, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_603396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_603380 = ref object of OpenApiRestCall_602450
proc url_GetApnsVoipSandboxChannel_603382(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetApnsVoipSandboxChannel_603381(path: JsonNode; query: JsonNode;
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
  var valid_603383 = path.getOrDefault("application-id")
  valid_603383 = validateParameter(valid_603383, JString, required = true,
                                 default = nil)
  if valid_603383 != nil:
    section.add "application-id", valid_603383
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
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Content-Sha256", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Algorithm")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Algorithm", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Signature")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Signature", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-SignedHeaders", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603391: Call_GetApnsVoipSandboxChannel_603380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_603391.validator(path, query, header, formData, body)
  let scheme = call_603391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603391.url(scheme.get, call_603391.host, call_603391.base,
                         call_603391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603391, url, valid)

proc call*(call_603392: Call_GetApnsVoipSandboxChannel_603380;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603393 = newJObject()
  add(path_603393, "application-id", newJString(applicationId))
  result = call_603392.call(path_603393, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_603380(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_603381, base: "/",
    url: url_GetApnsVoipSandboxChannel_603382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_603410 = ref object of OpenApiRestCall_602450
proc url_DeleteApnsVoipSandboxChannel_603412(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApnsVoipSandboxChannel_603411(path: JsonNode; query: JsonNode;
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
  var valid_603413 = path.getOrDefault("application-id")
  valid_603413 = validateParameter(valid_603413, JString, required = true,
                                 default = nil)
  if valid_603413 != nil:
    section.add "application-id", valid_603413
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
  var valid_603414 = header.getOrDefault("X-Amz-Date")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Date", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Security-Token")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Security-Token", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Content-Sha256", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Algorithm")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Algorithm", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Signature")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Signature", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-SignedHeaders", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Credential")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Credential", valid_603420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603421: Call_DeleteApnsVoipSandboxChannel_603410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603421.validator(path, query, header, formData, body)
  let scheme = call_603421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603421.url(scheme.get, call_603421.host, call_603421.base,
                         call_603421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603421, url, valid)

proc call*(call_603422: Call_DeleteApnsVoipSandboxChannel_603410;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603423 = newJObject()
  add(path_603423, "application-id", newJString(applicationId))
  result = call_603422.call(path_603423, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_603410(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_603411, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_603412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_603424 = ref object of OpenApiRestCall_602450
proc url_GetApp_603426(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetApp_603425(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603427 = path.getOrDefault("application-id")
  valid_603427 = validateParameter(valid_603427, JString, required = true,
                                 default = nil)
  if valid_603427 != nil:
    section.add "application-id", valid_603427
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
  var valid_603428 = header.getOrDefault("X-Amz-Date")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Date", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Security-Token")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Security-Token", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Content-Sha256", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Algorithm")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Algorithm", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Signature")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Signature", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-SignedHeaders", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Credential")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Credential", valid_603434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603435: Call_GetApp_603424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_603435.validator(path, query, header, formData, body)
  let scheme = call_603435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603435.url(scheme.get, call_603435.host, call_603435.base,
                         call_603435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603435, url, valid)

proc call*(call_603436: Call_GetApp_603424; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603437 = newJObject()
  add(path_603437, "application-id", newJString(applicationId))
  result = call_603436.call(path_603437, nil, nil, nil, nil)

var getApp* = Call_GetApp_603424(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_603425, base: "/",
                              url: url_GetApp_603426,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_603438 = ref object of OpenApiRestCall_602450
proc url_DeleteApp_603440(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApp_603439(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603441 = path.getOrDefault("application-id")
  valid_603441 = validateParameter(valid_603441, JString, required = true,
                                 default = nil)
  if valid_603441 != nil:
    section.add "application-id", valid_603441
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
  var valid_603442 = header.getOrDefault("X-Amz-Date")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Date", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Security-Token")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Security-Token", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Content-Sha256", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Algorithm")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Algorithm", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Signature")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Signature", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-SignedHeaders", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Credential")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Credential", valid_603448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603449: Call_DeleteApp_603438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_603449.validator(path, query, header, formData, body)
  let scheme = call_603449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603449.url(scheme.get, call_603449.host, call_603449.base,
                         call_603449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603449, url, valid)

proc call*(call_603450: Call_DeleteApp_603438; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603451 = newJObject()
  add(path_603451, "application-id", newJString(applicationId))
  result = call_603450.call(path_603451, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_603438(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_603439,
                                    base: "/", url: url_DeleteApp_603440,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_603466 = ref object of OpenApiRestCall_602450
proc url_UpdateBaiduChannel_603468(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBaiduChannel_603467(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the settings of the Baidu channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603469 = path.getOrDefault("application-id")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "application-id", valid_603469
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
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Security-Token")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Security-Token", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_UpdateBaiduChannel_603466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of the Baidu channel for an application.
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_UpdateBaiduChannel_603466; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Updates the settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603480 = newJObject()
  var body_603481 = newJObject()
  add(path_603480, "application-id", newJString(applicationId))
  if body != nil:
    body_603481 = body
  result = call_603479.call(path_603480, nil, nil, nil, body_603481)

var updateBaiduChannel* = Call_UpdateBaiduChannel_603466(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_603467, base: "/",
    url: url_UpdateBaiduChannel_603468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_603452 = ref object of OpenApiRestCall_602450
proc url_GetBaiduChannel_603454(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetBaiduChannel_603453(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603455 = path.getOrDefault("application-id")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = nil)
  if valid_603455 != nil:
    section.add "application-id", valid_603455
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
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_GetBaiduChannel_603452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_GetBaiduChannel_603452; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603465 = newJObject()
  add(path_603465, "application-id", newJString(applicationId))
  result = call_603464.call(path_603465, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_603452(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_603453, base: "/", url: url_GetBaiduChannel_603454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_603482 = ref object of OpenApiRestCall_602450
proc url_DeleteBaiduChannel_603484(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteBaiduChannel_603483(path: JsonNode; query: JsonNode;
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
  var valid_603485 = path.getOrDefault("application-id")
  valid_603485 = validateParameter(valid_603485, JString, required = true,
                                 default = nil)
  if valid_603485 != nil:
    section.add "application-id", valid_603485
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
  var valid_603486 = header.getOrDefault("X-Amz-Date")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Date", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Content-Sha256", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Algorithm")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Algorithm", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Signature")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Signature", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-SignedHeaders", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Credential")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Credential", valid_603492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_DeleteBaiduChannel_603482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_DeleteBaiduChannel_603482; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603495 = newJObject()
  add(path_603495, "application-id", newJString(applicationId))
  result = call_603494.call(path_603495, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_603482(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_603483, base: "/",
    url: url_DeleteBaiduChannel_603484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_603511 = ref object of OpenApiRestCall_602450
proc url_UpdateCampaign_603513(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateCampaign_603512(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the settings for a campaign.
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
  var valid_603514 = path.getOrDefault("application-id")
  valid_603514 = validateParameter(valid_603514, JString, required = true,
                                 default = nil)
  if valid_603514 != nil:
    section.add "application-id", valid_603514
  var valid_603515 = path.getOrDefault("campaign-id")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "campaign-id", valid_603515
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
  var valid_603516 = header.getOrDefault("X-Amz-Date")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Date", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Security-Token")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Security-Token", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Content-Sha256", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Algorithm")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Algorithm", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Signature")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Signature", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-SignedHeaders", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Credential")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Credential", valid_603522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603524: Call_UpdateCampaign_603511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for a campaign.
  ## 
  let valid = call_603524.validator(path, query, header, formData, body)
  let scheme = call_603524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603524.url(scheme.get, call_603524.host, call_603524.base,
                         call_603524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603524, url, valid)

proc call*(call_603525: Call_UpdateCampaign_603511; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_603526 = newJObject()
  var body_603527 = newJObject()
  add(path_603526, "application-id", newJString(applicationId))
  if body != nil:
    body_603527 = body
  add(path_603526, "campaign-id", newJString(campaignId))
  result = call_603525.call(path_603526, nil, nil, nil, body_603527)

var updateCampaign* = Call_UpdateCampaign_603511(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_603512, base: "/", url: url_UpdateCampaign_603513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_603496 = ref object of OpenApiRestCall_602450
proc url_GetCampaign_603498(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaign_603497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603499 = path.getOrDefault("application-id")
  valid_603499 = validateParameter(valid_603499, JString, required = true,
                                 default = nil)
  if valid_603499 != nil:
    section.add "application-id", valid_603499
  var valid_603500 = path.getOrDefault("campaign-id")
  valid_603500 = validateParameter(valid_603500, JString, required = true,
                                 default = nil)
  if valid_603500 != nil:
    section.add "campaign-id", valid_603500
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
  var valid_603501 = header.getOrDefault("X-Amz-Date")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Date", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Security-Token")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Security-Token", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Content-Sha256", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Algorithm")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Algorithm", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Signature")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Signature", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-SignedHeaders", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Credential")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Credential", valid_603507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_GetCampaign_603496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603508, url, valid)

proc call*(call_603509: Call_GetCampaign_603496; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_603510 = newJObject()
  add(path_603510, "application-id", newJString(applicationId))
  add(path_603510, "campaign-id", newJString(campaignId))
  result = call_603509.call(path_603510, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_603496(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_603497,
                                        base: "/", url: url_GetCampaign_603498,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_603528 = ref object of OpenApiRestCall_602450
proc url_DeleteCampaign_603530(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteCampaign_603529(path: JsonNode; query: JsonNode;
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
  var valid_603531 = path.getOrDefault("application-id")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = nil)
  if valid_603531 != nil:
    section.add "application-id", valid_603531
  var valid_603532 = path.getOrDefault("campaign-id")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = nil)
  if valid_603532 != nil:
    section.add "campaign-id", valid_603532
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
  var valid_603533 = header.getOrDefault("X-Amz-Date")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Date", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Security-Token")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Security-Token", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Content-Sha256", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Algorithm")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Algorithm", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Signature")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Signature", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-SignedHeaders", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Credential")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Credential", valid_603539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603540: Call_DeleteCampaign_603528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_603540.validator(path, query, header, formData, body)
  let scheme = call_603540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603540.url(scheme.get, call_603540.host, call_603540.base,
                         call_603540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603540, url, valid)

proc call*(call_603541: Call_DeleteCampaign_603528; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_603542 = newJObject()
  add(path_603542, "application-id", newJString(applicationId))
  add(path_603542, "campaign-id", newJString(campaignId))
  result = call_603541.call(path_603542, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_603528(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_603529, base: "/", url: url_DeleteCampaign_603530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_603557 = ref object of OpenApiRestCall_602450
proc url_UpdateEmailChannel_603559(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateEmailChannel_603558(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the status and settings of the email channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603560 = path.getOrDefault("application-id")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = nil)
  if valid_603560 != nil:
    section.add "application-id", valid_603560
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
  var valid_603561 = header.getOrDefault("X-Amz-Date")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Date", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Security-Token")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Security-Token", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Content-Sha256", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Algorithm")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Algorithm", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Signature")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Signature", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-SignedHeaders", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Credential")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Credential", valid_603567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603569: Call_UpdateEmailChannel_603557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the email channel for an application.
  ## 
  let valid = call_603569.validator(path, query, header, formData, body)
  let scheme = call_603569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603569.url(scheme.get, call_603569.host, call_603569.base,
                         call_603569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603569, url, valid)

proc call*(call_603570: Call_UpdateEmailChannel_603557; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603571 = newJObject()
  var body_603572 = newJObject()
  add(path_603571, "application-id", newJString(applicationId))
  if body != nil:
    body_603572 = body
  result = call_603570.call(path_603571, nil, nil, nil, body_603572)

var updateEmailChannel* = Call_UpdateEmailChannel_603557(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_603558, base: "/",
    url: url_UpdateEmailChannel_603559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_603543 = ref object of OpenApiRestCall_602450
proc url_GetEmailChannel_603545(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEmailChannel_603544(path: JsonNode; query: JsonNode;
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
  var valid_603546 = path.getOrDefault("application-id")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = nil)
  if valid_603546 != nil:
    section.add "application-id", valid_603546
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
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Content-Sha256", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Credential")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Credential", valid_603553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603554: Call_GetEmailChannel_603543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_603554.validator(path, query, header, formData, body)
  let scheme = call_603554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603554.url(scheme.get, call_603554.host, call_603554.base,
                         call_603554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603554, url, valid)

proc call*(call_603555: Call_GetEmailChannel_603543; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603556 = newJObject()
  add(path_603556, "application-id", newJString(applicationId))
  result = call_603555.call(path_603556, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_603543(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_603544, base: "/", url: url_GetEmailChannel_603545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_603573 = ref object of OpenApiRestCall_602450
proc url_DeleteEmailChannel_603575(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteEmailChannel_603574(path: JsonNode; query: JsonNode;
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
  var valid_603576 = path.getOrDefault("application-id")
  valid_603576 = validateParameter(valid_603576, JString, required = true,
                                 default = nil)
  if valid_603576 != nil:
    section.add "application-id", valid_603576
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
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Content-Sha256", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Algorithm")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Algorithm", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Signature")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Signature", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-SignedHeaders", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Credential")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Credential", valid_603583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603584: Call_DeleteEmailChannel_603573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603584.validator(path, query, header, formData, body)
  let scheme = call_603584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603584.url(scheme.get, call_603584.host, call_603584.base,
                         call_603584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603584, url, valid)

proc call*(call_603585: Call_DeleteEmailChannel_603573; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603586 = newJObject()
  add(path_603586, "application-id", newJString(applicationId))
  result = call_603585.call(path_603586, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_603573(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_603574, base: "/",
    url: url_DeleteEmailChannel_603575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_603602 = ref object of OpenApiRestCall_602450
proc url_UpdateEndpoint_603604(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateEndpoint_603603(path: JsonNode; query: JsonNode;
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
  var valid_603605 = path.getOrDefault("application-id")
  valid_603605 = validateParameter(valid_603605, JString, required = true,
                                 default = nil)
  if valid_603605 != nil:
    section.add "application-id", valid_603605
  var valid_603606 = path.getOrDefault("endpoint-id")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "endpoint-id", valid_603606
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Content-Sha256", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Algorithm")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Algorithm", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Signature")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Signature", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-SignedHeaders", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Credential")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Credential", valid_603613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603615: Call_UpdateEndpoint_603602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_603615.validator(path, query, header, formData, body)
  let scheme = call_603615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603615.url(scheme.get, call_603615.host, call_603615.base,
                         call_603615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603615, url, valid)

proc call*(call_603616: Call_UpdateEndpoint_603602; applicationId: string;
          endpointId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   body: JObject (required)
  var path_603617 = newJObject()
  var body_603618 = newJObject()
  add(path_603617, "application-id", newJString(applicationId))
  add(path_603617, "endpoint-id", newJString(endpointId))
  if body != nil:
    body_603618 = body
  result = call_603616.call(path_603617, nil, nil, nil, body_603618)

var updateEndpoint* = Call_UpdateEndpoint_603602(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_603603, base: "/", url: url_UpdateEndpoint_603604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_603587 = ref object of OpenApiRestCall_602450
proc url_GetEndpoint_603589(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEndpoint_603588(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603590 = path.getOrDefault("application-id")
  valid_603590 = validateParameter(valid_603590, JString, required = true,
                                 default = nil)
  if valid_603590 != nil:
    section.add "application-id", valid_603590
  var valid_603591 = path.getOrDefault("endpoint-id")
  valid_603591 = validateParameter(valid_603591, JString, required = true,
                                 default = nil)
  if valid_603591 != nil:
    section.add "endpoint-id", valid_603591
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
  var valid_603592 = header.getOrDefault("X-Amz-Date")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Date", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Content-Sha256", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Algorithm")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Algorithm", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Signature")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Signature", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-SignedHeaders", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Credential")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Credential", valid_603598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603599: Call_GetEndpoint_603587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_603599.validator(path, query, header, formData, body)
  let scheme = call_603599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603599.url(scheme.get, call_603599.host, call_603599.base,
                         call_603599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603599, url, valid)

proc call*(call_603600: Call_GetEndpoint_603587; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_603601 = newJObject()
  add(path_603601, "application-id", newJString(applicationId))
  add(path_603601, "endpoint-id", newJString(endpointId))
  result = call_603600.call(path_603601, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_603587(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_603588,
                                        base: "/", url: url_GetEndpoint_603589,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_603619 = ref object of OpenApiRestCall_602450
proc url_DeleteEndpoint_603621(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteEndpoint_603620(path: JsonNode; query: JsonNode;
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
  var valid_603622 = path.getOrDefault("application-id")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = nil)
  if valid_603622 != nil:
    section.add "application-id", valid_603622
  var valid_603623 = path.getOrDefault("endpoint-id")
  valid_603623 = validateParameter(valid_603623, JString, required = true,
                                 default = nil)
  if valid_603623 != nil:
    section.add "endpoint-id", valid_603623
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
  var valid_603624 = header.getOrDefault("X-Amz-Date")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Date", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Security-Token")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Security-Token", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Content-Sha256", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Algorithm")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Algorithm", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Signature")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Signature", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-SignedHeaders", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Credential")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Credential", valid_603630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_DeleteEndpoint_603619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_DeleteEndpoint_603619; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_603633 = newJObject()
  add(path_603633, "application-id", newJString(applicationId))
  add(path_603633, "endpoint-id", newJString(endpointId))
  result = call_603632.call(path_603633, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_603619(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_603620, base: "/", url: url_DeleteEndpoint_603621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_603648 = ref object of OpenApiRestCall_602450
proc url_PutEventStream_603650(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutEventStream_603649(path: JsonNode; query: JsonNode;
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
  var valid_603651 = path.getOrDefault("application-id")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "application-id", valid_603651
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
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Content-Sha256", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Algorithm")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Algorithm", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Signature")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Signature", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-SignedHeaders", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Credential")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Credential", valid_603658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603660: Call_PutEventStream_603648; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_603660.validator(path, query, header, formData, body)
  let scheme = call_603660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603660.url(scheme.get, call_603660.host, call_603660.base,
                         call_603660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603660, url, valid)

proc call*(call_603661: Call_PutEventStream_603648; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603662 = newJObject()
  var body_603663 = newJObject()
  add(path_603662, "application-id", newJString(applicationId))
  if body != nil:
    body_603663 = body
  result = call_603661.call(path_603662, nil, nil, nil, body_603663)

var putEventStream* = Call_PutEventStream_603648(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_603649, base: "/", url: url_PutEventStream_603650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_603634 = ref object of OpenApiRestCall_602450
proc url_GetEventStream_603636(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEventStream_603635(path: JsonNode; query: JsonNode;
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
  var valid_603637 = path.getOrDefault("application-id")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = nil)
  if valid_603637 != nil:
    section.add "application-id", valid_603637
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
  var valid_603638 = header.getOrDefault("X-Amz-Date")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Date", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Security-Token")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Security-Token", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Content-Sha256", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Algorithm")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Algorithm", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Signature")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Signature", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-SignedHeaders", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Credential")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Credential", valid_603644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603645: Call_GetEventStream_603634; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_603645.validator(path, query, header, formData, body)
  let scheme = call_603645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603645.url(scheme.get, call_603645.host, call_603645.base,
                         call_603645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603645, url, valid)

proc call*(call_603646: Call_GetEventStream_603634; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603647 = newJObject()
  add(path_603647, "application-id", newJString(applicationId))
  result = call_603646.call(path_603647, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_603634(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_603635, base: "/", url: url_GetEventStream_603636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_603664 = ref object of OpenApiRestCall_602450
proc url_DeleteEventStream_603666(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteEventStream_603665(path: JsonNode; query: JsonNode;
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
  var valid_603667 = path.getOrDefault("application-id")
  valid_603667 = validateParameter(valid_603667, JString, required = true,
                                 default = nil)
  if valid_603667 != nil:
    section.add "application-id", valid_603667
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
  var valid_603668 = header.getOrDefault("X-Amz-Date")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Date", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Security-Token")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Security-Token", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Algorithm")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Algorithm", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Signature")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Signature", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-SignedHeaders", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Credential")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Credential", valid_603674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603675: Call_DeleteEventStream_603664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_603675.validator(path, query, header, formData, body)
  let scheme = call_603675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603675.url(scheme.get, call_603675.host, call_603675.base,
                         call_603675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603675, url, valid)

proc call*(call_603676: Call_DeleteEventStream_603664; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603677 = newJObject()
  add(path_603677, "application-id", newJString(applicationId))
  result = call_603676.call(path_603677, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_603664(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_603665, base: "/",
    url: url_DeleteEventStream_603666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_603692 = ref object of OpenApiRestCall_602450
proc url_UpdateGcmChannel_603694(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateGcmChannel_603693(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the status and settings of the GCM channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603695 = path.getOrDefault("application-id")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = nil)
  if valid_603695 != nil:
    section.add "application-id", valid_603695
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
  var valid_603696 = header.getOrDefault("X-Amz-Date")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Date", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Security-Token")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Security-Token", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Algorithm")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Algorithm", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Signature")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Signature", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-SignedHeaders", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Credential")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Credential", valid_603702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_UpdateGcmChannel_603692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_UpdateGcmChannel_603692; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603706 = newJObject()
  var body_603707 = newJObject()
  add(path_603706, "application-id", newJString(applicationId))
  if body != nil:
    body_603707 = body
  result = call_603705.call(path_603706, nil, nil, nil, body_603707)

var updateGcmChannel* = Call_UpdateGcmChannel_603692(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_603693, base: "/",
    url: url_UpdateGcmChannel_603694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_603678 = ref object of OpenApiRestCall_602450
proc url_GetGcmChannel_603680(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetGcmChannel_603679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603681 = path.getOrDefault("application-id")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = nil)
  if valid_603681 != nil:
    section.add "application-id", valid_603681
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
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Content-Sha256", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Algorithm")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Algorithm", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Signature")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Signature", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-SignedHeaders", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Credential")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Credential", valid_603688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603689: Call_GetGcmChannel_603678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_603689.validator(path, query, header, formData, body)
  let scheme = call_603689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603689.url(scheme.get, call_603689.host, call_603689.base,
                         call_603689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603689, url, valid)

proc call*(call_603690: Call_GetGcmChannel_603678; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603691 = newJObject()
  add(path_603691, "application-id", newJString(applicationId))
  result = call_603690.call(path_603691, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_603678(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_603679, base: "/", url: url_GetGcmChannel_603680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_603708 = ref object of OpenApiRestCall_602450
proc url_DeleteGcmChannel_603710(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteGcmChannel_603709(path: JsonNode; query: JsonNode;
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
  var valid_603711 = path.getOrDefault("application-id")
  valid_603711 = validateParameter(valid_603711, JString, required = true,
                                 default = nil)
  if valid_603711 != nil:
    section.add "application-id", valid_603711
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
  var valid_603712 = header.getOrDefault("X-Amz-Date")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Date", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Security-Token")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Security-Token", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Content-Sha256", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Algorithm")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Algorithm", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Signature")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Signature", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-SignedHeaders", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Credential")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Credential", valid_603718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603719: Call_DeleteGcmChannel_603708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603719.validator(path, query, header, formData, body)
  let scheme = call_603719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603719.url(scheme.get, call_603719.host, call_603719.base,
                         call_603719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603719, url, valid)

proc call*(call_603720: Call_DeleteGcmChannel_603708; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603721 = newJObject()
  add(path_603721, "application-id", newJString(applicationId))
  result = call_603720.call(path_603721, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_603708(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_603709, base: "/",
    url: url_DeleteGcmChannel_603710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_603737 = ref object of OpenApiRestCall_602450
proc url_UpdateSegment_603739(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateSegment_603738(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603740 = path.getOrDefault("segment-id")
  valid_603740 = validateParameter(valid_603740, JString, required = true,
                                 default = nil)
  if valid_603740 != nil:
    section.add "segment-id", valid_603740
  var valid_603741 = path.getOrDefault("application-id")
  valid_603741 = validateParameter(valid_603741, JString, required = true,
                                 default = nil)
  if valid_603741 != nil:
    section.add "application-id", valid_603741
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
  var valid_603742 = header.getOrDefault("X-Amz-Date")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Date", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Security-Token")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Security-Token", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Algorithm")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Algorithm", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Signature")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Signature", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-SignedHeaders", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Credential")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Credential", valid_603748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603750: Call_UpdateSegment_603737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_603750.validator(path, query, header, formData, body)
  let scheme = call_603750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603750.url(scheme.get, call_603750.host, call_603750.base,
                         call_603750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603750, url, valid)

proc call*(call_603751: Call_UpdateSegment_603737; segmentId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603752 = newJObject()
  var body_603753 = newJObject()
  add(path_603752, "segment-id", newJString(segmentId))
  add(path_603752, "application-id", newJString(applicationId))
  if body != nil:
    body_603753 = body
  result = call_603751.call(path_603752, nil, nil, nil, body_603753)

var updateSegment* = Call_UpdateSegment_603737(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_603738, base: "/", url: url_UpdateSegment_603739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_603722 = ref object of OpenApiRestCall_602450
proc url_GetSegment_603724(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetSegment_603723(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603725 = path.getOrDefault("segment-id")
  valid_603725 = validateParameter(valid_603725, JString, required = true,
                                 default = nil)
  if valid_603725 != nil:
    section.add "segment-id", valid_603725
  var valid_603726 = path.getOrDefault("application-id")
  valid_603726 = validateParameter(valid_603726, JString, required = true,
                                 default = nil)
  if valid_603726 != nil:
    section.add "application-id", valid_603726
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
  var valid_603727 = header.getOrDefault("X-Amz-Date")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Date", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Security-Token")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Security-Token", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Content-Sha256", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Algorithm")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Algorithm", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Signature")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Signature", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-SignedHeaders", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Credential")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Credential", valid_603733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603734: Call_GetSegment_603722; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_603734.validator(path, query, header, formData, body)
  let scheme = call_603734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603734.url(scheme.get, call_603734.host, call_603734.base,
                         call_603734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603734, url, valid)

proc call*(call_603735: Call_GetSegment_603722; segmentId: string;
          applicationId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603736 = newJObject()
  add(path_603736, "segment-id", newJString(segmentId))
  add(path_603736, "application-id", newJString(applicationId))
  result = call_603735.call(path_603736, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_603722(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_603723,
                                      base: "/", url: url_GetSegment_603724,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_603754 = ref object of OpenApiRestCall_602450
proc url_DeleteSegment_603756(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteSegment_603755(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603757 = path.getOrDefault("segment-id")
  valid_603757 = validateParameter(valid_603757, JString, required = true,
                                 default = nil)
  if valid_603757 != nil:
    section.add "segment-id", valid_603757
  var valid_603758 = path.getOrDefault("application-id")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = nil)
  if valid_603758 != nil:
    section.add "application-id", valid_603758
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
  var valid_603759 = header.getOrDefault("X-Amz-Date")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Date", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Security-Token")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Security-Token", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Content-Sha256", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Algorithm")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Algorithm", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Signature")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Signature", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-SignedHeaders", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_DeleteSegment_603754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_DeleteSegment_603754; segmentId: string;
          applicationId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603768 = newJObject()
  add(path_603768, "segment-id", newJString(segmentId))
  add(path_603768, "application-id", newJString(applicationId))
  result = call_603767.call(path_603768, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_603754(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_603755, base: "/", url: url_DeleteSegment_603756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_603783 = ref object of OpenApiRestCall_602450
proc url_UpdateSmsChannel_603785(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateSmsChannel_603784(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the status and settings of the SMS channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603786 = path.getOrDefault("application-id")
  valid_603786 = validateParameter(valid_603786, JString, required = true,
                                 default = nil)
  if valid_603786 != nil:
    section.add "application-id", valid_603786
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
  var valid_603787 = header.getOrDefault("X-Amz-Date")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Date", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Security-Token")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Security-Token", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Content-Sha256", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Algorithm")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Algorithm", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Signature")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Signature", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-SignedHeaders", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Credential")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Credential", valid_603793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603795: Call_UpdateSmsChannel_603783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_603795.validator(path, query, header, formData, body)
  let scheme = call_603795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603795.url(scheme.get, call_603795.host, call_603795.base,
                         call_603795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603795, url, valid)

proc call*(call_603796: Call_UpdateSmsChannel_603783; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603797 = newJObject()
  var body_603798 = newJObject()
  add(path_603797, "application-id", newJString(applicationId))
  if body != nil:
    body_603798 = body
  result = call_603796.call(path_603797, nil, nil, nil, body_603798)

var updateSmsChannel* = Call_UpdateSmsChannel_603783(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_603784, base: "/",
    url: url_UpdateSmsChannel_603785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_603769 = ref object of OpenApiRestCall_602450
proc url_GetSmsChannel_603771(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSmsChannel_603770(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603772 = path.getOrDefault("application-id")
  valid_603772 = validateParameter(valid_603772, JString, required = true,
                                 default = nil)
  if valid_603772 != nil:
    section.add "application-id", valid_603772
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
  var valid_603773 = header.getOrDefault("X-Amz-Date")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Date", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Security-Token")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Security-Token", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Content-Sha256", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Algorithm")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Algorithm", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Signature")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Signature", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-SignedHeaders", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Credential")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Credential", valid_603779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603780: Call_GetSmsChannel_603769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_603780.validator(path, query, header, formData, body)
  let scheme = call_603780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603780.url(scheme.get, call_603780.host, call_603780.base,
                         call_603780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603780, url, valid)

proc call*(call_603781: Call_GetSmsChannel_603769; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603782 = newJObject()
  add(path_603782, "application-id", newJString(applicationId))
  result = call_603781.call(path_603782, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_603769(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_603770, base: "/", url: url_GetSmsChannel_603771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_603799 = ref object of OpenApiRestCall_602450
proc url_DeleteSmsChannel_603801(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteSmsChannel_603800(path: JsonNode; query: JsonNode;
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
  var valid_603802 = path.getOrDefault("application-id")
  valid_603802 = validateParameter(valid_603802, JString, required = true,
                                 default = nil)
  if valid_603802 != nil:
    section.add "application-id", valid_603802
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
  var valid_603803 = header.getOrDefault("X-Amz-Date")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Date", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Security-Token")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Security-Token", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Content-Sha256", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Algorithm")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Algorithm", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Signature")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Signature", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-SignedHeaders", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Credential")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Credential", valid_603809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603810: Call_DeleteSmsChannel_603799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603810.validator(path, query, header, formData, body)
  let scheme = call_603810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603810.url(scheme.get, call_603810.host, call_603810.base,
                         call_603810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603810, url, valid)

proc call*(call_603811: Call_DeleteSmsChannel_603799; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603812 = newJObject()
  add(path_603812, "application-id", newJString(applicationId))
  result = call_603811.call(path_603812, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_603799(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_603800, base: "/",
    url: url_DeleteSmsChannel_603801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_603813 = ref object of OpenApiRestCall_602450
proc url_GetUserEndpoints_603815(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUserEndpoints_603814(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_603816 = path.getOrDefault("user-id")
  valid_603816 = validateParameter(valid_603816, JString, required = true,
                                 default = nil)
  if valid_603816 != nil:
    section.add "user-id", valid_603816
  var valid_603817 = path.getOrDefault("application-id")
  valid_603817 = validateParameter(valid_603817, JString, required = true,
                                 default = nil)
  if valid_603817 != nil:
    section.add "application-id", valid_603817
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
  var valid_603818 = header.getOrDefault("X-Amz-Date")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Date", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Security-Token")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Security-Token", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Content-Sha256", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Algorithm")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Algorithm", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Signature")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Signature", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-SignedHeaders", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Credential")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Credential", valid_603824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603825: Call_GetUserEndpoints_603813; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_603825.validator(path, query, header, formData, body)
  let scheme = call_603825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603825.url(scheme.get, call_603825.host, call_603825.base,
                         call_603825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603825, url, valid)

proc call*(call_603826: Call_GetUserEndpoints_603813; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603827 = newJObject()
  add(path_603827, "user-id", newJString(userId))
  add(path_603827, "application-id", newJString(applicationId))
  result = call_603826.call(path_603827, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_603813(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_603814, base: "/",
    url: url_GetUserEndpoints_603815, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_603828 = ref object of OpenApiRestCall_602450
proc url_DeleteUserEndpoints_603830(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteUserEndpoints_603829(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_603831 = path.getOrDefault("user-id")
  valid_603831 = validateParameter(valid_603831, JString, required = true,
                                 default = nil)
  if valid_603831 != nil:
    section.add "user-id", valid_603831
  var valid_603832 = path.getOrDefault("application-id")
  valid_603832 = validateParameter(valid_603832, JString, required = true,
                                 default = nil)
  if valid_603832 != nil:
    section.add "application-id", valid_603832
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
  var valid_603833 = header.getOrDefault("X-Amz-Date")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Date", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Security-Token")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Security-Token", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Content-Sha256", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Algorithm")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Algorithm", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Signature")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Signature", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-SignedHeaders", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Credential")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Credential", valid_603839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603840: Call_DeleteUserEndpoints_603828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_603840.validator(path, query, header, formData, body)
  let scheme = call_603840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603840.url(scheme.get, call_603840.host, call_603840.base,
                         call_603840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603840, url, valid)

proc call*(call_603841: Call_DeleteUserEndpoints_603828; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603842 = newJObject()
  add(path_603842, "user-id", newJString(userId))
  add(path_603842, "application-id", newJString(applicationId))
  result = call_603841.call(path_603842, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_603828(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_603829, base: "/",
    url: url_DeleteUserEndpoints_603830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_603857 = ref object of OpenApiRestCall_602450
proc url_UpdateVoiceChannel_603859(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateVoiceChannel_603858(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the status and settings of the voice channel for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603860 = path.getOrDefault("application-id")
  valid_603860 = validateParameter(valid_603860, JString, required = true,
                                 default = nil)
  if valid_603860 != nil:
    section.add "application-id", valid_603860
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
  var valid_603861 = header.getOrDefault("X-Amz-Date")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Date", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Security-Token")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Security-Token", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Content-Sha256", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Algorithm")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Algorithm", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Signature")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Signature", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-SignedHeaders", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Credential")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Credential", valid_603867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603869: Call_UpdateVoiceChannel_603857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_603869.validator(path, query, header, formData, body)
  let scheme = call_603869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603869.url(scheme.get, call_603869.host, call_603869.base,
                         call_603869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603869, url, valid)

proc call*(call_603870: Call_UpdateVoiceChannel_603857; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603871 = newJObject()
  var body_603872 = newJObject()
  add(path_603871, "application-id", newJString(applicationId))
  if body != nil:
    body_603872 = body
  result = call_603870.call(path_603871, nil, nil, nil, body_603872)

var updateVoiceChannel* = Call_UpdateVoiceChannel_603857(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_603858, base: "/",
    url: url_UpdateVoiceChannel_603859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_603843 = ref object of OpenApiRestCall_602450
proc url_GetVoiceChannel_603845(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetVoiceChannel_603844(path: JsonNode; query: JsonNode;
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
  var valid_603846 = path.getOrDefault("application-id")
  valid_603846 = validateParameter(valid_603846, JString, required = true,
                                 default = nil)
  if valid_603846 != nil:
    section.add "application-id", valid_603846
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
  var valid_603847 = header.getOrDefault("X-Amz-Date")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Date", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Security-Token")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Security-Token", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Content-Sha256", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Algorithm")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Algorithm", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Signature")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Signature", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-SignedHeaders", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Credential")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Credential", valid_603853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603854: Call_GetVoiceChannel_603843; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_603854.validator(path, query, header, formData, body)
  let scheme = call_603854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603854.url(scheme.get, call_603854.host, call_603854.base,
                         call_603854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603854, url, valid)

proc call*(call_603855: Call_GetVoiceChannel_603843; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603856 = newJObject()
  add(path_603856, "application-id", newJString(applicationId))
  result = call_603855.call(path_603856, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_603843(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_603844, base: "/", url: url_GetVoiceChannel_603845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_603873 = ref object of OpenApiRestCall_602450
proc url_DeleteVoiceChannel_603875(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteVoiceChannel_603874(path: JsonNode; query: JsonNode;
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
  var valid_603876 = path.getOrDefault("application-id")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = nil)
  if valid_603876 != nil:
    section.add "application-id", valid_603876
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
  var valid_603877 = header.getOrDefault("X-Amz-Date")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Date", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Security-Token")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Security-Token", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Content-Sha256", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Algorithm")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Algorithm", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Signature")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Signature", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-SignedHeaders", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Credential")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Credential", valid_603883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603884: Call_DeleteVoiceChannel_603873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603884.validator(path, query, header, formData, body)
  let scheme = call_603884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603884.url(scheme.get, call_603884.host, call_603884.base,
                         call_603884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603884, url, valid)

proc call*(call_603885: Call_DeleteVoiceChannel_603873; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603886 = newJObject()
  add(path_603886, "application-id", newJString(applicationId))
  result = call_603885.call(path_603886, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_603873(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_603874, base: "/",
    url: url_DeleteVoiceChannel_603875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_603887 = ref object of OpenApiRestCall_602450
proc url_GetApplicationDateRangeKpi_603889(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetApplicationDateRangeKpi_603888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are attempted-deliveries and successful-deliveries. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603890 = path.getOrDefault("application-id")
  valid_603890 = validateParameter(valid_603890, JString, required = true,
                                 default = nil)
  if valid_603890 != nil:
    section.add "application-id", valid_603890
  var valid_603891 = path.getOrDefault("kpi-name")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = nil)
  if valid_603891 != nil:
    section.add "kpi-name", valid_603891
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-19 for July 19, 2019. To define a date range that ends at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-19T20:00Z for 8:00 PM July 19, 2019.
  ##   start-time: JString
  ##             : The first date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-15 for July 15, 2019. To define a date range that begins at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-15T16:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603892 = query.getOrDefault("end-time")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "end-time", valid_603892
  var valid_603893 = query.getOrDefault("start-time")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "start-time", valid_603893
  var valid_603894 = query.getOrDefault("next-token")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "next-token", valid_603894
  var valid_603895 = query.getOrDefault("page-size")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "page-size", valid_603895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603896 = header.getOrDefault("X-Amz-Date")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Date", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Security-Token")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Security-Token", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Content-Sha256", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Algorithm")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Algorithm", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Signature")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Signature", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-SignedHeaders", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Credential")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Credential", valid_603902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603903: Call_GetApplicationDateRangeKpi_603887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.</p>
  ## 
  let valid = call_603903.validator(path, query, header, formData, body)
  let scheme = call_603903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603903.url(scheme.get, call_603903.host, call_603903.base,
                         call_603903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603903, url, valid)

proc call*(call_603904: Call_GetApplicationDateRangeKpi_603887;
          applicationId: string; kpiName: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getApplicationDateRangeKpi
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.</p>
  ##   endTime: string
  ##          : The last date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-19 for July 19, 2019. To define a date range that ends at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-19T20:00Z for 8:00 PM July 19, 2019.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are attempted-deliveries and successful-deliveries. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   startTime: string
  ##            : The first date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-15 for July 15, 2019. To define a date range that begins at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-15T16:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603905 = newJObject()
  var query_603906 = newJObject()
  add(query_603906, "end-time", newJString(endTime))
  add(path_603905, "application-id", newJString(applicationId))
  add(path_603905, "kpi-name", newJString(kpiName))
  add(query_603906, "start-time", newJString(startTime))
  add(query_603906, "next-token", newJString(nextToken))
  add(query_603906, "page-size", newJString(pageSize))
  result = call_603904.call(path_603905, query_603906, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_603887(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_603888, base: "/",
    url: url_GetApplicationDateRangeKpi_603889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_603921 = ref object of OpenApiRestCall_602450
proc url_UpdateApplicationSettings_603923(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApplicationSettings_603922(path: JsonNode; query: JsonNode;
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
  var valid_603924 = path.getOrDefault("application-id")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = nil)
  if valid_603924 != nil:
    section.add "application-id", valid_603924
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
  var valid_603925 = header.getOrDefault("X-Amz-Date")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Date", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Security-Token")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Security-Token", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Content-Sha256", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Algorithm")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Algorithm", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Signature")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Signature", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-SignedHeaders", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Credential")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Credential", valid_603931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603933: Call_UpdateApplicationSettings_603921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_603933.validator(path, query, header, formData, body)
  let scheme = call_603933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603933.url(scheme.get, call_603933.host, call_603933.base,
                         call_603933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603933, url, valid)

proc call*(call_603934: Call_UpdateApplicationSettings_603921;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603935 = newJObject()
  var body_603936 = newJObject()
  add(path_603935, "application-id", newJString(applicationId))
  if body != nil:
    body_603936 = body
  result = call_603934.call(path_603935, nil, nil, nil, body_603936)

var updateApplicationSettings* = Call_UpdateApplicationSettings_603921(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_603922, base: "/",
    url: url_UpdateApplicationSettings_603923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_603907 = ref object of OpenApiRestCall_602450
proc url_GetApplicationSettings_603909(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetApplicationSettings_603908(path: JsonNode; query: JsonNode;
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
  var valid_603910 = path.getOrDefault("application-id")
  valid_603910 = validateParameter(valid_603910, JString, required = true,
                                 default = nil)
  if valid_603910 != nil:
    section.add "application-id", valid_603910
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
  var valid_603911 = header.getOrDefault("X-Amz-Date")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Date", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Security-Token")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Security-Token", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Content-Sha256", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Algorithm")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Algorithm", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Signature")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Signature", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-SignedHeaders", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Credential")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Credential", valid_603917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603918: Call_GetApplicationSettings_603907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_603918.validator(path, query, header, formData, body)
  let scheme = call_603918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603918.url(scheme.get, call_603918.host, call_603918.base,
                         call_603918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603918, url, valid)

proc call*(call_603919: Call_GetApplicationSettings_603907; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603920 = newJObject()
  add(path_603920, "application-id", newJString(applicationId))
  result = call_603919.call(path_603920, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_603907(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_603908, base: "/",
    url: url_GetApplicationSettings_603909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_603937 = ref object of OpenApiRestCall_602450
proc url_GetCampaignActivities_603939(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaignActivities_603938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the activity performed by a campaign.
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
  var valid_603940 = path.getOrDefault("application-id")
  valid_603940 = validateParameter(valid_603940, JString, required = true,
                                 default = nil)
  if valid_603940 != nil:
    section.add "application-id", valid_603940
  var valid_603941 = path.getOrDefault("campaign-id")
  valid_603941 = validateParameter(valid_603941, JString, required = true,
                                 default = nil)
  if valid_603941 != nil:
    section.add "campaign-id", valid_603941
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603942 = query.getOrDefault("token")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "token", valid_603942
  var valid_603943 = query.getOrDefault("page-size")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "page-size", valid_603943
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603944 = header.getOrDefault("X-Amz-Date")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Date", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Security-Token")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Security-Token", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Content-Sha256", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Algorithm")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Algorithm", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Signature")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Signature", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-SignedHeaders", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Credential")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Credential", valid_603950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603951: Call_GetCampaignActivities_603937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the activity performed by a campaign.
  ## 
  let valid = call_603951.validator(path, query, header, formData, body)
  let scheme = call_603951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603951.url(scheme.get, call_603951.host, call_603951.base,
                         call_603951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603951, url, valid)

proc call*(call_603952: Call_GetCampaignActivities_603937; applicationId: string;
          campaignId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaignActivities
  ## Retrieves information about the activity performed by a campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603953 = newJObject()
  var query_603954 = newJObject()
  add(query_603954, "token", newJString(token))
  add(path_603953, "application-id", newJString(applicationId))
  add(path_603953, "campaign-id", newJString(campaignId))
  add(query_603954, "page-size", newJString(pageSize))
  result = call_603952.call(path_603953, query_603954, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_603937(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_603938, base: "/",
    url: url_GetCampaignActivities_603939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_603955 = ref object of OpenApiRestCall_602450
proc url_GetCampaignDateRangeKpi_603957(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaignDateRangeKpi_603956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are attempted-deliveries and successful-deliveries. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `application-id` field"
  var valid_603958 = path.getOrDefault("application-id")
  valid_603958 = validateParameter(valid_603958, JString, required = true,
                                 default = nil)
  if valid_603958 != nil:
    section.add "application-id", valid_603958
  var valid_603959 = path.getOrDefault("kpi-name")
  valid_603959 = validateParameter(valid_603959, JString, required = true,
                                 default = nil)
  if valid_603959 != nil:
    section.add "kpi-name", valid_603959
  var valid_603960 = path.getOrDefault("campaign-id")
  valid_603960 = validateParameter(valid_603960, JString, required = true,
                                 default = nil)
  if valid_603960 != nil:
    section.add "campaign-id", valid_603960
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-19 for July 19, 2019. To define a date range that ends at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-19T20:00Z for 8:00 PM July 19, 2019.
  ##   start-time: JString
  ##             : The first date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-15 for July 15, 2019. To define a date range that begins at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-15T16:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603961 = query.getOrDefault("end-time")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "end-time", valid_603961
  var valid_603962 = query.getOrDefault("start-time")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "start-time", valid_603962
  var valid_603963 = query.getOrDefault("next-token")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "next-token", valid_603963
  var valid_603964 = query.getOrDefault("page-size")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "page-size", valid_603964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603965 = header.getOrDefault("X-Amz-Date")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Date", valid_603965
  var valid_603966 = header.getOrDefault("X-Amz-Security-Token")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-Security-Token", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Content-Sha256", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-Algorithm")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Algorithm", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Signature")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Signature", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-SignedHeaders", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Credential")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Credential", valid_603971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603972: Call_GetCampaignDateRangeKpi_603955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.</p>
  ## 
  let valid = call_603972.validator(path, query, header, formData, body)
  let scheme = call_603972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603972.url(scheme.get, call_603972.host, call_603972.base,
                         call_603972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603972, url, valid)

proc call*(call_603973: Call_GetCampaignDateRangeKpi_603955; applicationId: string;
          kpiName: string; campaignId: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getCampaignDateRangeKpi
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.</p>
  ##   endTime: string
  ##          : The last date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-19 for July 19, 2019. To define a date range that ends at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-19T20:00Z for 8:00 PM July 19, 2019.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are attempted-deliveries and successful-deliveries. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   startTime: string
  ##            : The first date to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in ISO 8601 format, for example: 2019-07-15 for July 15, 2019. To define a date range that begins at a specific time, specify the date and time in ISO 8601 format, for example: 2019-07-15T16:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_603974 = newJObject()
  var query_603975 = newJObject()
  add(query_603975, "end-time", newJString(endTime))
  add(path_603974, "application-id", newJString(applicationId))
  add(path_603974, "kpi-name", newJString(kpiName))
  add(query_603975, "start-time", newJString(startTime))
  add(query_603975, "next-token", newJString(nextToken))
  add(path_603974, "campaign-id", newJString(campaignId))
  add(query_603975, "page-size", newJString(pageSize))
  result = call_603973.call(path_603974, query_603975, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_603955(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_603956, base: "/",
    url: url_GetCampaignDateRangeKpi_603957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_603976 = ref object of OpenApiRestCall_602450
proc url_GetCampaignVersion_603978(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaignVersion_603977(path: JsonNode; query: JsonNode;
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
  var valid_603979 = path.getOrDefault("version")
  valid_603979 = validateParameter(valid_603979, JString, required = true,
                                 default = nil)
  if valid_603979 != nil:
    section.add "version", valid_603979
  var valid_603980 = path.getOrDefault("application-id")
  valid_603980 = validateParameter(valid_603980, JString, required = true,
                                 default = nil)
  if valid_603980 != nil:
    section.add "application-id", valid_603980
  var valid_603981 = path.getOrDefault("campaign-id")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = nil)
  if valid_603981 != nil:
    section.add "campaign-id", valid_603981
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
  var valid_603982 = header.getOrDefault("X-Amz-Date")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Date", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Security-Token")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Security-Token", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Content-Sha256", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Algorithm")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Algorithm", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Signature")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Signature", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-SignedHeaders", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Credential")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Credential", valid_603988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603989: Call_GetCampaignVersion_603976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_603989.validator(path, query, header, formData, body)
  let scheme = call_603989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603989.url(scheme.get, call_603989.host, call_603989.base,
                         call_603989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603989, url, valid)

proc call*(call_603990: Call_GetCampaignVersion_603976; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_603991 = newJObject()
  add(path_603991, "version", newJString(version))
  add(path_603991, "application-id", newJString(applicationId))
  add(path_603991, "campaign-id", newJString(campaignId))
  result = call_603990.call(path_603991, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_603976(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_603977, base: "/",
    url: url_GetCampaignVersion_603978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_603992 = ref object of OpenApiRestCall_602450
proc url_GetCampaignVersions_603994(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCampaignVersions_603993(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
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
  var valid_603995 = path.getOrDefault("application-id")
  valid_603995 = validateParameter(valid_603995, JString, required = true,
                                 default = nil)
  if valid_603995 != nil:
    section.add "application-id", valid_603995
  var valid_603996 = path.getOrDefault("campaign-id")
  valid_603996 = validateParameter(valid_603996, JString, required = true,
                                 default = nil)
  if valid_603996 != nil:
    section.add "campaign-id", valid_603996
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_603997 = query.getOrDefault("token")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "token", valid_603997
  var valid_603998 = query.getOrDefault("page-size")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "page-size", valid_603998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603999 = header.getOrDefault("X-Amz-Date")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Date", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Security-Token")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Security-Token", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Content-Sha256", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Algorithm")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Algorithm", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Signature")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Signature", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-SignedHeaders", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Credential")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Credential", valid_604005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604006: Call_GetCampaignVersions_603992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ## 
  let valid = call_604006.validator(path, query, header, formData, body)
  let scheme = call_604006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604006.url(scheme.get, call_604006.host, call_604006.base,
                         call_604006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604006, url, valid)

proc call*(call_604007: Call_GetCampaignVersions_603992; applicationId: string;
          campaignId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaignVersions
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_604008 = newJObject()
  var query_604009 = newJObject()
  add(query_604009, "token", newJString(token))
  add(path_604008, "application-id", newJString(applicationId))
  add(path_604008, "campaign-id", newJString(campaignId))
  add(query_604009, "page-size", newJString(pageSize))
  result = call_604007.call(path_604008, query_604009, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_603992(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_603993, base: "/",
    url: url_GetCampaignVersions_603994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_604010 = ref object of OpenApiRestCall_602450
proc url_GetChannels_604012(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetChannels_604011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604013 = path.getOrDefault("application-id")
  valid_604013 = validateParameter(valid_604013, JString, required = true,
                                 default = nil)
  if valid_604013 != nil:
    section.add "application-id", valid_604013
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
  var valid_604014 = header.getOrDefault("X-Amz-Date")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Date", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Security-Token")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Security-Token", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Content-Sha256", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Algorithm")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Algorithm", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Signature")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Signature", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-SignedHeaders", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Credential")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Credential", valid_604020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604021: Call_GetChannels_604010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_604021.validator(path, query, header, formData, body)
  let scheme = call_604021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604021.url(scheme.get, call_604021.host, call_604021.base,
                         call_604021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604021, url, valid)

proc call*(call_604022: Call_GetChannels_604010; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_604023 = newJObject()
  add(path_604023, "application-id", newJString(applicationId))
  result = call_604022.call(path_604023, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_604010(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_604011,
                                        base: "/", url: url_GetChannels_604012,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_604024 = ref object of OpenApiRestCall_602450
proc url_GetExportJob_604026(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetExportJob_604025(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604027 = path.getOrDefault("application-id")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = nil)
  if valid_604027 != nil:
    section.add "application-id", valid_604027
  var valid_604028 = path.getOrDefault("job-id")
  valid_604028 = validateParameter(valid_604028, JString, required = true,
                                 default = nil)
  if valid_604028 != nil:
    section.add "job-id", valid_604028
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
  var valid_604029 = header.getOrDefault("X-Amz-Date")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Date", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Security-Token")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Security-Token", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Content-Sha256", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Algorithm")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Algorithm", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Signature")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Signature", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-SignedHeaders", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Credential")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Credential", valid_604035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604036: Call_GetExportJob_604024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_604036.validator(path, query, header, formData, body)
  let scheme = call_604036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604036.url(scheme.get, call_604036.host, call_604036.base,
                         call_604036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604036, url, valid)

proc call*(call_604037: Call_GetExportJob_604024; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_604038 = newJObject()
  add(path_604038, "application-id", newJString(applicationId))
  add(path_604038, "job-id", newJString(jobId))
  result = call_604037.call(path_604038, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_604024(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_604025, base: "/", url: url_GetExportJob_604026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_604039 = ref object of OpenApiRestCall_602450
proc url_GetImportJob_604041(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetImportJob_604040(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604042 = path.getOrDefault("application-id")
  valid_604042 = validateParameter(valid_604042, JString, required = true,
                                 default = nil)
  if valid_604042 != nil:
    section.add "application-id", valid_604042
  var valid_604043 = path.getOrDefault("job-id")
  valid_604043 = validateParameter(valid_604043, JString, required = true,
                                 default = nil)
  if valid_604043 != nil:
    section.add "job-id", valid_604043
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
  var valid_604044 = header.getOrDefault("X-Amz-Date")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Date", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Security-Token")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Security-Token", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Content-Sha256", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Algorithm")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Algorithm", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Signature")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Signature", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-SignedHeaders", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Credential")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Credential", valid_604050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604051: Call_GetImportJob_604039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_604051.validator(path, query, header, formData, body)
  let scheme = call_604051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604051.url(scheme.get, call_604051.host, call_604051.base,
                         call_604051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604051, url, valid)

proc call*(call_604052: Call_GetImportJob_604039; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_604053 = newJObject()
  add(path_604053, "application-id", newJString(applicationId))
  add(path_604053, "job-id", newJString(jobId))
  result = call_604052.call(path_604053, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_604039(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_604040, base: "/", url: url_GetImportJob_604041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_604054 = ref object of OpenApiRestCall_602450
proc url_GetSegmentExportJobs_604056(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSegmentExportJobs_604055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604057 = path.getOrDefault("segment-id")
  valid_604057 = validateParameter(valid_604057, JString, required = true,
                                 default = nil)
  if valid_604057 != nil:
    section.add "segment-id", valid_604057
  var valid_604058 = path.getOrDefault("application-id")
  valid_604058 = validateParameter(valid_604058, JString, required = true,
                                 default = nil)
  if valid_604058 != nil:
    section.add "application-id", valid_604058
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_604059 = query.getOrDefault("token")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "token", valid_604059
  var valid_604060 = query.getOrDefault("page-size")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "page-size", valid_604060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604061 = header.getOrDefault("X-Amz-Date")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Date", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Security-Token")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Security-Token", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Content-Sha256", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Algorithm")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Algorithm", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Signature")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Signature", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-SignedHeaders", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Credential")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Credential", valid_604067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604068: Call_GetSegmentExportJobs_604054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_604068.validator(path, query, header, formData, body)
  let scheme = call_604068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604068.url(scheme.get, call_604068.host, call_604068.base,
                         call_604068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604068, url, valid)

proc call*(call_604069: Call_GetSegmentExportJobs_604054; segmentId: string;
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
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_604070 = newJObject()
  var query_604071 = newJObject()
  add(query_604071, "token", newJString(token))
  add(path_604070, "segment-id", newJString(segmentId))
  add(path_604070, "application-id", newJString(applicationId))
  add(query_604071, "page-size", newJString(pageSize))
  result = call_604069.call(path_604070, query_604071, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_604054(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_604055, base: "/",
    url: url_GetSegmentExportJobs_604056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_604072 = ref object of OpenApiRestCall_602450
proc url_GetSegmentImportJobs_604074(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSegmentImportJobs_604073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604075 = path.getOrDefault("segment-id")
  valid_604075 = validateParameter(valid_604075, JString, required = true,
                                 default = nil)
  if valid_604075 != nil:
    section.add "segment-id", valid_604075
  var valid_604076 = path.getOrDefault("application-id")
  valid_604076 = validateParameter(valid_604076, JString, required = true,
                                 default = nil)
  if valid_604076 != nil:
    section.add "application-id", valid_604076
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_604077 = query.getOrDefault("token")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "token", valid_604077
  var valid_604078 = query.getOrDefault("page-size")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "page-size", valid_604078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604079 = header.getOrDefault("X-Amz-Date")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Date", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Security-Token")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Security-Token", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Content-Sha256", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Algorithm")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Algorithm", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Signature")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Signature", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-SignedHeaders", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Credential")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Credential", valid_604085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604086: Call_GetSegmentImportJobs_604072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_604086.validator(path, query, header, formData, body)
  let scheme = call_604086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604086.url(scheme.get, call_604086.host, call_604086.base,
                         call_604086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604086, url, valid)

proc call*(call_604087: Call_GetSegmentImportJobs_604072; segmentId: string;
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
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_604088 = newJObject()
  var query_604089 = newJObject()
  add(query_604089, "token", newJString(token))
  add(path_604088, "segment-id", newJString(segmentId))
  add(path_604088, "application-id", newJString(applicationId))
  add(query_604089, "page-size", newJString(pageSize))
  result = call_604087.call(path_604088, query_604089, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_604072(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_604073, base: "/",
    url: url_GetSegmentImportJobs_604074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_604090 = ref object of OpenApiRestCall_602450
proc url_GetSegmentVersion_604092(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSegmentVersion_604091(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_604093 = path.getOrDefault("segment-id")
  valid_604093 = validateParameter(valid_604093, JString, required = true,
                                 default = nil)
  if valid_604093 != nil:
    section.add "segment-id", valid_604093
  var valid_604094 = path.getOrDefault("version")
  valid_604094 = validateParameter(valid_604094, JString, required = true,
                                 default = nil)
  if valid_604094 != nil:
    section.add "version", valid_604094
  var valid_604095 = path.getOrDefault("application-id")
  valid_604095 = validateParameter(valid_604095, JString, required = true,
                                 default = nil)
  if valid_604095 != nil:
    section.add "application-id", valid_604095
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
  var valid_604096 = header.getOrDefault("X-Amz-Date")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Date", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Security-Token")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Security-Token", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Content-Sha256", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Algorithm")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Algorithm", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Signature")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Signature", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-SignedHeaders", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Credential")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Credential", valid_604102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604103: Call_GetSegmentVersion_604090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_604103.validator(path, query, header, formData, body)
  let scheme = call_604103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604103.url(scheme.get, call_604103.host, call_604103.base,
                         call_604103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604103, url, valid)

proc call*(call_604104: Call_GetSegmentVersion_604090; segmentId: string;
          version: string; applicationId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_604105 = newJObject()
  add(path_604105, "segment-id", newJString(segmentId))
  add(path_604105, "version", newJString(version))
  add(path_604105, "application-id", newJString(applicationId))
  result = call_604104.call(path_604105, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_604090(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_604091, base: "/",
    url: url_GetSegmentVersion_604092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_604106 = ref object of OpenApiRestCall_602450
proc url_GetSegmentVersions_604108(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSegmentVersions_604107(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
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
  var valid_604109 = path.getOrDefault("segment-id")
  valid_604109 = validateParameter(valid_604109, JString, required = true,
                                 default = nil)
  if valid_604109 != nil:
    section.add "segment-id", valid_604109
  var valid_604110 = path.getOrDefault("application-id")
  valid_604110 = validateParameter(valid_604110, JString, required = true,
                                 default = nil)
  if valid_604110 != nil:
    section.add "application-id", valid_604110
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_604111 = query.getOrDefault("token")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "token", valid_604111
  var valid_604112 = query.getOrDefault("page-size")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "page-size", valid_604112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604113 = header.getOrDefault("X-Amz-Date")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Date", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Security-Token")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Security-Token", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Content-Sha256", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Algorithm")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Algorithm", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Signature")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Signature", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-SignedHeaders", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Credential")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Credential", valid_604119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604120: Call_GetSegmentVersions_604106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_604120.validator(path, query, header, formData, body)
  let scheme = call_604120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604120.url(scheme.get, call_604120.host, call_604120.base,
                         call_604120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604120, url, valid)

proc call*(call_604121: Call_GetSegmentVersions_604106; segmentId: string;
          applicationId: string; token: string = ""; pageSize: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_604122 = newJObject()
  var query_604123 = newJObject()
  add(query_604123, "token", newJString(token))
  add(path_604122, "segment-id", newJString(segmentId))
  add(path_604122, "application-id", newJString(applicationId))
  add(query_604123, "page-size", newJString(pageSize))
  result = call_604121.call(path_604122, query_604123, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_604106(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_604107, base: "/",
    url: url_GetSegmentVersions_604108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604138 = ref object of OpenApiRestCall_602450
proc url_TagResource_604140(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_604139(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_604141 = path.getOrDefault("resource-arn")
  valid_604141 = validateParameter(valid_604141, JString, required = true,
                                 default = nil)
  if valid_604141 != nil:
    section.add "resource-arn", valid_604141
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
  var valid_604142 = header.getOrDefault("X-Amz-Date")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Date", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Security-Token")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Security-Token", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Content-Sha256", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Algorithm")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Algorithm", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Signature")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Signature", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-SignedHeaders", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Credential")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Credential", valid_604148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604150: Call_TagResource_604138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ## 
  let valid = call_604150.validator(path, query, header, formData, body)
  let scheme = call_604150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604150.url(scheme.get, call_604150.host, call_604150.base,
                         call_604150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604150, url, valid)

proc call*(call_604151: Call_TagResource_604138; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  ##   body: JObject (required)
  var path_604152 = newJObject()
  var body_604153 = newJObject()
  add(path_604152, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_604153 = body
  result = call_604151.call(path_604152, nil, nil, nil, body_604153)

var tagResource* = Call_TagResource_604138(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_604139,
                                        base: "/", url: url_TagResource_604140,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_604124 = ref object of OpenApiRestCall_602450
proc url_ListTagsForResource_604126(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_604125(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_604127 = path.getOrDefault("resource-arn")
  valid_604127 = validateParameter(valid_604127, JString, required = true,
                                 default = nil)
  if valid_604127 != nil:
    section.add "resource-arn", valid_604127
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
  var valid_604128 = header.getOrDefault("X-Amz-Date")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Date", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Security-Token")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Security-Token", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Content-Sha256", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Algorithm")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Algorithm", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Signature")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Signature", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-SignedHeaders", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Credential")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Credential", valid_604134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604135: Call_ListTagsForResource_604124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ## 
  let valid = call_604135.validator(path, query, header, formData, body)
  let scheme = call_604135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604135.url(scheme.get, call_604135.host, call_604135.base,
                         call_604135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604135, url, valid)

proc call*(call_604136: Call_ListTagsForResource_604124; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_604137 = newJObject()
  add(path_604137, "resource-arn", newJString(resourceArn))
  result = call_604136.call(path_604137, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_604124(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_604125, base: "/",
    url: url_ListTagsForResource_604126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_604154 = ref object of OpenApiRestCall_602450
proc url_PhoneNumberValidate_604156(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PhoneNumberValidate_604155(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604157 = header.getOrDefault("X-Amz-Date")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Date", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Security-Token")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Security-Token", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Content-Sha256", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Algorithm")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Algorithm", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Signature")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Signature", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-SignedHeaders", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Credential")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Credential", valid_604163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604165: Call_PhoneNumberValidate_604154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_604165.validator(path, query, header, formData, body)
  let scheme = call_604165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604165.url(scheme.get, call_604165.host, call_604165.base,
                         call_604165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604165, url, valid)

proc call*(call_604166: Call_PhoneNumberValidate_604154; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_604167 = newJObject()
  if body != nil:
    body_604167 = body
  result = call_604166.call(nil, nil, nil, nil, body_604167)

var phoneNumberValidate* = Call_PhoneNumberValidate_604154(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_604155, base: "/",
    url: url_PhoneNumberValidate_604156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_604168 = ref object of OpenApiRestCall_602450
proc url_PutEvents_604170(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_PutEvents_604169(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604171 = path.getOrDefault("application-id")
  valid_604171 = validateParameter(valid_604171, JString, required = true,
                                 default = nil)
  if valid_604171 != nil:
    section.add "application-id", valid_604171
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
  var valid_604172 = header.getOrDefault("X-Amz-Date")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Date", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Security-Token")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Security-Token", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Content-Sha256", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Algorithm")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Algorithm", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Signature")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Signature", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-SignedHeaders", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Credential")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Credential", valid_604178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604180: Call_PutEvents_604168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_604180.validator(path, query, header, formData, body)
  let scheme = call_604180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604180.url(scheme.get, call_604180.host, call_604180.base,
                         call_604180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604180, url, valid)

proc call*(call_604181: Call_PutEvents_604168; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_604182 = newJObject()
  var body_604183 = newJObject()
  add(path_604182, "application-id", newJString(applicationId))
  if body != nil:
    body_604183 = body
  result = call_604181.call(path_604182, nil, nil, nil, body_604183)

var putEvents* = Call_PutEvents_604168(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_604169,
                                    base: "/", url: url_PutEvents_604170,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_604184 = ref object of OpenApiRestCall_602450
proc url_RemoveAttributes_604186(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RemoveAttributes_604185(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   attribute-type: JString (required)
  ##                 :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-custom-metrics - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `attribute-type` field"
  var valid_604187 = path.getOrDefault("attribute-type")
  valid_604187 = validateParameter(valid_604187, JString, required = true,
                                 default = nil)
  if valid_604187 != nil:
    section.add "attribute-type", valid_604187
  var valid_604188 = path.getOrDefault("application-id")
  valid_604188 = validateParameter(valid_604188, JString, required = true,
                                 default = nil)
  if valid_604188 != nil:
    section.add "application-id", valid_604188
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
  var valid_604189 = header.getOrDefault("X-Amz-Date")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Date", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Security-Token")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Security-Token", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Content-Sha256", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Algorithm")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Algorithm", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Signature")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Signature", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-SignedHeaders", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Credential")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Credential", valid_604195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604197: Call_RemoveAttributes_604184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_604197.validator(path, query, header, formData, body)
  let scheme = call_604197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604197.url(scheme.get, call_604197.host, call_604197.base,
                         call_604197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604197, url, valid)

proc call*(call_604198: Call_RemoveAttributes_604184; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-custom-metrics - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_604199 = newJObject()
  var body_604200 = newJObject()
  add(path_604199, "attribute-type", newJString(attributeType))
  add(path_604199, "application-id", newJString(applicationId))
  if body != nil:
    body_604200 = body
  result = call_604198.call(path_604199, nil, nil, nil, body_604200)

var removeAttributes* = Call_RemoveAttributes_604184(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_604185, base: "/",
    url: url_RemoveAttributes_604186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_604201 = ref object of OpenApiRestCall_602450
proc url_SendMessages_604203(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_SendMessages_604202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604204 = path.getOrDefault("application-id")
  valid_604204 = validateParameter(valid_604204, JString, required = true,
                                 default = nil)
  if valid_604204 != nil:
    section.add "application-id", valid_604204
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
  var valid_604205 = header.getOrDefault("X-Amz-Date")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Date", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-Security-Token")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Security-Token", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Content-Sha256", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Algorithm")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Algorithm", valid_604208
  var valid_604209 = header.getOrDefault("X-Amz-Signature")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Signature", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-SignedHeaders", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Credential")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Credential", valid_604211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604213: Call_SendMessages_604201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_604213.validator(path, query, header, formData, body)
  let scheme = call_604213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604213.url(scheme.get, call_604213.host, call_604213.base,
                         call_604213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604213, url, valid)

proc call*(call_604214: Call_SendMessages_604201; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_604215 = newJObject()
  var body_604216 = newJObject()
  add(path_604215, "application-id", newJString(applicationId))
  if body != nil:
    body_604216 = body
  result = call_604214.call(path_604215, nil, nil, nil, body_604216)

var sendMessages* = Call_SendMessages_604201(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_604202,
    base: "/", url: url_SendMessages_604203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_604217 = ref object of OpenApiRestCall_602450
proc url_SendUsersMessages_604219(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_SendUsersMessages_604218(path: JsonNode; query: JsonNode;
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
  var valid_604220 = path.getOrDefault("application-id")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = nil)
  if valid_604220 != nil:
    section.add "application-id", valid_604220
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
  var valid_604221 = header.getOrDefault("X-Amz-Date")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "X-Amz-Date", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-Security-Token")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Security-Token", valid_604222
  var valid_604223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Content-Sha256", valid_604223
  var valid_604224 = header.getOrDefault("X-Amz-Algorithm")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Algorithm", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Signature")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Signature", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-SignedHeaders", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Credential")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Credential", valid_604227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604229: Call_SendUsersMessages_604217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_604229.validator(path, query, header, formData, body)
  let scheme = call_604229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604229.url(scheme.get, call_604229.host, call_604229.base,
                         call_604229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604229, url, valid)

proc call*(call_604230: Call_SendUsersMessages_604217; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_604231 = newJObject()
  var body_604232 = newJObject()
  add(path_604231, "application-id", newJString(applicationId))
  if body != nil:
    body_604232 = body
  result = call_604230.call(path_604231, nil, nil, nil, body_604232)

var sendUsersMessages* = Call_SendUsersMessages_604217(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_604218, base: "/",
    url: url_SendUsersMessages_604219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604233 = ref object of OpenApiRestCall_602450
proc url_UntagResource_604235(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_604234(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_604236 = path.getOrDefault("resource-arn")
  valid_604236 = validateParameter(valid_604236, JString, required = true,
                                 default = nil)
  if valid_604236 != nil:
    section.add "resource-arn", valid_604236
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_604237 = query.getOrDefault("tagKeys")
  valid_604237 = validateParameter(valid_604237, JArray, required = true, default = nil)
  if valid_604237 != nil:
    section.add "tagKeys", valid_604237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604238 = header.getOrDefault("X-Amz-Date")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Date", valid_604238
  var valid_604239 = header.getOrDefault("X-Amz-Security-Token")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-Security-Token", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Content-Sha256", valid_604240
  var valid_604241 = header.getOrDefault("X-Amz-Algorithm")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "X-Amz-Algorithm", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Signature")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Signature", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-SignedHeaders", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Credential")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Credential", valid_604244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604245: Call_UntagResource_604233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ## 
  let valid = call_604245.validator(path, query, header, formData, body)
  let scheme = call_604245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604245.url(scheme.get, call_604245.host, call_604245.base,
                         call_604245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604245, url, valid)

proc call*(call_604246: Call_UntagResource_604233; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_604247 = newJObject()
  var query_604248 = newJObject()
  if tagKeys != nil:
    query_604248.add "tagKeys", tagKeys
  add(path_604247, "resource-arn", newJString(resourceArn))
  result = call_604246.call(path_604247, query_604248, nil, nil, nil)

var untagResource* = Call_UntagResource_604233(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_604234,
    base: "/", url: url_UntagResource_604235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_604249 = ref object of OpenApiRestCall_602450
proc url_UpdateEndpointsBatch_604251(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateEndpointsBatch_604250(path: JsonNode; query: JsonNode;
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
  var valid_604252 = path.getOrDefault("application-id")
  valid_604252 = validateParameter(valid_604252, JString, required = true,
                                 default = nil)
  if valid_604252 != nil:
    section.add "application-id", valid_604252
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
  var valid_604253 = header.getOrDefault("X-Amz-Date")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Date", valid_604253
  var valid_604254 = header.getOrDefault("X-Amz-Security-Token")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "X-Amz-Security-Token", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Content-Sha256", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Algorithm")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Algorithm", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Signature")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Signature", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-SignedHeaders", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Credential")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Credential", valid_604259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604261: Call_UpdateEndpointsBatch_604249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_604261.validator(path, query, header, formData, body)
  let scheme = call_604261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604261.url(scheme.get, call_604261.host, call_604261.base,
                         call_604261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604261, url, valid)

proc call*(call_604262: Call_UpdateEndpointsBatch_604249; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_604263 = newJObject()
  var body_604264 = newJObject()
  add(path_604263, "application-id", newJString(applicationId))
  if body != nil:
    body_604264 = body
  result = call_604262.call(path_604263, nil, nil, nil, body_604264)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_604249(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_604250, base: "/",
    url: url_UpdateEndpointsBatch_604251, schemes: {Scheme.Https, Scheme.Http})
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
