
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_CreateApp_599946 = ref object of OpenApiRestCall_599352
proc url_CreateApp_599948(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_599947(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599949 = header.getOrDefault("X-Amz-Date")
  valid_599949 = validateParameter(valid_599949, JString, required = false,
                                 default = nil)
  if valid_599949 != nil:
    section.add "X-Amz-Date", valid_599949
  var valid_599950 = header.getOrDefault("X-Amz-Security-Token")
  valid_599950 = validateParameter(valid_599950, JString, required = false,
                                 default = nil)
  if valid_599950 != nil:
    section.add "X-Amz-Security-Token", valid_599950
  var valid_599951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599951 = validateParameter(valid_599951, JString, required = false,
                                 default = nil)
  if valid_599951 != nil:
    section.add "X-Amz-Content-Sha256", valid_599951
  var valid_599952 = header.getOrDefault("X-Amz-Algorithm")
  valid_599952 = validateParameter(valid_599952, JString, required = false,
                                 default = nil)
  if valid_599952 != nil:
    section.add "X-Amz-Algorithm", valid_599952
  var valid_599953 = header.getOrDefault("X-Amz-Signature")
  valid_599953 = validateParameter(valid_599953, JString, required = false,
                                 default = nil)
  if valid_599953 != nil:
    section.add "X-Amz-Signature", valid_599953
  var valid_599954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599954 = validateParameter(valid_599954, JString, required = false,
                                 default = nil)
  if valid_599954 != nil:
    section.add "X-Amz-SignedHeaders", valid_599954
  var valid_599955 = header.getOrDefault("X-Amz-Credential")
  valid_599955 = validateParameter(valid_599955, JString, required = false,
                                 default = nil)
  if valid_599955 != nil:
    section.add "X-Amz-Credential", valid_599955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599957: Call_CreateApp_599946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_599957.validator(path, query, header, formData, body)
  let scheme = call_599957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599957.url(scheme.get, call_599957.host, call_599957.base,
                         call_599957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599957, url, valid)

proc call*(call_599958: Call_CreateApp_599946; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_599959 = newJObject()
  if body != nil:
    body_599959 = body
  result = call_599958.call(nil, nil, nil, nil, body_599959)

var createApp* = Call_CreateApp_599946(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_599947,
                                    base: "/", url: url_CreateApp_599948,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_599689 = ref object of OpenApiRestCall_599352
proc url_GetApps_599691(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApps_599690(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_599803 = query.getOrDefault("token")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "token", valid_599803
  var valid_599804 = query.getOrDefault("page-size")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "page-size", valid_599804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599805 = header.getOrDefault("X-Amz-Date")
  valid_599805 = validateParameter(valid_599805, JString, required = false,
                                 default = nil)
  if valid_599805 != nil:
    section.add "X-Amz-Date", valid_599805
  var valid_599806 = header.getOrDefault("X-Amz-Security-Token")
  valid_599806 = validateParameter(valid_599806, JString, required = false,
                                 default = nil)
  if valid_599806 != nil:
    section.add "X-Amz-Security-Token", valid_599806
  var valid_599807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599807 = validateParameter(valid_599807, JString, required = false,
                                 default = nil)
  if valid_599807 != nil:
    section.add "X-Amz-Content-Sha256", valid_599807
  var valid_599808 = header.getOrDefault("X-Amz-Algorithm")
  valid_599808 = validateParameter(valid_599808, JString, required = false,
                                 default = nil)
  if valid_599808 != nil:
    section.add "X-Amz-Algorithm", valid_599808
  var valid_599809 = header.getOrDefault("X-Amz-Signature")
  valid_599809 = validateParameter(valid_599809, JString, required = false,
                                 default = nil)
  if valid_599809 != nil:
    section.add "X-Amz-Signature", valid_599809
  var valid_599810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-SignedHeaders", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Credential")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Credential", valid_599811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599834: Call_GetApps_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_599834.validator(path, query, header, formData, body)
  let scheme = call_599834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599834.url(scheme.get, call_599834.host, call_599834.base,
                         call_599834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599834, url, valid)

proc call*(call_599905: Call_GetApps_599689; token: string = ""; pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_599906 = newJObject()
  add(query_599906, "token", newJString(token))
  add(query_599906, "page-size", newJString(pageSize))
  result = call_599905.call(nil, query_599906, nil, nil, nil)

var getApps* = Call_GetApps_599689(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_599690, base: "/",
                                url: url_GetApps_599691,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_599991 = ref object of OpenApiRestCall_599352
proc url_CreateCampaign_599993(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_599992(path: JsonNode; query: JsonNode;
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
  var valid_599994 = path.getOrDefault("application-id")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "application-id", valid_599994
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599995 = header.getOrDefault("X-Amz-Date")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Date", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Security-Token")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Security-Token", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Content-Sha256", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Algorithm")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Algorithm", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Signature")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Signature", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-SignedHeaders", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Credential")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Credential", valid_600001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600003: Call_CreateCampaign_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_600003.validator(path, query, header, formData, body)
  let scheme = call_600003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600003.url(scheme.get, call_600003.host, call_600003.base,
                         call_600003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600003, url, valid)

proc call*(call_600004: Call_CreateCampaign_599991; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600005 = newJObject()
  var body_600006 = newJObject()
  add(path_600005, "application-id", newJString(applicationId))
  if body != nil:
    body_600006 = body
  result = call_600004.call(path_600005, nil, nil, nil, body_600006)

var createCampaign* = Call_CreateCampaign_599991(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_599992, base: "/", url: url_CreateCampaign_599993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_599960 = ref object of OpenApiRestCall_599352
proc url_GetCampaigns_599962(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_599961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599977 = path.getOrDefault("application-id")
  valid_599977 = validateParameter(valid_599977, JString, required = true,
                                 default = nil)
  if valid_599977 != nil:
    section.add "application-id", valid_599977
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_599978 = query.getOrDefault("token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "token", valid_599978
  var valid_599979 = query.getOrDefault("page-size")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "page-size", valid_599979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599980 = header.getOrDefault("X-Amz-Date")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Date", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Security-Token")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Security-Token", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Content-Sha256", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Algorithm")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Algorithm", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Signature")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Signature", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-SignedHeaders", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Credential")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Credential", valid_599986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_GetCampaigns_599960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_GetCampaigns_599960; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_599989 = newJObject()
  var query_599990 = newJObject()
  add(query_599990, "token", newJString(token))
  add(path_599989, "application-id", newJString(applicationId))
  add(query_599990, "page-size", newJString(pageSize))
  result = call_599988.call(path_599989, query_599990, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_599960(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_599961, base: "/", url: url_GetCampaigns_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_600021 = ref object of OpenApiRestCall_599352
proc url_UpdateEmailTemplate_600023(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_600022(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600024 = path.getOrDefault("template-name")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = nil)
  if valid_600024 != nil:
    section.add "template-name", valid_600024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600025 = header.getOrDefault("X-Amz-Date")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Date", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Security-Token")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Security-Token", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Content-Sha256", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Algorithm")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Algorithm", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Signature")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Signature", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-SignedHeaders", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Credential")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Credential", valid_600031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600033: Call_UpdateEmailTemplate_600021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_600033.validator(path, query, header, formData, body)
  let scheme = call_600033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600033.url(scheme.get, call_600033.host, call_600033.base,
                         call_600033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600033, url, valid)

proc call*(call_600034: Call_UpdateEmailTemplate_600021; templateName: string;
          body: JsonNode): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600035 = newJObject()
  var body_600036 = newJObject()
  add(path_600035, "template-name", newJString(templateName))
  if body != nil:
    body_600036 = body
  result = call_600034.call(path_600035, nil, nil, nil, body_600036)

var updateEmailTemplate* = Call_UpdateEmailTemplate_600021(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_600022, base: "/",
    url: url_UpdateEmailTemplate_600023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_600037 = ref object of OpenApiRestCall_599352
proc url_CreateEmailTemplate_600039(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_600038(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600040 = path.getOrDefault("template-name")
  valid_600040 = validateParameter(valid_600040, JString, required = true,
                                 default = nil)
  if valid_600040 != nil:
    section.add "template-name", valid_600040
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600041 = header.getOrDefault("X-Amz-Date")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Date", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Security-Token")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Security-Token", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Content-Sha256", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Algorithm")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Algorithm", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Signature")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Signature", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-SignedHeaders", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Credential")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Credential", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600049: Call_CreateEmailTemplate_600037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_600049.validator(path, query, header, formData, body)
  let scheme = call_600049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600049.url(scheme.get, call_600049.host, call_600049.base,
                         call_600049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600049, url, valid)

proc call*(call_600050: Call_CreateEmailTemplate_600037; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600051 = newJObject()
  var body_600052 = newJObject()
  add(path_600051, "template-name", newJString(templateName))
  if body != nil:
    body_600052 = body
  result = call_600050.call(path_600051, nil, nil, nil, body_600052)

var createEmailTemplate* = Call_CreateEmailTemplate_600037(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_600038, base: "/",
    url: url_CreateEmailTemplate_600039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_600007 = ref object of OpenApiRestCall_599352
proc url_GetEmailTemplate_600009(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_600008(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600010 = path.getOrDefault("template-name")
  valid_600010 = validateParameter(valid_600010, JString, required = true,
                                 default = nil)
  if valid_600010 != nil:
    section.add "template-name", valid_600010
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600011 = header.getOrDefault("X-Amz-Date")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Date", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Security-Token")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Security-Token", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Content-Sha256", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Algorithm")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Algorithm", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Signature")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Signature", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-SignedHeaders", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Credential")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Credential", valid_600017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600018: Call_GetEmailTemplate_600007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_600018.validator(path, query, header, formData, body)
  let scheme = call_600018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600018.url(scheme.get, call_600018.host, call_600018.base,
                         call_600018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600018, url, valid)

proc call*(call_600019: Call_GetEmailTemplate_600007; templateName: string): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600020 = newJObject()
  add(path_600020, "template-name", newJString(templateName))
  result = call_600019.call(path_600020, nil, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_600007(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_600008, base: "/",
    url: url_GetEmailTemplate_600009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_600053 = ref object of OpenApiRestCall_599352
proc url_DeleteEmailTemplate_600055(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_600054(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600056 = path.getOrDefault("template-name")
  valid_600056 = validateParameter(valid_600056, JString, required = true,
                                 default = nil)
  if valid_600056 != nil:
    section.add "template-name", valid_600056
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600057 = header.getOrDefault("X-Amz-Date")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Date", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Security-Token")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Security-Token", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Content-Sha256", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Algorithm")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Algorithm", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Signature")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Signature", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-SignedHeaders", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Credential")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Credential", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600064: Call_DeleteEmailTemplate_600053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ## 
  let valid = call_600064.validator(path, query, header, formData, body)
  let scheme = call_600064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600064.url(scheme.get, call_600064.host, call_600064.base,
                         call_600064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600064, url, valid)

proc call*(call_600065: Call_DeleteEmailTemplate_600053; templateName: string): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600066 = newJObject()
  add(path_600066, "template-name", newJString(templateName))
  result = call_600065.call(path_600066, nil, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_600053(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_600054, base: "/",
    url: url_DeleteEmailTemplate_600055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_600084 = ref object of OpenApiRestCall_599352
proc url_CreateExportJob_600086(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_600085(path: JsonNode; query: JsonNode;
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
  var valid_600087 = path.getOrDefault("application-id")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = nil)
  if valid_600087 != nil:
    section.add "application-id", valid_600087
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600088 = header.getOrDefault("X-Amz-Date")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Date", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Security-Token")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Security-Token", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Content-Sha256", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Algorithm")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Algorithm", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Signature", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-SignedHeaders", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Credential")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Credential", valid_600094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600096: Call_CreateExportJob_600084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_600096.validator(path, query, header, formData, body)
  let scheme = call_600096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600096.url(scheme.get, call_600096.host, call_600096.base,
                         call_600096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600096, url, valid)

proc call*(call_600097: Call_CreateExportJob_600084; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600098 = newJObject()
  var body_600099 = newJObject()
  add(path_600098, "application-id", newJString(applicationId))
  if body != nil:
    body_600099 = body
  result = call_600097.call(path_600098, nil, nil, nil, body_600099)

var createExportJob* = Call_CreateExportJob_600084(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_600085, base: "/", url: url_CreateExportJob_600086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_600067 = ref object of OpenApiRestCall_599352
proc url_GetExportJobs_600069(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_600068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600070 = path.getOrDefault("application-id")
  valid_600070 = validateParameter(valid_600070, JString, required = true,
                                 default = nil)
  if valid_600070 != nil:
    section.add "application-id", valid_600070
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_600071 = query.getOrDefault("token")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "token", valid_600071
  var valid_600072 = query.getOrDefault("page-size")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "page-size", valid_600072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600073 = header.getOrDefault("X-Amz-Date")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Date", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Security-Token")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Security-Token", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Content-Sha256", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Algorithm")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Algorithm", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Signature")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Signature", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-SignedHeaders", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Credential")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Credential", valid_600079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600080: Call_GetExportJobs_600067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_600080.validator(path, query, header, formData, body)
  let scheme = call_600080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600080.url(scheme.get, call_600080.host, call_600080.base,
                         call_600080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600080, url, valid)

proc call*(call_600081: Call_GetExportJobs_600067; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_600082 = newJObject()
  var query_600083 = newJObject()
  add(query_600083, "token", newJString(token))
  add(path_600082, "application-id", newJString(applicationId))
  add(query_600083, "page-size", newJString(pageSize))
  result = call_600081.call(path_600082, query_600083, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_600067(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_600068, base: "/", url: url_GetExportJobs_600069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_600117 = ref object of OpenApiRestCall_599352
proc url_CreateImportJob_600119(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_600118(path: JsonNode; query: JsonNode;
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
  var valid_600120 = path.getOrDefault("application-id")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "application-id", valid_600120
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600121 = header.getOrDefault("X-Amz-Date")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Date", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Security-Token")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Security-Token", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Content-Sha256", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Algorithm")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Algorithm", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Signature")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Signature", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-SignedHeaders", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Credential")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Credential", valid_600127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600129: Call_CreateImportJob_600117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_600129.validator(path, query, header, formData, body)
  let scheme = call_600129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600129.url(scheme.get, call_600129.host, call_600129.base,
                         call_600129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600129, url, valid)

proc call*(call_600130: Call_CreateImportJob_600117; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600131 = newJObject()
  var body_600132 = newJObject()
  add(path_600131, "application-id", newJString(applicationId))
  if body != nil:
    body_600132 = body
  result = call_600130.call(path_600131, nil, nil, nil, body_600132)

var createImportJob* = Call_CreateImportJob_600117(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_600118, base: "/", url: url_CreateImportJob_600119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_600100 = ref object of OpenApiRestCall_599352
proc url_GetImportJobs_600102(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_600101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600103 = path.getOrDefault("application-id")
  valid_600103 = validateParameter(valid_600103, JString, required = true,
                                 default = nil)
  if valid_600103 != nil:
    section.add "application-id", valid_600103
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_600104 = query.getOrDefault("token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "token", valid_600104
  var valid_600105 = query.getOrDefault("page-size")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "page-size", valid_600105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600106 = header.getOrDefault("X-Amz-Date")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Date", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Security-Token")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Security-Token", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Content-Sha256", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Algorithm")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Algorithm", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Signature")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Signature", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-SignedHeaders", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Credential")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Credential", valid_600112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600113: Call_GetImportJobs_600100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_600113.validator(path, query, header, formData, body)
  let scheme = call_600113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600113.url(scheme.get, call_600113.host, call_600113.base,
                         call_600113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600113, url, valid)

proc call*(call_600114: Call_GetImportJobs_600100; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_600115 = newJObject()
  var query_600116 = newJObject()
  add(query_600116, "token", newJString(token))
  add(path_600115, "application-id", newJString(applicationId))
  add(query_600116, "page-size", newJString(pageSize))
  result = call_600114.call(path_600115, query_600116, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_600100(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_600101, base: "/", url: url_GetImportJobs_600102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_600150 = ref object of OpenApiRestCall_599352
proc url_CreateJourney_600152(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_600151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600153 = path.getOrDefault("application-id")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = nil)
  if valid_600153 != nil:
    section.add "application-id", valid_600153
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600154 = header.getOrDefault("X-Amz-Date")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Date", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Security-Token")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Security-Token", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Content-Sha256", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Algorithm")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Algorithm", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Signature")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Signature", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-SignedHeaders", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Credential")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Credential", valid_600160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600162: Call_CreateJourney_600150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_600162.validator(path, query, header, formData, body)
  let scheme = call_600162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600162.url(scheme.get, call_600162.host, call_600162.base,
                         call_600162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600162, url, valid)

proc call*(call_600163: Call_CreateJourney_600150; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600164 = newJObject()
  var body_600165 = newJObject()
  add(path_600164, "application-id", newJString(applicationId))
  if body != nil:
    body_600165 = body
  result = call_600163.call(path_600164, nil, nil, nil, body_600165)

var createJourney* = Call_CreateJourney_600150(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_600151, base: "/", url: url_CreateJourney_600152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_600133 = ref object of OpenApiRestCall_599352
proc url_ListJourneys_600135(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_600134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600136 = path.getOrDefault("application-id")
  valid_600136 = validateParameter(valid_600136, JString, required = true,
                                 default = nil)
  if valid_600136 != nil:
    section.add "application-id", valid_600136
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_600137 = query.getOrDefault("token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "token", valid_600137
  var valid_600138 = query.getOrDefault("page-size")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "page-size", valid_600138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600139 = header.getOrDefault("X-Amz-Date")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Date", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Security-Token")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Security-Token", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Content-Sha256", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Algorithm")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Algorithm", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Signature")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Signature", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-SignedHeaders", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Credential")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Credential", valid_600145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600146: Call_ListJourneys_600133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_600146.validator(path, query, header, formData, body)
  let scheme = call_600146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600146.url(scheme.get, call_600146.host, call_600146.base,
                         call_600146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600146, url, valid)

proc call*(call_600147: Call_ListJourneys_600133; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_600148 = newJObject()
  var query_600149 = newJObject()
  add(query_600149, "token", newJString(token))
  add(path_600148, "application-id", newJString(applicationId))
  add(query_600149, "page-size", newJString(pageSize))
  result = call_600147.call(path_600148, query_600149, nil, nil, nil)

var listJourneys* = Call_ListJourneys_600133(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_600134,
    base: "/", url: url_ListJourneys_600135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_600180 = ref object of OpenApiRestCall_599352
proc url_UpdatePushTemplate_600182(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_600181(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600183 = path.getOrDefault("template-name")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = nil)
  if valid_600183 != nil:
    section.add "template-name", valid_600183
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600184 = header.getOrDefault("X-Amz-Date")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Date", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Security-Token")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Security-Token", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Content-Sha256", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Algorithm")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Algorithm", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Signature")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Signature", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-SignedHeaders", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Credential")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Credential", valid_600190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600192: Call_UpdatePushTemplate_600180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_600192.validator(path, query, header, formData, body)
  let scheme = call_600192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600192.url(scheme.get, call_600192.host, call_600192.base,
                         call_600192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600192, url, valid)

proc call*(call_600193: Call_UpdatePushTemplate_600180; templateName: string;
          body: JsonNode): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600194 = newJObject()
  var body_600195 = newJObject()
  add(path_600194, "template-name", newJString(templateName))
  if body != nil:
    body_600195 = body
  result = call_600193.call(path_600194, nil, nil, nil, body_600195)

var updatePushTemplate* = Call_UpdatePushTemplate_600180(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_600181, base: "/",
    url: url_UpdatePushTemplate_600182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_600196 = ref object of OpenApiRestCall_599352
proc url_CreatePushTemplate_600198(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_600197(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600199 = path.getOrDefault("template-name")
  valid_600199 = validateParameter(valid_600199, JString, required = true,
                                 default = nil)
  if valid_600199 != nil:
    section.add "template-name", valid_600199
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600200 = header.getOrDefault("X-Amz-Date")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Date", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Security-Token")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Security-Token", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Content-Sha256", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Algorithm")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Algorithm", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Signature")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Signature", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-SignedHeaders", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Credential")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Credential", valid_600206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600208: Call_CreatePushTemplate_600196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_600208.validator(path, query, header, formData, body)
  let scheme = call_600208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600208.url(scheme.get, call_600208.host, call_600208.base,
                         call_600208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600208, url, valid)

proc call*(call_600209: Call_CreatePushTemplate_600196; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600210 = newJObject()
  var body_600211 = newJObject()
  add(path_600210, "template-name", newJString(templateName))
  if body != nil:
    body_600211 = body
  result = call_600209.call(path_600210, nil, nil, nil, body_600211)

var createPushTemplate* = Call_CreatePushTemplate_600196(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_600197, base: "/",
    url: url_CreatePushTemplate_600198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_600166 = ref object of OpenApiRestCall_599352
proc url_GetPushTemplate_600168(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_600167(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600169 = path.getOrDefault("template-name")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "template-name", valid_600169
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600170 = header.getOrDefault("X-Amz-Date")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Date", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Security-Token")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Security-Token", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Content-Sha256", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Algorithm")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Algorithm", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Signature")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Signature", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-SignedHeaders", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Credential")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Credential", valid_600176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600177: Call_GetPushTemplate_600166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_600177.validator(path, query, header, formData, body)
  let scheme = call_600177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600177.url(scheme.get, call_600177.host, call_600177.base,
                         call_600177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600177, url, valid)

proc call*(call_600178: Call_GetPushTemplate_600166; templateName: string): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600179 = newJObject()
  add(path_600179, "template-name", newJString(templateName))
  result = call_600178.call(path_600179, nil, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_600166(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_600167, base: "/", url: url_GetPushTemplate_600168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_600212 = ref object of OpenApiRestCall_599352
proc url_DeletePushTemplate_600214(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_600213(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600215 = path.getOrDefault("template-name")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "template-name", valid_600215
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600216 = header.getOrDefault("X-Amz-Date")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Date", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Security-Token")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Security-Token", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Content-Sha256", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Algorithm")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Algorithm", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Signature")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Signature", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-SignedHeaders", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Credential")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Credential", valid_600222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600223: Call_DeletePushTemplate_600212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ## 
  let valid = call_600223.validator(path, query, header, formData, body)
  let scheme = call_600223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600223.url(scheme.get, call_600223.host, call_600223.base,
                         call_600223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600223, url, valid)

proc call*(call_600224: Call_DeletePushTemplate_600212; templateName: string): Recallable =
  ## deletePushTemplate
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600225 = newJObject()
  add(path_600225, "template-name", newJString(templateName))
  result = call_600224.call(path_600225, nil, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_600212(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_600213, base: "/",
    url: url_DeletePushTemplate_600214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_600243 = ref object of OpenApiRestCall_599352
proc url_CreateSegment_600245(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_600244(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600246 = path.getOrDefault("application-id")
  valid_600246 = validateParameter(valid_600246, JString, required = true,
                                 default = nil)
  if valid_600246 != nil:
    section.add "application-id", valid_600246
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Content-Sha256", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Algorithm")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Algorithm", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Signature")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Signature", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-SignedHeaders", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Credential")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Credential", valid_600253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600255: Call_CreateSegment_600243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_600255.validator(path, query, header, formData, body)
  let scheme = call_600255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600255.url(scheme.get, call_600255.host, call_600255.base,
                         call_600255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600255, url, valid)

proc call*(call_600256: Call_CreateSegment_600243; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600257 = newJObject()
  var body_600258 = newJObject()
  add(path_600257, "application-id", newJString(applicationId))
  if body != nil:
    body_600258 = body
  result = call_600256.call(path_600257, nil, nil, nil, body_600258)

var createSegment* = Call_CreateSegment_600243(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_600244, base: "/", url: url_CreateSegment_600245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_600226 = ref object of OpenApiRestCall_599352
proc url_GetSegments_600228(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_600227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600229 = path.getOrDefault("application-id")
  valid_600229 = validateParameter(valid_600229, JString, required = true,
                                 default = nil)
  if valid_600229 != nil:
    section.add "application-id", valid_600229
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_600230 = query.getOrDefault("token")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "token", valid_600230
  var valid_600231 = query.getOrDefault("page-size")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "page-size", valid_600231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Content-Sha256", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Algorithm")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Algorithm", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Signature")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Signature", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-SignedHeaders", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Credential")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Credential", valid_600238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600239: Call_GetSegments_600226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_600239.validator(path, query, header, formData, body)
  let scheme = call_600239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600239.url(scheme.get, call_600239.host, call_600239.base,
                         call_600239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600239, url, valid)

proc call*(call_600240: Call_GetSegments_600226; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_600241 = newJObject()
  var query_600242 = newJObject()
  add(query_600242, "token", newJString(token))
  add(path_600241, "application-id", newJString(applicationId))
  add(query_600242, "page-size", newJString(pageSize))
  result = call_600240.call(path_600241, query_600242, nil, nil, nil)

var getSegments* = Call_GetSegments_600226(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_600227,
                                        base: "/", url: url_GetSegments_600228,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_600273 = ref object of OpenApiRestCall_599352
proc url_UpdateSmsTemplate_600275(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_600274(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600276 = path.getOrDefault("template-name")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = nil)
  if valid_600276 != nil:
    section.add "template-name", valid_600276
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Content-Sha256", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Algorithm")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Algorithm", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Signature")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Signature", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-SignedHeaders", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Credential")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Credential", valid_600283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600285: Call_UpdateSmsTemplate_600273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_UpdateSmsTemplate_600273; templateName: string;
          body: JsonNode): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600287 = newJObject()
  var body_600288 = newJObject()
  add(path_600287, "template-name", newJString(templateName))
  if body != nil:
    body_600288 = body
  result = call_600286.call(path_600287, nil, nil, nil, body_600288)

var updateSmsTemplate* = Call_UpdateSmsTemplate_600273(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_600274, base: "/",
    url: url_UpdateSmsTemplate_600275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_600289 = ref object of OpenApiRestCall_599352
proc url_CreateSmsTemplate_600291(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_600290(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600292 = path.getOrDefault("template-name")
  valid_600292 = validateParameter(valid_600292, JString, required = true,
                                 default = nil)
  if valid_600292 != nil:
    section.add "template-name", valid_600292
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_CreateSmsTemplate_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_CreateSmsTemplate_600289; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600303 = newJObject()
  var body_600304 = newJObject()
  add(path_600303, "template-name", newJString(templateName))
  if body != nil:
    body_600304 = body
  result = call_600302.call(path_600303, nil, nil, nil, body_600304)

var createSmsTemplate* = Call_CreateSmsTemplate_600289(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_600290, base: "/",
    url: url_CreateSmsTemplate_600291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_600259 = ref object of OpenApiRestCall_599352
proc url_GetSmsTemplate_600261(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_600260(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600262 = path.getOrDefault("template-name")
  valid_600262 = validateParameter(valid_600262, JString, required = true,
                                 default = nil)
  if valid_600262 != nil:
    section.add "template-name", valid_600262
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600263 = header.getOrDefault("X-Amz-Date")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Date", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Security-Token")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Security-Token", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600270: Call_GetSmsTemplate_600259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_600270.validator(path, query, header, formData, body)
  let scheme = call_600270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600270.url(scheme.get, call_600270.host, call_600270.base,
                         call_600270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600270, url, valid)

proc call*(call_600271: Call_GetSmsTemplate_600259; templateName: string): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600272 = newJObject()
  add(path_600272, "template-name", newJString(templateName))
  result = call_600271.call(path_600272, nil, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_600259(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_600260, base: "/", url: url_GetSmsTemplate_600261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_600305 = ref object of OpenApiRestCall_599352
proc url_DeleteSmsTemplate_600307(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_600306(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600308 = path.getOrDefault("template-name")
  valid_600308 = validateParameter(valid_600308, JString, required = true,
                                 default = nil)
  if valid_600308 != nil:
    section.add "template-name", valid_600308
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600309 = header.getOrDefault("X-Amz-Date")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Date", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Security-Token")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Security-Token", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Content-Sha256", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Algorithm")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Algorithm", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Signature")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Signature", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-SignedHeaders", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Credential")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Credential", valid_600315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DeleteSmsTemplate_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DeleteSmsTemplate_600305; templateName: string): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600318 = newJObject()
  add(path_600318, "template-name", newJString(templateName))
  result = call_600317.call(path_600318, nil, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_600305(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_600306, base: "/",
    url: url_DeleteSmsTemplate_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_600333 = ref object of OpenApiRestCall_599352
proc url_UpdateVoiceTemplate_600335(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceTemplate_600334(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing message template that you can use in messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600336 = path.getOrDefault("template-name")
  valid_600336 = validateParameter(valid_600336, JString, required = true,
                                 default = nil)
  if valid_600336 != nil:
    section.add "template-name", valid_600336
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Content-Sha256", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Algorithm")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Algorithm", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Signature")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Signature", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-SignedHeaders", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Credential")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Credential", valid_600343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600345: Call_UpdateVoiceTemplate_600333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the voice channel.
  ## 
  let valid = call_600345.validator(path, query, header, formData, body)
  let scheme = call_600345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600345.url(scheme.get, call_600345.host, call_600345.base,
                         call_600345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600345, url, valid)

proc call*(call_600346: Call_UpdateVoiceTemplate_600333; templateName: string;
          body: JsonNode): Recallable =
  ## updateVoiceTemplate
  ## Updates an existing message template that you can use in messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600347 = newJObject()
  var body_600348 = newJObject()
  add(path_600347, "template-name", newJString(templateName))
  if body != nil:
    body_600348 = body
  result = call_600346.call(path_600347, nil, nil, nil, body_600348)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_600333(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_600334, base: "/",
    url: url_UpdateVoiceTemplate_600335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_600349 = ref object of OpenApiRestCall_599352
proc url_CreateVoiceTemplate_600351(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceTemplate_600350(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a message template that you can use in messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600352 = path.getOrDefault("template-name")
  valid_600352 = validateParameter(valid_600352, JString, required = true,
                                 default = nil)
  if valid_600352 != nil:
    section.add "template-name", valid_600352
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600353 = header.getOrDefault("X-Amz-Date")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Date", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Security-Token")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Security-Token", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600361: Call_CreateVoiceTemplate_600349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the voice channel.
  ## 
  let valid = call_600361.validator(path, query, header, formData, body)
  let scheme = call_600361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600361.url(scheme.get, call_600361.host, call_600361.base,
                         call_600361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600361, url, valid)

proc call*(call_600362: Call_CreateVoiceTemplate_600349; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template that you can use in messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_600363 = newJObject()
  var body_600364 = newJObject()
  add(path_600363, "template-name", newJString(templateName))
  if body != nil:
    body_600364 = body
  result = call_600362.call(path_600363, nil, nil, nil, body_600364)

var createVoiceTemplate* = Call_CreateVoiceTemplate_600349(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_600350, base: "/",
    url: url_CreateVoiceTemplate_600351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_600319 = ref object of OpenApiRestCall_599352
proc url_GetVoiceTemplate_600321(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceTemplate_600320(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600322 = path.getOrDefault("template-name")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = nil)
  if valid_600322 != nil:
    section.add "template-name", valid_600322
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600330: Call_GetVoiceTemplate_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the voice channel.
  ## 
  let valid = call_600330.validator(path, query, header, formData, body)
  let scheme = call_600330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600330.url(scheme.get, call_600330.host, call_600330.base,
                         call_600330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600330, url, valid)

proc call*(call_600331: Call_GetVoiceTemplate_600319; templateName: string): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600332 = newJObject()
  add(path_600332, "template-name", newJString(templateName))
  result = call_600331.call(path_600332, nil, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_600319(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_600320, base: "/",
    url: url_GetVoiceTemplate_600321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_600365 = ref object of OpenApiRestCall_599352
proc url_DeleteVoiceTemplate_600367(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceTemplate_600366(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a message template that was designed for use in messages that were sent through the voice channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   template-name: JString (required)
  ##                : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `template-name` field"
  var valid_600368 = path.getOrDefault("template-name")
  valid_600368 = validateParameter(valid_600368, JString, required = true,
                                 default = nil)
  if valid_600368 != nil:
    section.add "template-name", valid_600368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600369 = header.getOrDefault("X-Amz-Date")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Date", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Security-Token")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Security-Token", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Content-Sha256", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Algorithm")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Algorithm", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Signature")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Signature", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-SignedHeaders", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Credential")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Credential", valid_600375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_DeleteVoiceTemplate_600365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the voice channel.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_DeleteVoiceTemplate_600365; templateName: string): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_600378 = newJObject()
  add(path_600378, "template-name", newJString(templateName))
  result = call_600377.call(path_600378, nil, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_600365(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_600366, base: "/",
    url: url_DeleteVoiceTemplate_600367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_600393 = ref object of OpenApiRestCall_599352
proc url_UpdateAdmChannel_600395(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_600394(path: JsonNode; query: JsonNode;
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
  var valid_600396 = path.getOrDefault("application-id")
  valid_600396 = validateParameter(valid_600396, JString, required = true,
                                 default = nil)
  if valid_600396 != nil:
    section.add "application-id", valid_600396
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Content-Sha256", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Algorithm")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Algorithm", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Signature")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Signature", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-SignedHeaders", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Credential")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Credential", valid_600403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600405: Call_UpdateAdmChannel_600393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_600405.validator(path, query, header, formData, body)
  let scheme = call_600405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600405.url(scheme.get, call_600405.host, call_600405.base,
                         call_600405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600405, url, valid)

proc call*(call_600406: Call_UpdateAdmChannel_600393; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600407 = newJObject()
  var body_600408 = newJObject()
  add(path_600407, "application-id", newJString(applicationId))
  if body != nil:
    body_600408 = body
  result = call_600406.call(path_600407, nil, nil, nil, body_600408)

var updateAdmChannel* = Call_UpdateAdmChannel_600393(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_600394, base: "/",
    url: url_UpdateAdmChannel_600395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_600379 = ref object of OpenApiRestCall_599352
proc url_GetAdmChannel_600381(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_600380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600382 = path.getOrDefault("application-id")
  valid_600382 = validateParameter(valid_600382, JString, required = true,
                                 default = nil)
  if valid_600382 != nil:
    section.add "application-id", valid_600382
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600383 = header.getOrDefault("X-Amz-Date")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Date", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Security-Token")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Security-Token", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600390: Call_GetAdmChannel_600379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_600390.validator(path, query, header, formData, body)
  let scheme = call_600390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600390.url(scheme.get, call_600390.host, call_600390.base,
                         call_600390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600390, url, valid)

proc call*(call_600391: Call_GetAdmChannel_600379; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600392 = newJObject()
  add(path_600392, "application-id", newJString(applicationId))
  result = call_600391.call(path_600392, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_600379(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_600380, base: "/", url: url_GetAdmChannel_600381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_600409 = ref object of OpenApiRestCall_599352
proc url_DeleteAdmChannel_600411(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_600410(path: JsonNode; query: JsonNode;
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
  var valid_600412 = path.getOrDefault("application-id")
  valid_600412 = validateParameter(valid_600412, JString, required = true,
                                 default = nil)
  if valid_600412 != nil:
    section.add "application-id", valid_600412
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600413 = header.getOrDefault("X-Amz-Date")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Date", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Security-Token")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Security-Token", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600420: Call_DeleteAdmChannel_600409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600420.validator(path, query, header, formData, body)
  let scheme = call_600420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600420.url(scheme.get, call_600420.host, call_600420.base,
                         call_600420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600420, url, valid)

proc call*(call_600421: Call_DeleteAdmChannel_600409; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600422 = newJObject()
  add(path_600422, "application-id", newJString(applicationId))
  result = call_600421.call(path_600422, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_600409(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_600410, base: "/",
    url: url_DeleteAdmChannel_600411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_600437 = ref object of OpenApiRestCall_599352
proc url_UpdateApnsChannel_600439(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_600438(path: JsonNode; query: JsonNode;
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
  var valid_600440 = path.getOrDefault("application-id")
  valid_600440 = validateParameter(valid_600440, JString, required = true,
                                 default = nil)
  if valid_600440 != nil:
    section.add "application-id", valid_600440
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600441 = header.getOrDefault("X-Amz-Date")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Date", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Security-Token")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Security-Token", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Content-Sha256", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Algorithm")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Algorithm", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Signature")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Signature", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-SignedHeaders", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Credential")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Credential", valid_600447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600449: Call_UpdateApnsChannel_600437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_600449.validator(path, query, header, formData, body)
  let scheme = call_600449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600449.url(scheme.get, call_600449.host, call_600449.base,
                         call_600449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600449, url, valid)

proc call*(call_600450: Call_UpdateApnsChannel_600437; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600451 = newJObject()
  var body_600452 = newJObject()
  add(path_600451, "application-id", newJString(applicationId))
  if body != nil:
    body_600452 = body
  result = call_600450.call(path_600451, nil, nil, nil, body_600452)

var updateApnsChannel* = Call_UpdateApnsChannel_600437(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_600438, base: "/",
    url: url_UpdateApnsChannel_600439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_600423 = ref object of OpenApiRestCall_599352
proc url_GetApnsChannel_600425(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_600424(path: JsonNode; query: JsonNode;
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
  var valid_600426 = path.getOrDefault("application-id")
  valid_600426 = validateParameter(valid_600426, JString, required = true,
                                 default = nil)
  if valid_600426 != nil:
    section.add "application-id", valid_600426
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600427 = header.getOrDefault("X-Amz-Date")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Date", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Security-Token")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Security-Token", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Content-Sha256", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Algorithm")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Algorithm", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Signature")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Signature", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-SignedHeaders", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Credential")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Credential", valid_600433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600434: Call_GetApnsChannel_600423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_600434.validator(path, query, header, formData, body)
  let scheme = call_600434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600434.url(scheme.get, call_600434.host, call_600434.base,
                         call_600434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600434, url, valid)

proc call*(call_600435: Call_GetApnsChannel_600423; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600436 = newJObject()
  add(path_600436, "application-id", newJString(applicationId))
  result = call_600435.call(path_600436, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_600423(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_600424, base: "/", url: url_GetApnsChannel_600425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_600453 = ref object of OpenApiRestCall_599352
proc url_DeleteApnsChannel_600455(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_600454(path: JsonNode; query: JsonNode;
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
  var valid_600456 = path.getOrDefault("application-id")
  valid_600456 = validateParameter(valid_600456, JString, required = true,
                                 default = nil)
  if valid_600456 != nil:
    section.add "application-id", valid_600456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Content-Sha256", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Algorithm")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Algorithm", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Signature")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Signature", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-SignedHeaders", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Credential")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Credential", valid_600463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600464: Call_DeleteApnsChannel_600453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600464.validator(path, query, header, formData, body)
  let scheme = call_600464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600464.url(scheme.get, call_600464.host, call_600464.base,
                         call_600464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600464, url, valid)

proc call*(call_600465: Call_DeleteApnsChannel_600453; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600466 = newJObject()
  add(path_600466, "application-id", newJString(applicationId))
  result = call_600465.call(path_600466, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_600453(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_600454, base: "/",
    url: url_DeleteApnsChannel_600455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_600481 = ref object of OpenApiRestCall_599352
proc url_UpdateApnsSandboxChannel_600483(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_600482(path: JsonNode; query: JsonNode;
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
  var valid_600484 = path.getOrDefault("application-id")
  valid_600484 = validateParameter(valid_600484, JString, required = true,
                                 default = nil)
  if valid_600484 != nil:
    section.add "application-id", valid_600484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600485 = header.getOrDefault("X-Amz-Date")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Date", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Security-Token")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Security-Token", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Content-Sha256", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Algorithm")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Algorithm", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Signature")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Signature", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-SignedHeaders", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Credential")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Credential", valid_600491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600493: Call_UpdateApnsSandboxChannel_600481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_600493.validator(path, query, header, formData, body)
  let scheme = call_600493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600493.url(scheme.get, call_600493.host, call_600493.base,
                         call_600493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600493, url, valid)

proc call*(call_600494: Call_UpdateApnsSandboxChannel_600481;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600495 = newJObject()
  var body_600496 = newJObject()
  add(path_600495, "application-id", newJString(applicationId))
  if body != nil:
    body_600496 = body
  result = call_600494.call(path_600495, nil, nil, nil, body_600496)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_600481(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_600482, base: "/",
    url: url_UpdateApnsSandboxChannel_600483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_600467 = ref object of OpenApiRestCall_599352
proc url_GetApnsSandboxChannel_600469(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_600468(path: JsonNode; query: JsonNode;
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
  var valid_600470 = path.getOrDefault("application-id")
  valid_600470 = validateParameter(valid_600470, JString, required = true,
                                 default = nil)
  if valid_600470 != nil:
    section.add "application-id", valid_600470
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600471 = header.getOrDefault("X-Amz-Date")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Date", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Security-Token")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Security-Token", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Content-Sha256", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Algorithm")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Algorithm", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Signature")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Signature", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-SignedHeaders", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Credential")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Credential", valid_600477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600478: Call_GetApnsSandboxChannel_600467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_600478.validator(path, query, header, formData, body)
  let scheme = call_600478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600478.url(scheme.get, call_600478.host, call_600478.base,
                         call_600478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600478, url, valid)

proc call*(call_600479: Call_GetApnsSandboxChannel_600467; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600480 = newJObject()
  add(path_600480, "application-id", newJString(applicationId))
  result = call_600479.call(path_600480, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_600467(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_600468, base: "/",
    url: url_GetApnsSandboxChannel_600469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_600497 = ref object of OpenApiRestCall_599352
proc url_DeleteApnsSandboxChannel_600499(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_600498(path: JsonNode; query: JsonNode;
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
  var valid_600500 = path.getOrDefault("application-id")
  valid_600500 = validateParameter(valid_600500, JString, required = true,
                                 default = nil)
  if valid_600500 != nil:
    section.add "application-id", valid_600500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600501 = header.getOrDefault("X-Amz-Date")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Date", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Security-Token")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Security-Token", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Content-Sha256", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Algorithm")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Algorithm", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Signature")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Signature", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-SignedHeaders", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Credential")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Credential", valid_600507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600508: Call_DeleteApnsSandboxChannel_600497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600508.validator(path, query, header, formData, body)
  let scheme = call_600508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600508.url(scheme.get, call_600508.host, call_600508.base,
                         call_600508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600508, url, valid)

proc call*(call_600509: Call_DeleteApnsSandboxChannel_600497; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600510 = newJObject()
  add(path_600510, "application-id", newJString(applicationId))
  result = call_600509.call(path_600510, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_600497(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_600498, base: "/",
    url: url_DeleteApnsSandboxChannel_600499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_600525 = ref object of OpenApiRestCall_599352
proc url_UpdateApnsVoipChannel_600527(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_600526(path: JsonNode; query: JsonNode;
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
  var valid_600528 = path.getOrDefault("application-id")
  valid_600528 = validateParameter(valid_600528, JString, required = true,
                                 default = nil)
  if valid_600528 != nil:
    section.add "application-id", valid_600528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600529 = header.getOrDefault("X-Amz-Date")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Date", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Security-Token")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Security-Token", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Content-Sha256", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Algorithm")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Algorithm", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Signature")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Signature", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-SignedHeaders", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Credential")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Credential", valid_600535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600537: Call_UpdateApnsVoipChannel_600525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_600537.validator(path, query, header, formData, body)
  let scheme = call_600537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600537.url(scheme.get, call_600537.host, call_600537.base,
                         call_600537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600537, url, valid)

proc call*(call_600538: Call_UpdateApnsVoipChannel_600525; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600539 = newJObject()
  var body_600540 = newJObject()
  add(path_600539, "application-id", newJString(applicationId))
  if body != nil:
    body_600540 = body
  result = call_600538.call(path_600539, nil, nil, nil, body_600540)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_600525(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_600526, base: "/",
    url: url_UpdateApnsVoipChannel_600527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_600511 = ref object of OpenApiRestCall_599352
proc url_GetApnsVoipChannel_600513(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_600512(path: JsonNode; query: JsonNode;
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
  var valid_600514 = path.getOrDefault("application-id")
  valid_600514 = validateParameter(valid_600514, JString, required = true,
                                 default = nil)
  if valid_600514 != nil:
    section.add "application-id", valid_600514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600515 = header.getOrDefault("X-Amz-Date")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Date", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Security-Token")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Security-Token", valid_600516
  var valid_600517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Content-Sha256", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Algorithm")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Algorithm", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Signature")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Signature", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-SignedHeaders", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Credential")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Credential", valid_600521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600522: Call_GetApnsVoipChannel_600511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_600522.validator(path, query, header, formData, body)
  let scheme = call_600522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600522.url(scheme.get, call_600522.host, call_600522.base,
                         call_600522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600522, url, valid)

proc call*(call_600523: Call_GetApnsVoipChannel_600511; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600524 = newJObject()
  add(path_600524, "application-id", newJString(applicationId))
  result = call_600523.call(path_600524, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_600511(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_600512, base: "/",
    url: url_GetApnsVoipChannel_600513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_600541 = ref object of OpenApiRestCall_599352
proc url_DeleteApnsVoipChannel_600543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_600542(path: JsonNode; query: JsonNode;
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
  var valid_600544 = path.getOrDefault("application-id")
  valid_600544 = validateParameter(valid_600544, JString, required = true,
                                 default = nil)
  if valid_600544 != nil:
    section.add "application-id", valid_600544
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600545 = header.getOrDefault("X-Amz-Date")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Date", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Security-Token")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Security-Token", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Content-Sha256", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Algorithm")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Algorithm", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Signature")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Signature", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-SignedHeaders", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Credential")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Credential", valid_600551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600552: Call_DeleteApnsVoipChannel_600541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600552.validator(path, query, header, formData, body)
  let scheme = call_600552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600552.url(scheme.get, call_600552.host, call_600552.base,
                         call_600552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600552, url, valid)

proc call*(call_600553: Call_DeleteApnsVoipChannel_600541; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600554 = newJObject()
  add(path_600554, "application-id", newJString(applicationId))
  result = call_600553.call(path_600554, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_600541(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_600542, base: "/",
    url: url_DeleteApnsVoipChannel_600543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_600569 = ref object of OpenApiRestCall_599352
proc url_UpdateApnsVoipSandboxChannel_600571(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_600570(path: JsonNode; query: JsonNode;
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
  var valid_600572 = path.getOrDefault("application-id")
  valid_600572 = validateParameter(valid_600572, JString, required = true,
                                 default = nil)
  if valid_600572 != nil:
    section.add "application-id", valid_600572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600573 = header.getOrDefault("X-Amz-Date")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Date", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Security-Token")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Security-Token", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Content-Sha256", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Algorithm")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Algorithm", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Signature")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Signature", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-SignedHeaders", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Credential")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Credential", valid_600579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600581: Call_UpdateApnsVoipSandboxChannel_600569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_600581.validator(path, query, header, formData, body)
  let scheme = call_600581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600581.url(scheme.get, call_600581.host, call_600581.base,
                         call_600581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600581, url, valid)

proc call*(call_600582: Call_UpdateApnsVoipSandboxChannel_600569;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600583 = newJObject()
  var body_600584 = newJObject()
  add(path_600583, "application-id", newJString(applicationId))
  if body != nil:
    body_600584 = body
  result = call_600582.call(path_600583, nil, nil, nil, body_600584)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_600569(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_600570, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_600571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_600555 = ref object of OpenApiRestCall_599352
proc url_GetApnsVoipSandboxChannel_600557(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_600556(path: JsonNode; query: JsonNode;
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
  var valid_600558 = path.getOrDefault("application-id")
  valid_600558 = validateParameter(valid_600558, JString, required = true,
                                 default = nil)
  if valid_600558 != nil:
    section.add "application-id", valid_600558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600559 = header.getOrDefault("X-Amz-Date")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Date", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Security-Token")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Security-Token", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Content-Sha256", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Algorithm")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Algorithm", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Signature")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Signature", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-SignedHeaders", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Credential")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Credential", valid_600565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600566: Call_GetApnsVoipSandboxChannel_600555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_600566.validator(path, query, header, formData, body)
  let scheme = call_600566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600566.url(scheme.get, call_600566.host, call_600566.base,
                         call_600566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600566, url, valid)

proc call*(call_600567: Call_GetApnsVoipSandboxChannel_600555;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600568 = newJObject()
  add(path_600568, "application-id", newJString(applicationId))
  result = call_600567.call(path_600568, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_600555(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_600556, base: "/",
    url: url_GetApnsVoipSandboxChannel_600557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_600585 = ref object of OpenApiRestCall_599352
proc url_DeleteApnsVoipSandboxChannel_600587(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_600586(path: JsonNode; query: JsonNode;
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
  var valid_600588 = path.getOrDefault("application-id")
  valid_600588 = validateParameter(valid_600588, JString, required = true,
                                 default = nil)
  if valid_600588 != nil:
    section.add "application-id", valid_600588
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600589 = header.getOrDefault("X-Amz-Date")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Date", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Security-Token")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Security-Token", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Content-Sha256", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Algorithm")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Algorithm", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Signature")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Signature", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-SignedHeaders", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Credential")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Credential", valid_600595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600596: Call_DeleteApnsVoipSandboxChannel_600585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_DeleteApnsVoipSandboxChannel_600585;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600598 = newJObject()
  add(path_600598, "application-id", newJString(applicationId))
  result = call_600597.call(path_600598, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_600585(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_600586, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_600587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_600599 = ref object of OpenApiRestCall_599352
proc url_GetApp_600601(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_600600(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600602 = path.getOrDefault("application-id")
  valid_600602 = validateParameter(valid_600602, JString, required = true,
                                 default = nil)
  if valid_600602 != nil:
    section.add "application-id", valid_600602
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600603 = header.getOrDefault("X-Amz-Date")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Date", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Security-Token")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Security-Token", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Content-Sha256", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Algorithm")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Algorithm", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Signature")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Signature", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-SignedHeaders", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Credential")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Credential", valid_600609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600610: Call_GetApp_600599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_600610.validator(path, query, header, formData, body)
  let scheme = call_600610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600610.url(scheme.get, call_600610.host, call_600610.base,
                         call_600610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600610, url, valid)

proc call*(call_600611: Call_GetApp_600599; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600612 = newJObject()
  add(path_600612, "application-id", newJString(applicationId))
  result = call_600611.call(path_600612, nil, nil, nil, nil)

var getApp* = Call_GetApp_600599(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_600600, base: "/",
                              url: url_GetApp_600601,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_600613 = ref object of OpenApiRestCall_599352
proc url_DeleteApp_600615(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_600614(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600616 = path.getOrDefault("application-id")
  valid_600616 = validateParameter(valid_600616, JString, required = true,
                                 default = nil)
  if valid_600616 != nil:
    section.add "application-id", valid_600616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600617 = header.getOrDefault("X-Amz-Date")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Date", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Security-Token")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Security-Token", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Content-Sha256", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Algorithm")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Algorithm", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Signature")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Signature", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-SignedHeaders", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Credential")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Credential", valid_600623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600624: Call_DeleteApp_600613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_600624.validator(path, query, header, formData, body)
  let scheme = call_600624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600624.url(scheme.get, call_600624.host, call_600624.base,
                         call_600624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600624, url, valid)

proc call*(call_600625: Call_DeleteApp_600613; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600626 = newJObject()
  add(path_600626, "application-id", newJString(applicationId))
  result = call_600625.call(path_600626, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_600613(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_600614,
                                    base: "/", url: url_DeleteApp_600615,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_600641 = ref object of OpenApiRestCall_599352
proc url_UpdateBaiduChannel_600643(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_600642(path: JsonNode; query: JsonNode;
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
  var valid_600644 = path.getOrDefault("application-id")
  valid_600644 = validateParameter(valid_600644, JString, required = true,
                                 default = nil)
  if valid_600644 != nil:
    section.add "application-id", valid_600644
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600645 = header.getOrDefault("X-Amz-Date")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Date", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-Security-Token")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-Security-Token", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Content-Sha256", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Algorithm")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Algorithm", valid_600648
  var valid_600649 = header.getOrDefault("X-Amz-Signature")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Signature", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-SignedHeaders", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Credential")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Credential", valid_600651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600653: Call_UpdateBaiduChannel_600641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_600653.validator(path, query, header, formData, body)
  let scheme = call_600653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600653.url(scheme.get, call_600653.host, call_600653.base,
                         call_600653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600653, url, valid)

proc call*(call_600654: Call_UpdateBaiduChannel_600641; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600655 = newJObject()
  var body_600656 = newJObject()
  add(path_600655, "application-id", newJString(applicationId))
  if body != nil:
    body_600656 = body
  result = call_600654.call(path_600655, nil, nil, nil, body_600656)

var updateBaiduChannel* = Call_UpdateBaiduChannel_600641(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_600642, base: "/",
    url: url_UpdateBaiduChannel_600643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_600627 = ref object of OpenApiRestCall_599352
proc url_GetBaiduChannel_600629(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_600628(path: JsonNode; query: JsonNode;
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
  var valid_600630 = path.getOrDefault("application-id")
  valid_600630 = validateParameter(valid_600630, JString, required = true,
                                 default = nil)
  if valid_600630 != nil:
    section.add "application-id", valid_600630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600631 = header.getOrDefault("X-Amz-Date")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Date", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Security-Token")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Security-Token", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Content-Sha256", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Algorithm")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Algorithm", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Signature")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Signature", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-SignedHeaders", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Credential")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Credential", valid_600637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600638: Call_GetBaiduChannel_600627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_600638.validator(path, query, header, formData, body)
  let scheme = call_600638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600638.url(scheme.get, call_600638.host, call_600638.base,
                         call_600638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600638, url, valid)

proc call*(call_600639: Call_GetBaiduChannel_600627; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600640 = newJObject()
  add(path_600640, "application-id", newJString(applicationId))
  result = call_600639.call(path_600640, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_600627(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_600628, base: "/", url: url_GetBaiduChannel_600629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_600657 = ref object of OpenApiRestCall_599352
proc url_DeleteBaiduChannel_600659(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_600658(path: JsonNode; query: JsonNode;
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
  var valid_600660 = path.getOrDefault("application-id")
  valid_600660 = validateParameter(valid_600660, JString, required = true,
                                 default = nil)
  if valid_600660 != nil:
    section.add "application-id", valid_600660
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600661 = header.getOrDefault("X-Amz-Date")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Date", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Security-Token")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Security-Token", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Content-Sha256", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Algorithm")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Algorithm", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Signature")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Signature", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-SignedHeaders", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Credential")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Credential", valid_600667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600668: Call_DeleteBaiduChannel_600657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600668.validator(path, query, header, formData, body)
  let scheme = call_600668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600668.url(scheme.get, call_600668.host, call_600668.base,
                         call_600668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600668, url, valid)

proc call*(call_600669: Call_DeleteBaiduChannel_600657; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600670 = newJObject()
  add(path_600670, "application-id", newJString(applicationId))
  result = call_600669.call(path_600670, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_600657(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_600658, base: "/",
    url: url_DeleteBaiduChannel_600659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_600686 = ref object of OpenApiRestCall_599352
proc url_UpdateCampaign_600688(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_600687(path: JsonNode; query: JsonNode;
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
  var valid_600689 = path.getOrDefault("application-id")
  valid_600689 = validateParameter(valid_600689, JString, required = true,
                                 default = nil)
  if valid_600689 != nil:
    section.add "application-id", valid_600689
  var valid_600690 = path.getOrDefault("campaign-id")
  valid_600690 = validateParameter(valid_600690, JString, required = true,
                                 default = nil)
  if valid_600690 != nil:
    section.add "campaign-id", valid_600690
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600691 = header.getOrDefault("X-Amz-Date")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Date", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Security-Token")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Security-Token", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Content-Sha256", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Algorithm")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Algorithm", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Signature")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Signature", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-SignedHeaders", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Credential")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Credential", valid_600697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600699: Call_UpdateCampaign_600686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_600699.validator(path, query, header, formData, body)
  let scheme = call_600699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600699.url(scheme.get, call_600699.host, call_600699.base,
                         call_600699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600699, url, valid)

proc call*(call_600700: Call_UpdateCampaign_600686; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_600701 = newJObject()
  var body_600702 = newJObject()
  add(path_600701, "application-id", newJString(applicationId))
  if body != nil:
    body_600702 = body
  add(path_600701, "campaign-id", newJString(campaignId))
  result = call_600700.call(path_600701, nil, nil, nil, body_600702)

var updateCampaign* = Call_UpdateCampaign_600686(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_600687, base: "/", url: url_UpdateCampaign_600688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_600671 = ref object of OpenApiRestCall_599352
proc url_GetCampaign_600673(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_600672(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600674 = path.getOrDefault("application-id")
  valid_600674 = validateParameter(valid_600674, JString, required = true,
                                 default = nil)
  if valid_600674 != nil:
    section.add "application-id", valid_600674
  var valid_600675 = path.getOrDefault("campaign-id")
  valid_600675 = validateParameter(valid_600675, JString, required = true,
                                 default = nil)
  if valid_600675 != nil:
    section.add "campaign-id", valid_600675
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600676 = header.getOrDefault("X-Amz-Date")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Date", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Security-Token")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Security-Token", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Content-Sha256", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Algorithm")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Algorithm", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Signature")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Signature", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-SignedHeaders", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Credential")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Credential", valid_600682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600683: Call_GetCampaign_600671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_GetCampaign_600671; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_600685 = newJObject()
  add(path_600685, "application-id", newJString(applicationId))
  add(path_600685, "campaign-id", newJString(campaignId))
  result = call_600684.call(path_600685, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_600671(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_600672,
                                        base: "/", url: url_GetCampaign_600673,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_600703 = ref object of OpenApiRestCall_599352
proc url_DeleteCampaign_600705(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_600704(path: JsonNode; query: JsonNode;
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
  var valid_600706 = path.getOrDefault("application-id")
  valid_600706 = validateParameter(valid_600706, JString, required = true,
                                 default = nil)
  if valid_600706 != nil:
    section.add "application-id", valid_600706
  var valid_600707 = path.getOrDefault("campaign-id")
  valid_600707 = validateParameter(valid_600707, JString, required = true,
                                 default = nil)
  if valid_600707 != nil:
    section.add "campaign-id", valid_600707
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600708 = header.getOrDefault("X-Amz-Date")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Date", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Security-Token")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Security-Token", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Content-Sha256", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Algorithm")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Algorithm", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Signature")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Signature", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-SignedHeaders", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-Credential")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Credential", valid_600714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600715: Call_DeleteCampaign_600703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_600715.validator(path, query, header, formData, body)
  let scheme = call_600715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600715.url(scheme.get, call_600715.host, call_600715.base,
                         call_600715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600715, url, valid)

proc call*(call_600716: Call_DeleteCampaign_600703; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_600717 = newJObject()
  add(path_600717, "application-id", newJString(applicationId))
  add(path_600717, "campaign-id", newJString(campaignId))
  result = call_600716.call(path_600717, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_600703(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_600704, base: "/", url: url_DeleteCampaign_600705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_600732 = ref object of OpenApiRestCall_599352
proc url_UpdateEmailChannel_600734(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_600733(path: JsonNode; query: JsonNode;
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
  var valid_600735 = path.getOrDefault("application-id")
  valid_600735 = validateParameter(valid_600735, JString, required = true,
                                 default = nil)
  if valid_600735 != nil:
    section.add "application-id", valid_600735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600736 = header.getOrDefault("X-Amz-Date")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Date", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Security-Token")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Security-Token", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Content-Sha256", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Algorithm")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Algorithm", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Signature")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Signature", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-SignedHeaders", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Credential")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Credential", valid_600742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600744: Call_UpdateEmailChannel_600732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_600744.validator(path, query, header, formData, body)
  let scheme = call_600744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600744.url(scheme.get, call_600744.host, call_600744.base,
                         call_600744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600744, url, valid)

proc call*(call_600745: Call_UpdateEmailChannel_600732; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600746 = newJObject()
  var body_600747 = newJObject()
  add(path_600746, "application-id", newJString(applicationId))
  if body != nil:
    body_600747 = body
  result = call_600745.call(path_600746, nil, nil, nil, body_600747)

var updateEmailChannel* = Call_UpdateEmailChannel_600732(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_600733, base: "/",
    url: url_UpdateEmailChannel_600734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_600718 = ref object of OpenApiRestCall_599352
proc url_GetEmailChannel_600720(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_600719(path: JsonNode; query: JsonNode;
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
  var valid_600721 = path.getOrDefault("application-id")
  valid_600721 = validateParameter(valid_600721, JString, required = true,
                                 default = nil)
  if valid_600721 != nil:
    section.add "application-id", valid_600721
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600722 = header.getOrDefault("X-Amz-Date")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Date", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Security-Token")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Security-Token", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Content-Sha256", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Algorithm")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Algorithm", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Signature")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Signature", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-SignedHeaders", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Credential")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Credential", valid_600728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600729: Call_GetEmailChannel_600718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_600729.validator(path, query, header, formData, body)
  let scheme = call_600729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600729.url(scheme.get, call_600729.host, call_600729.base,
                         call_600729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600729, url, valid)

proc call*(call_600730: Call_GetEmailChannel_600718; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600731 = newJObject()
  add(path_600731, "application-id", newJString(applicationId))
  result = call_600730.call(path_600731, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_600718(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_600719, base: "/", url: url_GetEmailChannel_600720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_600748 = ref object of OpenApiRestCall_599352
proc url_DeleteEmailChannel_600750(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_600749(path: JsonNode; query: JsonNode;
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
  var valid_600751 = path.getOrDefault("application-id")
  valid_600751 = validateParameter(valid_600751, JString, required = true,
                                 default = nil)
  if valid_600751 != nil:
    section.add "application-id", valid_600751
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600752 = header.getOrDefault("X-Amz-Date")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Date", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Security-Token")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Security-Token", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Content-Sha256", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-Algorithm")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-Algorithm", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Signature")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Signature", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-SignedHeaders", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Credential")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Credential", valid_600758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600759: Call_DeleteEmailChannel_600748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600759.validator(path, query, header, formData, body)
  let scheme = call_600759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600759.url(scheme.get, call_600759.host, call_600759.base,
                         call_600759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600759, url, valid)

proc call*(call_600760: Call_DeleteEmailChannel_600748; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600761 = newJObject()
  add(path_600761, "application-id", newJString(applicationId))
  result = call_600760.call(path_600761, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_600748(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_600749, base: "/",
    url: url_DeleteEmailChannel_600750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_600777 = ref object of OpenApiRestCall_599352
proc url_UpdateEndpoint_600779(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_600778(path: JsonNode; query: JsonNode;
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
  var valid_600780 = path.getOrDefault("application-id")
  valid_600780 = validateParameter(valid_600780, JString, required = true,
                                 default = nil)
  if valid_600780 != nil:
    section.add "application-id", valid_600780
  var valid_600781 = path.getOrDefault("endpoint-id")
  valid_600781 = validateParameter(valid_600781, JString, required = true,
                                 default = nil)
  if valid_600781 != nil:
    section.add "endpoint-id", valid_600781
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600782 = header.getOrDefault("X-Amz-Date")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Date", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Security-Token")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Security-Token", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Content-Sha256", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-Algorithm")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-Algorithm", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Signature")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Signature", valid_600786
  var valid_600787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-SignedHeaders", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Credential")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Credential", valid_600788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600790: Call_UpdateEndpoint_600777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_600790.validator(path, query, header, formData, body)
  let scheme = call_600790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600790.url(scheme.get, call_600790.host, call_600790.base,
                         call_600790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600790, url, valid)

proc call*(call_600791: Call_UpdateEndpoint_600777; applicationId: string;
          endpointId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   body: JObject (required)
  var path_600792 = newJObject()
  var body_600793 = newJObject()
  add(path_600792, "application-id", newJString(applicationId))
  add(path_600792, "endpoint-id", newJString(endpointId))
  if body != nil:
    body_600793 = body
  result = call_600791.call(path_600792, nil, nil, nil, body_600793)

var updateEndpoint* = Call_UpdateEndpoint_600777(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_600778, base: "/", url: url_UpdateEndpoint_600779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_600762 = ref object of OpenApiRestCall_599352
proc url_GetEndpoint_600764(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_600763(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600765 = path.getOrDefault("application-id")
  valid_600765 = validateParameter(valid_600765, JString, required = true,
                                 default = nil)
  if valid_600765 != nil:
    section.add "application-id", valid_600765
  var valid_600766 = path.getOrDefault("endpoint-id")
  valid_600766 = validateParameter(valid_600766, JString, required = true,
                                 default = nil)
  if valid_600766 != nil:
    section.add "endpoint-id", valid_600766
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600767 = header.getOrDefault("X-Amz-Date")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Date", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Security-Token")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Security-Token", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Content-Sha256", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Algorithm")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Algorithm", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Signature")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Signature", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-SignedHeaders", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Credential")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Credential", valid_600773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600774: Call_GetEndpoint_600762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_600774.validator(path, query, header, formData, body)
  let scheme = call_600774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600774.url(scheme.get, call_600774.host, call_600774.base,
                         call_600774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600774, url, valid)

proc call*(call_600775: Call_GetEndpoint_600762; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_600776 = newJObject()
  add(path_600776, "application-id", newJString(applicationId))
  add(path_600776, "endpoint-id", newJString(endpointId))
  result = call_600775.call(path_600776, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_600762(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_600763,
                                        base: "/", url: url_GetEndpoint_600764,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_600794 = ref object of OpenApiRestCall_599352
proc url_DeleteEndpoint_600796(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_600795(path: JsonNode; query: JsonNode;
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
  var valid_600797 = path.getOrDefault("application-id")
  valid_600797 = validateParameter(valid_600797, JString, required = true,
                                 default = nil)
  if valid_600797 != nil:
    section.add "application-id", valid_600797
  var valid_600798 = path.getOrDefault("endpoint-id")
  valid_600798 = validateParameter(valid_600798, JString, required = true,
                                 default = nil)
  if valid_600798 != nil:
    section.add "endpoint-id", valid_600798
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600799 = header.getOrDefault("X-Amz-Date")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Date", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Security-Token")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Security-Token", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Content-Sha256", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Algorithm")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Algorithm", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Signature")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Signature", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-SignedHeaders", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Credential")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Credential", valid_600805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600806: Call_DeleteEndpoint_600794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_600806.validator(path, query, header, formData, body)
  let scheme = call_600806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600806.url(scheme.get, call_600806.host, call_600806.base,
                         call_600806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600806, url, valid)

proc call*(call_600807: Call_DeleteEndpoint_600794; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_600808 = newJObject()
  add(path_600808, "application-id", newJString(applicationId))
  add(path_600808, "endpoint-id", newJString(endpointId))
  result = call_600807.call(path_600808, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_600794(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_600795, base: "/", url: url_DeleteEndpoint_600796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_600823 = ref object of OpenApiRestCall_599352
proc url_PutEventStream_600825(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_600824(path: JsonNode; query: JsonNode;
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
  var valid_600826 = path.getOrDefault("application-id")
  valid_600826 = validateParameter(valid_600826, JString, required = true,
                                 default = nil)
  if valid_600826 != nil:
    section.add "application-id", valid_600826
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600827 = header.getOrDefault("X-Amz-Date")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Date", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Security-Token")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Security-Token", valid_600828
  var valid_600829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "X-Amz-Content-Sha256", valid_600829
  var valid_600830 = header.getOrDefault("X-Amz-Algorithm")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "X-Amz-Algorithm", valid_600830
  var valid_600831 = header.getOrDefault("X-Amz-Signature")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-Signature", valid_600831
  var valid_600832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-SignedHeaders", valid_600832
  var valid_600833 = header.getOrDefault("X-Amz-Credential")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Credential", valid_600833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600835: Call_PutEventStream_600823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_600835.validator(path, query, header, formData, body)
  let scheme = call_600835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600835.url(scheme.get, call_600835.host, call_600835.base,
                         call_600835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600835, url, valid)

proc call*(call_600836: Call_PutEventStream_600823; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600837 = newJObject()
  var body_600838 = newJObject()
  add(path_600837, "application-id", newJString(applicationId))
  if body != nil:
    body_600838 = body
  result = call_600836.call(path_600837, nil, nil, nil, body_600838)

var putEventStream* = Call_PutEventStream_600823(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_600824, base: "/", url: url_PutEventStream_600825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_600809 = ref object of OpenApiRestCall_599352
proc url_GetEventStream_600811(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_600810(path: JsonNode; query: JsonNode;
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
  var valid_600812 = path.getOrDefault("application-id")
  valid_600812 = validateParameter(valid_600812, JString, required = true,
                                 default = nil)
  if valid_600812 != nil:
    section.add "application-id", valid_600812
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600813 = header.getOrDefault("X-Amz-Date")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Date", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Security-Token")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Security-Token", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Content-Sha256", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Algorithm")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Algorithm", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Signature")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Signature", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-SignedHeaders", valid_600818
  var valid_600819 = header.getOrDefault("X-Amz-Credential")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-Credential", valid_600819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600820: Call_GetEventStream_600809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_600820.validator(path, query, header, formData, body)
  let scheme = call_600820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600820.url(scheme.get, call_600820.host, call_600820.base,
                         call_600820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600820, url, valid)

proc call*(call_600821: Call_GetEventStream_600809; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600822 = newJObject()
  add(path_600822, "application-id", newJString(applicationId))
  result = call_600821.call(path_600822, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_600809(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_600810, base: "/", url: url_GetEventStream_600811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_600839 = ref object of OpenApiRestCall_599352
proc url_DeleteEventStream_600841(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_600840(path: JsonNode; query: JsonNode;
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
  var valid_600842 = path.getOrDefault("application-id")
  valid_600842 = validateParameter(valid_600842, JString, required = true,
                                 default = nil)
  if valid_600842 != nil:
    section.add "application-id", valid_600842
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600843 = header.getOrDefault("X-Amz-Date")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Date", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Security-Token")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Security-Token", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Content-Sha256", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-Algorithm")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-Algorithm", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Signature")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Signature", valid_600847
  var valid_600848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "X-Amz-SignedHeaders", valid_600848
  var valid_600849 = header.getOrDefault("X-Amz-Credential")
  valid_600849 = validateParameter(valid_600849, JString, required = false,
                                 default = nil)
  if valid_600849 != nil:
    section.add "X-Amz-Credential", valid_600849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600850: Call_DeleteEventStream_600839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_600850.validator(path, query, header, formData, body)
  let scheme = call_600850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600850.url(scheme.get, call_600850.host, call_600850.base,
                         call_600850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600850, url, valid)

proc call*(call_600851: Call_DeleteEventStream_600839; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600852 = newJObject()
  add(path_600852, "application-id", newJString(applicationId))
  result = call_600851.call(path_600852, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_600839(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_600840, base: "/",
    url: url_DeleteEventStream_600841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_600867 = ref object of OpenApiRestCall_599352
proc url_UpdateGcmChannel_600869(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_600868(path: JsonNode; query: JsonNode;
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
  var valid_600870 = path.getOrDefault("application-id")
  valid_600870 = validateParameter(valid_600870, JString, required = true,
                                 default = nil)
  if valid_600870 != nil:
    section.add "application-id", valid_600870
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600879: Call_UpdateGcmChannel_600867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_600879.validator(path, query, header, formData, body)
  let scheme = call_600879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600879.url(scheme.get, call_600879.host, call_600879.base,
                         call_600879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600879, url, valid)

proc call*(call_600880: Call_UpdateGcmChannel_600867; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600881 = newJObject()
  var body_600882 = newJObject()
  add(path_600881, "application-id", newJString(applicationId))
  if body != nil:
    body_600882 = body
  result = call_600880.call(path_600881, nil, nil, nil, body_600882)

var updateGcmChannel* = Call_UpdateGcmChannel_600867(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_600868, base: "/",
    url: url_UpdateGcmChannel_600869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_600853 = ref object of OpenApiRestCall_599352
proc url_GetGcmChannel_600855(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_600854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600856 = path.getOrDefault("application-id")
  valid_600856 = validateParameter(valid_600856, JString, required = true,
                                 default = nil)
  if valid_600856 != nil:
    section.add "application-id", valid_600856
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600857 = header.getOrDefault("X-Amz-Date")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Date", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Security-Token")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Security-Token", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Content-Sha256", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Algorithm")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Algorithm", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Signature")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Signature", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-SignedHeaders", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-Credential")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-Credential", valid_600863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600864: Call_GetGcmChannel_600853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_600864.validator(path, query, header, formData, body)
  let scheme = call_600864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600864.url(scheme.get, call_600864.host, call_600864.base,
                         call_600864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600864, url, valid)

proc call*(call_600865: Call_GetGcmChannel_600853; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600866 = newJObject()
  add(path_600866, "application-id", newJString(applicationId))
  result = call_600865.call(path_600866, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_600853(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_600854, base: "/", url: url_GetGcmChannel_600855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_600883 = ref object of OpenApiRestCall_599352
proc url_DeleteGcmChannel_600885(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_600884(path: JsonNode; query: JsonNode;
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
  var valid_600886 = path.getOrDefault("application-id")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "application-id", valid_600886
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600887 = header.getOrDefault("X-Amz-Date")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Date", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Security-Token")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Security-Token", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Content-Sha256", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Algorithm")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Algorithm", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Signature")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Signature", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-SignedHeaders", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Credential")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Credential", valid_600893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600894: Call_DeleteGcmChannel_600883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_600894.validator(path, query, header, formData, body)
  let scheme = call_600894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600894.url(scheme.get, call_600894.host, call_600894.base,
                         call_600894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600894, url, valid)

proc call*(call_600895: Call_DeleteGcmChannel_600883; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600896 = newJObject()
  add(path_600896, "application-id", newJString(applicationId))
  result = call_600895.call(path_600896, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_600883(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_600884, base: "/",
    url: url_DeleteGcmChannel_600885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_600912 = ref object of OpenApiRestCall_599352
proc url_UpdateJourney_600914(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_600913(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600915 = path.getOrDefault("journey-id")
  valid_600915 = validateParameter(valid_600915, JString, required = true,
                                 default = nil)
  if valid_600915 != nil:
    section.add "journey-id", valid_600915
  var valid_600916 = path.getOrDefault("application-id")
  valid_600916 = validateParameter(valid_600916, JString, required = true,
                                 default = nil)
  if valid_600916 != nil:
    section.add "application-id", valid_600916
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600917 = header.getOrDefault("X-Amz-Date")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Date", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Security-Token")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Security-Token", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Content-Sha256", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Algorithm")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Algorithm", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Signature")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Signature", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-SignedHeaders", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Credential")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Credential", valid_600923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600925: Call_UpdateJourney_600912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_600925.validator(path, query, header, formData, body)
  let scheme = call_600925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600925.url(scheme.get, call_600925.host, call_600925.base,
                         call_600925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600925, url, valid)

proc call*(call_600926: Call_UpdateJourney_600912; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600927 = newJObject()
  var body_600928 = newJObject()
  add(path_600927, "journey-id", newJString(journeyId))
  add(path_600927, "application-id", newJString(applicationId))
  if body != nil:
    body_600928 = body
  result = call_600926.call(path_600927, nil, nil, nil, body_600928)

var updateJourney* = Call_UpdateJourney_600912(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_600913, base: "/", url: url_UpdateJourney_600914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_600897 = ref object of OpenApiRestCall_599352
proc url_GetJourney_600899(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJourney_600898(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600900 = path.getOrDefault("journey-id")
  valid_600900 = validateParameter(valid_600900, JString, required = true,
                                 default = nil)
  if valid_600900 != nil:
    section.add "journey-id", valid_600900
  var valid_600901 = path.getOrDefault("application-id")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = nil)
  if valid_600901 != nil:
    section.add "application-id", valid_600901
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600902 = header.getOrDefault("X-Amz-Date")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Date", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Security-Token")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Security-Token", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600909: Call_GetJourney_600897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_600909.validator(path, query, header, formData, body)
  let scheme = call_600909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600909.url(scheme.get, call_600909.host, call_600909.base,
                         call_600909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600909, url, valid)

proc call*(call_600910: Call_GetJourney_600897; journeyId: string;
          applicationId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600911 = newJObject()
  add(path_600911, "journey-id", newJString(journeyId))
  add(path_600911, "application-id", newJString(applicationId))
  result = call_600910.call(path_600911, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_600897(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_600898,
                                      base: "/", url: url_GetJourney_600899,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_600929 = ref object of OpenApiRestCall_599352
proc url_DeleteJourney_600931(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_600930(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600932 = path.getOrDefault("journey-id")
  valid_600932 = validateParameter(valid_600932, JString, required = true,
                                 default = nil)
  if valid_600932 != nil:
    section.add "journey-id", valid_600932
  var valid_600933 = path.getOrDefault("application-id")
  valid_600933 = validateParameter(valid_600933, JString, required = true,
                                 default = nil)
  if valid_600933 != nil:
    section.add "application-id", valid_600933
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600934 = header.getOrDefault("X-Amz-Date")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Date", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Security-Token")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Security-Token", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Content-Sha256", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Algorithm")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Algorithm", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Signature")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Signature", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-SignedHeaders", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Credential")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Credential", valid_600940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600941: Call_DeleteJourney_600929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_600941.validator(path, query, header, formData, body)
  let scheme = call_600941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600941.url(scheme.get, call_600941.host, call_600941.base,
                         call_600941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600941, url, valid)

proc call*(call_600942: Call_DeleteJourney_600929; journeyId: string;
          applicationId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600943 = newJObject()
  add(path_600943, "journey-id", newJString(journeyId))
  add(path_600943, "application-id", newJString(applicationId))
  result = call_600942.call(path_600943, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_600929(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_600930, base: "/", url: url_DeleteJourney_600931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_600959 = ref object of OpenApiRestCall_599352
proc url_UpdateSegment_600961(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_600960(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600962 = path.getOrDefault("segment-id")
  valid_600962 = validateParameter(valid_600962, JString, required = true,
                                 default = nil)
  if valid_600962 != nil:
    section.add "segment-id", valid_600962
  var valid_600963 = path.getOrDefault("application-id")
  valid_600963 = validateParameter(valid_600963, JString, required = true,
                                 default = nil)
  if valid_600963 != nil:
    section.add "application-id", valid_600963
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600964 = header.getOrDefault("X-Amz-Date")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Date", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Security-Token")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Security-Token", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Content-Sha256", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Algorithm")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Algorithm", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Signature")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Signature", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-SignedHeaders", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Credential")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Credential", valid_600970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600972: Call_UpdateSegment_600959; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_600972.validator(path, query, header, formData, body)
  let scheme = call_600972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600972.url(scheme.get, call_600972.host, call_600972.base,
                         call_600972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600972, url, valid)

proc call*(call_600973: Call_UpdateSegment_600959; segmentId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_600974 = newJObject()
  var body_600975 = newJObject()
  add(path_600974, "segment-id", newJString(segmentId))
  add(path_600974, "application-id", newJString(applicationId))
  if body != nil:
    body_600975 = body
  result = call_600973.call(path_600974, nil, nil, nil, body_600975)

var updateSegment* = Call_UpdateSegment_600959(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_600960, base: "/", url: url_UpdateSegment_600961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_600944 = ref object of OpenApiRestCall_599352
proc url_GetSegment_600946(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_600945(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600947 = path.getOrDefault("segment-id")
  valid_600947 = validateParameter(valid_600947, JString, required = true,
                                 default = nil)
  if valid_600947 != nil:
    section.add "segment-id", valid_600947
  var valid_600948 = path.getOrDefault("application-id")
  valid_600948 = validateParameter(valid_600948, JString, required = true,
                                 default = nil)
  if valid_600948 != nil:
    section.add "application-id", valid_600948
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600949 = header.getOrDefault("X-Amz-Date")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Date", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-Security-Token")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Security-Token", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Content-Sha256", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Algorithm")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Algorithm", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Signature")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Signature", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-SignedHeaders", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Credential")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Credential", valid_600955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600956: Call_GetSegment_600944; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_600956.validator(path, query, header, formData, body)
  let scheme = call_600956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600956.url(scheme.get, call_600956.host, call_600956.base,
                         call_600956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600956, url, valid)

proc call*(call_600957: Call_GetSegment_600944; segmentId: string;
          applicationId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600958 = newJObject()
  add(path_600958, "segment-id", newJString(segmentId))
  add(path_600958, "application-id", newJString(applicationId))
  result = call_600957.call(path_600958, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_600944(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_600945,
                                      base: "/", url: url_GetSegment_600946,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_600976 = ref object of OpenApiRestCall_599352
proc url_DeleteSegment_600978(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_600977(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600979 = path.getOrDefault("segment-id")
  valid_600979 = validateParameter(valid_600979, JString, required = true,
                                 default = nil)
  if valid_600979 != nil:
    section.add "segment-id", valid_600979
  var valid_600980 = path.getOrDefault("application-id")
  valid_600980 = validateParameter(valid_600980, JString, required = true,
                                 default = nil)
  if valid_600980 != nil:
    section.add "application-id", valid_600980
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600981 = header.getOrDefault("X-Amz-Date")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Date", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Security-Token")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Security-Token", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Content-Sha256", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Algorithm")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Algorithm", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Signature")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Signature", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-SignedHeaders", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-Credential")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Credential", valid_600987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600988: Call_DeleteSegment_600976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_600988.validator(path, query, header, formData, body)
  let scheme = call_600988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600988.url(scheme.get, call_600988.host, call_600988.base,
                         call_600988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600988, url, valid)

proc call*(call_600989: Call_DeleteSegment_600976; segmentId: string;
          applicationId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_600990 = newJObject()
  add(path_600990, "segment-id", newJString(segmentId))
  add(path_600990, "application-id", newJString(applicationId))
  result = call_600989.call(path_600990, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_600976(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_600977, base: "/", url: url_DeleteSegment_600978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_601005 = ref object of OpenApiRestCall_599352
proc url_UpdateSmsChannel_601007(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_601006(path: JsonNode; query: JsonNode;
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
  var valid_601008 = path.getOrDefault("application-id")
  valid_601008 = validateParameter(valid_601008, JString, required = true,
                                 default = nil)
  if valid_601008 != nil:
    section.add "application-id", valid_601008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601009 = header.getOrDefault("X-Amz-Date")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Date", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Security-Token")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Security-Token", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Content-Sha256", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Algorithm")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Algorithm", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Signature")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Signature", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-SignedHeaders", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Credential")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Credential", valid_601015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601017: Call_UpdateSmsChannel_601005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_601017.validator(path, query, header, formData, body)
  let scheme = call_601017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601017.url(scheme.get, call_601017.host, call_601017.base,
                         call_601017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601017, url, valid)

proc call*(call_601018: Call_UpdateSmsChannel_601005; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601019 = newJObject()
  var body_601020 = newJObject()
  add(path_601019, "application-id", newJString(applicationId))
  if body != nil:
    body_601020 = body
  result = call_601018.call(path_601019, nil, nil, nil, body_601020)

var updateSmsChannel* = Call_UpdateSmsChannel_601005(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_601006, base: "/",
    url: url_UpdateSmsChannel_601007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_600991 = ref object of OpenApiRestCall_599352
proc url_GetSmsChannel_600993(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_600992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600994 = path.getOrDefault("application-id")
  valid_600994 = validateParameter(valid_600994, JString, required = true,
                                 default = nil)
  if valid_600994 != nil:
    section.add "application-id", valid_600994
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600995 = header.getOrDefault("X-Amz-Date")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Date", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Security-Token")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Security-Token", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Content-Sha256", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Algorithm")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Algorithm", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-Signature")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Signature", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-SignedHeaders", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Credential")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Credential", valid_601001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601002: Call_GetSmsChannel_600991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_601002.validator(path, query, header, formData, body)
  let scheme = call_601002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601002.url(scheme.get, call_601002.host, call_601002.base,
                         call_601002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601002, url, valid)

proc call*(call_601003: Call_GetSmsChannel_600991; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601004 = newJObject()
  add(path_601004, "application-id", newJString(applicationId))
  result = call_601003.call(path_601004, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_600991(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_600992, base: "/", url: url_GetSmsChannel_600993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_601021 = ref object of OpenApiRestCall_599352
proc url_DeleteSmsChannel_601023(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_601022(path: JsonNode; query: JsonNode;
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
  var valid_601024 = path.getOrDefault("application-id")
  valid_601024 = validateParameter(valid_601024, JString, required = true,
                                 default = nil)
  if valid_601024 != nil:
    section.add "application-id", valid_601024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601025 = header.getOrDefault("X-Amz-Date")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Date", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Security-Token")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Security-Token", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Content-Sha256", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Algorithm")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Algorithm", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Signature")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Signature", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-SignedHeaders", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Credential")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Credential", valid_601031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601032: Call_DeleteSmsChannel_601021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601032.validator(path, query, header, formData, body)
  let scheme = call_601032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601032.url(scheme.get, call_601032.host, call_601032.base,
                         call_601032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601032, url, valid)

proc call*(call_601033: Call_DeleteSmsChannel_601021; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601034 = newJObject()
  add(path_601034, "application-id", newJString(applicationId))
  result = call_601033.call(path_601034, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_601021(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_601022, base: "/",
    url: url_DeleteSmsChannel_601023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_601035 = ref object of OpenApiRestCall_599352
proc url_GetUserEndpoints_601037(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_601036(path: JsonNode; query: JsonNode;
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
  var valid_601038 = path.getOrDefault("user-id")
  valid_601038 = validateParameter(valid_601038, JString, required = true,
                                 default = nil)
  if valid_601038 != nil:
    section.add "user-id", valid_601038
  var valid_601039 = path.getOrDefault("application-id")
  valid_601039 = validateParameter(valid_601039, JString, required = true,
                                 default = nil)
  if valid_601039 != nil:
    section.add "application-id", valid_601039
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601047: Call_GetUserEndpoints_601035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_601047.validator(path, query, header, formData, body)
  let scheme = call_601047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601047.url(scheme.get, call_601047.host, call_601047.base,
                         call_601047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601047, url, valid)

proc call*(call_601048: Call_GetUserEndpoints_601035; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601049 = newJObject()
  add(path_601049, "user-id", newJString(userId))
  add(path_601049, "application-id", newJString(applicationId))
  result = call_601048.call(path_601049, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_601035(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_601036, base: "/",
    url: url_GetUserEndpoints_601037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_601050 = ref object of OpenApiRestCall_599352
proc url_DeleteUserEndpoints_601052(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_601051(path: JsonNode; query: JsonNode;
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
  var valid_601053 = path.getOrDefault("user-id")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = nil)
  if valid_601053 != nil:
    section.add "user-id", valid_601053
  var valid_601054 = path.getOrDefault("application-id")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = nil)
  if valid_601054 != nil:
    section.add "application-id", valid_601054
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_DeleteUserEndpoints_601050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601062, url, valid)

proc call*(call_601063: Call_DeleteUserEndpoints_601050; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601064 = newJObject()
  add(path_601064, "user-id", newJString(userId))
  add(path_601064, "application-id", newJString(applicationId))
  result = call_601063.call(path_601064, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_601050(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_601051, base: "/",
    url: url_DeleteUserEndpoints_601052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_601079 = ref object of OpenApiRestCall_599352
proc url_UpdateVoiceChannel_601081(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_601080(path: JsonNode; query: JsonNode;
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
  var valid_601082 = path.getOrDefault("application-id")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "application-id", valid_601082
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601083 = header.getOrDefault("X-Amz-Date")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Date", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Security-Token")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Security-Token", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Content-Sha256", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Algorithm")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Algorithm", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Signature", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-SignedHeaders", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Credential")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Credential", valid_601089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601091: Call_UpdateVoiceChannel_601079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_601091.validator(path, query, header, formData, body)
  let scheme = call_601091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601091.url(scheme.get, call_601091.host, call_601091.base,
                         call_601091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601091, url, valid)

proc call*(call_601092: Call_UpdateVoiceChannel_601079; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601093 = newJObject()
  var body_601094 = newJObject()
  add(path_601093, "application-id", newJString(applicationId))
  if body != nil:
    body_601094 = body
  result = call_601092.call(path_601093, nil, nil, nil, body_601094)

var updateVoiceChannel* = Call_UpdateVoiceChannel_601079(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_601080, base: "/",
    url: url_UpdateVoiceChannel_601081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_601065 = ref object of OpenApiRestCall_599352
proc url_GetVoiceChannel_601067(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_601066(path: JsonNode; query: JsonNode;
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
  var valid_601068 = path.getOrDefault("application-id")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "application-id", valid_601068
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Content-Sha256", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Algorithm")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Algorithm", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Signature")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Signature", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-SignedHeaders", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Credential")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Credential", valid_601075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_GetVoiceChannel_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601076, url, valid)

proc call*(call_601077: Call_GetVoiceChannel_601065; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601078 = newJObject()
  add(path_601078, "application-id", newJString(applicationId))
  result = call_601077.call(path_601078, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_601065(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_601066, base: "/", url: url_GetVoiceChannel_601067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_601095 = ref object of OpenApiRestCall_599352
proc url_DeleteVoiceChannel_601097(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_601096(path: JsonNode; query: JsonNode;
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
  var valid_601098 = path.getOrDefault("application-id")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = nil)
  if valid_601098 != nil:
    section.add "application-id", valid_601098
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Content-Sha256", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Algorithm")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Algorithm", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Signature")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Signature", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-SignedHeaders", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Credential")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Credential", valid_601105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_DeleteVoiceChannel_601095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601106, url, valid)

proc call*(call_601107: Call_DeleteVoiceChannel_601095; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601108 = newJObject()
  add(path_601108, "application-id", newJString(applicationId))
  result = call_601107.call(path_601108, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_601095(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_601096, base: "/",
    url: url_DeleteVoiceChannel_601097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_601109 = ref object of OpenApiRestCall_599352
proc url_GetApplicationDateRangeKpi_601111(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_601110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601112 = path.getOrDefault("application-id")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "application-id", valid_601112
  var valid_601113 = path.getOrDefault("kpi-name")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = nil)
  if valid_601113 != nil:
    section.add "kpi-name", valid_601113
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
  var valid_601114 = query.getOrDefault("end-time")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "end-time", valid_601114
  var valid_601115 = query.getOrDefault("start-time")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "start-time", valid_601115
  var valid_601116 = query.getOrDefault("next-token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "next-token", valid_601116
  var valid_601117 = query.getOrDefault("page-size")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "page-size", valid_601117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601118 = header.getOrDefault("X-Amz-Date")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Date", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Security-Token")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Security-Token", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Content-Sha256", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Algorithm")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Algorithm", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Signature")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Signature", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-SignedHeaders", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Credential")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Credential", valid_601124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601125: Call_GetApplicationDateRangeKpi_601109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_601125.validator(path, query, header, formData, body)
  let scheme = call_601125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601125.url(scheme.get, call_601125.host, call_601125.base,
                         call_601125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601125, url, valid)

proc call*(call_601126: Call_GetApplicationDateRangeKpi_601109;
          applicationId: string; kpiName: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getApplicationDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
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
  var path_601127 = newJObject()
  var query_601128 = newJObject()
  add(query_601128, "end-time", newJString(endTime))
  add(path_601127, "application-id", newJString(applicationId))
  add(path_601127, "kpi-name", newJString(kpiName))
  add(query_601128, "start-time", newJString(startTime))
  add(query_601128, "next-token", newJString(nextToken))
  add(query_601128, "page-size", newJString(pageSize))
  result = call_601126.call(path_601127, query_601128, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_601109(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_601110, base: "/",
    url: url_GetApplicationDateRangeKpi_601111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_601143 = ref object of OpenApiRestCall_599352
proc url_UpdateApplicationSettings_601145(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_601144(path: JsonNode; query: JsonNode;
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
  var valid_601146 = path.getOrDefault("application-id")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = nil)
  if valid_601146 != nil:
    section.add "application-id", valid_601146
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Content-Sha256", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Algorithm")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Algorithm", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Signature")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Signature", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-SignedHeaders", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Credential")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Credential", valid_601153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601155: Call_UpdateApplicationSettings_601143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_601155.validator(path, query, header, formData, body)
  let scheme = call_601155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601155.url(scheme.get, call_601155.host, call_601155.base,
                         call_601155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601155, url, valid)

proc call*(call_601156: Call_UpdateApplicationSettings_601143;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601157 = newJObject()
  var body_601158 = newJObject()
  add(path_601157, "application-id", newJString(applicationId))
  if body != nil:
    body_601158 = body
  result = call_601156.call(path_601157, nil, nil, nil, body_601158)

var updateApplicationSettings* = Call_UpdateApplicationSettings_601143(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_601144, base: "/",
    url: url_UpdateApplicationSettings_601145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_601129 = ref object of OpenApiRestCall_599352
proc url_GetApplicationSettings_601131(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_601130(path: JsonNode; query: JsonNode;
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
  var valid_601132 = path.getOrDefault("application-id")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = nil)
  if valid_601132 != nil:
    section.add "application-id", valid_601132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_GetApplicationSettings_601129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601140, url, valid)

proc call*(call_601141: Call_GetApplicationSettings_601129; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601142 = newJObject()
  add(path_601142, "application-id", newJString(applicationId))
  result = call_601141.call(path_601142, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_601129(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_601130, base: "/",
    url: url_GetApplicationSettings_601131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_601159 = ref object of OpenApiRestCall_599352
proc url_GetCampaignActivities_601161(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_601160(path: JsonNode; query: JsonNode;
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
  var valid_601162 = path.getOrDefault("application-id")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = nil)
  if valid_601162 != nil:
    section.add "application-id", valid_601162
  var valid_601163 = path.getOrDefault("campaign-id")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "campaign-id", valid_601163
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601164 = query.getOrDefault("token")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "token", valid_601164
  var valid_601165 = query.getOrDefault("page-size")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "page-size", valid_601165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_GetCampaignActivities_601159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601173, url, valid)

proc call*(call_601174: Call_GetCampaignActivities_601159; applicationId: string;
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
  var path_601175 = newJObject()
  var query_601176 = newJObject()
  add(query_601176, "token", newJString(token))
  add(path_601175, "application-id", newJString(applicationId))
  add(path_601175, "campaign-id", newJString(campaignId))
  add(query_601176, "page-size", newJString(pageSize))
  result = call_601174.call(path_601175, query_601176, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_601159(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_601160, base: "/",
    url: url_GetCampaignActivities_601161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_601177 = ref object of OpenApiRestCall_599352
proc url_GetCampaignDateRangeKpi_601179(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_601178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601180 = path.getOrDefault("application-id")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "application-id", valid_601180
  var valid_601181 = path.getOrDefault("kpi-name")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "kpi-name", valid_601181
  var valid_601182 = path.getOrDefault("campaign-id")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = nil)
  if valid_601182 != nil:
    section.add "campaign-id", valid_601182
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
  var valid_601183 = query.getOrDefault("end-time")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "end-time", valid_601183
  var valid_601184 = query.getOrDefault("start-time")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "start-time", valid_601184
  var valid_601185 = query.getOrDefault("next-token")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "next-token", valid_601185
  var valid_601186 = query.getOrDefault("page-size")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "page-size", valid_601186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601187 = header.getOrDefault("X-Amz-Date")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Date", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Security-Token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Security-Token", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_GetCampaignDateRangeKpi_601177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601194, url, valid)

proc call*(call_601195: Call_GetCampaignDateRangeKpi_601177; applicationId: string;
          kpiName: string; campaignId: string; endTime: string = "";
          startTime: string = ""; nextToken: string = ""; pageSize: string = ""): Recallable =
  ## getCampaignDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
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
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_601196 = newJObject()
  var query_601197 = newJObject()
  add(query_601197, "end-time", newJString(endTime))
  add(path_601196, "application-id", newJString(applicationId))
  add(path_601196, "kpi-name", newJString(kpiName))
  add(query_601197, "start-time", newJString(startTime))
  add(query_601197, "next-token", newJString(nextToken))
  add(path_601196, "campaign-id", newJString(campaignId))
  add(query_601197, "page-size", newJString(pageSize))
  result = call_601195.call(path_601196, query_601197, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_601177(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_601178, base: "/",
    url: url_GetCampaignDateRangeKpi_601179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_601198 = ref object of OpenApiRestCall_599352
proc url_GetCampaignVersion_601200(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_601199(path: JsonNode; query: JsonNode;
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
  var valid_601201 = path.getOrDefault("version")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "version", valid_601201
  var valid_601202 = path.getOrDefault("application-id")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = nil)
  if valid_601202 != nil:
    section.add "application-id", valid_601202
  var valid_601203 = path.getOrDefault("campaign-id")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = nil)
  if valid_601203 != nil:
    section.add "campaign-id", valid_601203
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601204 = header.getOrDefault("X-Amz-Date")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Date", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Security-Token")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Security-Token", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Content-Sha256", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Algorithm")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Algorithm", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Signature")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Signature", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-SignedHeaders", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Credential")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Credential", valid_601210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601211: Call_GetCampaignVersion_601198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_601211.validator(path, query, header, formData, body)
  let scheme = call_601211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601211.url(scheme.get, call_601211.host, call_601211.base,
                         call_601211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601211, url, valid)

proc call*(call_601212: Call_GetCampaignVersion_601198; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_601213 = newJObject()
  add(path_601213, "version", newJString(version))
  add(path_601213, "application-id", newJString(applicationId))
  add(path_601213, "campaign-id", newJString(campaignId))
  result = call_601212.call(path_601213, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_601198(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_601199, base: "/",
    url: url_GetCampaignVersion_601200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_601214 = ref object of OpenApiRestCall_599352
proc url_GetCampaignVersions_601216(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_601215(path: JsonNode; query: JsonNode;
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
  var valid_601217 = path.getOrDefault("application-id")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = nil)
  if valid_601217 != nil:
    section.add "application-id", valid_601217
  var valid_601218 = path.getOrDefault("campaign-id")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "campaign-id", valid_601218
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601219 = query.getOrDefault("token")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "token", valid_601219
  var valid_601220 = query.getOrDefault("page-size")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "page-size", valid_601220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601221 = header.getOrDefault("X-Amz-Date")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Date", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Security-Token")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Security-Token", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601228: Call_GetCampaignVersions_601214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_601228.validator(path, query, header, formData, body)
  let scheme = call_601228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601228.url(scheme.get, call_601228.host, call_601228.base,
                         call_601228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601228, url, valid)

proc call*(call_601229: Call_GetCampaignVersions_601214; applicationId: string;
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
  var path_601230 = newJObject()
  var query_601231 = newJObject()
  add(query_601231, "token", newJString(token))
  add(path_601230, "application-id", newJString(applicationId))
  add(path_601230, "campaign-id", newJString(campaignId))
  add(query_601231, "page-size", newJString(pageSize))
  result = call_601229.call(path_601230, query_601231, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_601214(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_601215, base: "/",
    url: url_GetCampaignVersions_601216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_601232 = ref object of OpenApiRestCall_599352
proc url_GetChannels_601234(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_601233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601235 = path.getOrDefault("application-id")
  valid_601235 = validateParameter(valid_601235, JString, required = true,
                                 default = nil)
  if valid_601235 != nil:
    section.add "application-id", valid_601235
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601236 = header.getOrDefault("X-Amz-Date")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Date", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Security-Token")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Security-Token", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601243: Call_GetChannels_601232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_601243.validator(path, query, header, formData, body)
  let scheme = call_601243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601243.url(scheme.get, call_601243.host, call_601243.base,
                         call_601243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601243, url, valid)

proc call*(call_601244: Call_GetChannels_601232; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601245 = newJObject()
  add(path_601245, "application-id", newJString(applicationId))
  result = call_601244.call(path_601245, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_601232(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_601233,
                                        base: "/", url: url_GetChannels_601234,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_601246 = ref object of OpenApiRestCall_599352
proc url_GetExportJob_601248(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_601247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601249 = path.getOrDefault("application-id")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = nil)
  if valid_601249 != nil:
    section.add "application-id", valid_601249
  var valid_601250 = path.getOrDefault("job-id")
  valid_601250 = validateParameter(valid_601250, JString, required = true,
                                 default = nil)
  if valid_601250 != nil:
    section.add "job-id", valid_601250
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601251 = header.getOrDefault("X-Amz-Date")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Date", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Security-Token")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Security-Token", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601258: Call_GetExportJob_601246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_601258.validator(path, query, header, formData, body)
  let scheme = call_601258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601258.url(scheme.get, call_601258.host, call_601258.base,
                         call_601258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601258, url, valid)

proc call*(call_601259: Call_GetExportJob_601246; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_601260 = newJObject()
  add(path_601260, "application-id", newJString(applicationId))
  add(path_601260, "job-id", newJString(jobId))
  result = call_601259.call(path_601260, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_601246(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_601247, base: "/", url: url_GetExportJob_601248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_601261 = ref object of OpenApiRestCall_599352
proc url_GetImportJob_601263(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_601262(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601264 = path.getOrDefault("application-id")
  valid_601264 = validateParameter(valid_601264, JString, required = true,
                                 default = nil)
  if valid_601264 != nil:
    section.add "application-id", valid_601264
  var valid_601265 = path.getOrDefault("job-id")
  valid_601265 = validateParameter(valid_601265, JString, required = true,
                                 default = nil)
  if valid_601265 != nil:
    section.add "job-id", valid_601265
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601266 = header.getOrDefault("X-Amz-Date")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Date", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Security-Token")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Security-Token", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601273: Call_GetImportJob_601261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_601273.validator(path, query, header, formData, body)
  let scheme = call_601273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601273.url(scheme.get, call_601273.host, call_601273.base,
                         call_601273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601273, url, valid)

proc call*(call_601274: Call_GetImportJob_601261; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_601275 = newJObject()
  add(path_601275, "application-id", newJString(applicationId))
  add(path_601275, "job-id", newJString(jobId))
  result = call_601274.call(path_601275, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_601261(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_601262, base: "/", url: url_GetImportJob_601263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_601276 = ref object of OpenApiRestCall_599352
proc url_GetJourneyDateRangeKpi_601278(protocol: Scheme; host: string; base: string;
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

proc validate_GetJourneyDateRangeKpi_601277(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601279 = path.getOrDefault("journey-id")
  valid_601279 = validateParameter(valid_601279, JString, required = true,
                                 default = nil)
  if valid_601279 != nil:
    section.add "journey-id", valid_601279
  var valid_601280 = path.getOrDefault("application-id")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = nil)
  if valid_601280 != nil:
    section.add "application-id", valid_601280
  var valid_601281 = path.getOrDefault("kpi-name")
  valid_601281 = validateParameter(valid_601281, JString, required = true,
                                 default = nil)
  if valid_601281 != nil:
    section.add "kpi-name", valid_601281
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
  var valid_601282 = query.getOrDefault("end-time")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "end-time", valid_601282
  var valid_601283 = query.getOrDefault("start-time")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "start-time", valid_601283
  var valid_601284 = query.getOrDefault("next-token")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "next-token", valid_601284
  var valid_601285 = query.getOrDefault("page-size")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "page-size", valid_601285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601286 = header.getOrDefault("X-Amz-Date")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Date", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Security-Token")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Security-Token", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Content-Sha256", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Algorithm")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Algorithm", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Signature")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Signature", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-SignedHeaders", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Credential")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Credential", valid_601292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601293: Call_GetJourneyDateRangeKpi_601276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_601293.validator(path, query, header, formData, body)
  let scheme = call_601293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601293.url(scheme.get, call_601293.host, call_601293.base,
                         call_601293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601293, url, valid)

proc call*(call_601294: Call_GetJourneyDateRangeKpi_601276; journeyId: string;
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
  var path_601295 = newJObject()
  var query_601296 = newJObject()
  add(path_601295, "journey-id", newJString(journeyId))
  add(query_601296, "end-time", newJString(endTime))
  add(path_601295, "application-id", newJString(applicationId))
  add(path_601295, "kpi-name", newJString(kpiName))
  add(query_601296, "start-time", newJString(startTime))
  add(query_601296, "next-token", newJString(nextToken))
  add(query_601296, "page-size", newJString(pageSize))
  result = call_601294.call(path_601295, query_601296, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_601276(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_601277, base: "/",
    url: url_GetJourneyDateRangeKpi_601278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_601297 = ref object of OpenApiRestCall_599352
proc url_GetJourneyExecutionActivityMetrics_601299(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionActivityMetrics_601298(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601300 = path.getOrDefault("journey-id")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = nil)
  if valid_601300 != nil:
    section.add "journey-id", valid_601300
  var valid_601301 = path.getOrDefault("application-id")
  valid_601301 = validateParameter(valid_601301, JString, required = true,
                                 default = nil)
  if valid_601301 != nil:
    section.add "application-id", valid_601301
  var valid_601302 = path.getOrDefault("journey-activity-id")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = nil)
  if valid_601302 != nil:
    section.add "journey-activity-id", valid_601302
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601303 = query.getOrDefault("next-token")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "next-token", valid_601303
  var valid_601304 = query.getOrDefault("page-size")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "page-size", valid_601304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601305 = header.getOrDefault("X-Amz-Date")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Date", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Security-Token")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Security-Token", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Content-Sha256", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Algorithm")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Algorithm", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Signature")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Signature", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-SignedHeaders", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Credential")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Credential", valid_601311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601312: Call_GetJourneyExecutionActivityMetrics_601297;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_601312.validator(path, query, header, formData, body)
  let scheme = call_601312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601312.url(scheme.get, call_601312.host, call_601312.base,
                         call_601312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601312, url, valid)

proc call*(call_601313: Call_GetJourneyExecutionActivityMetrics_601297;
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
  var path_601314 = newJObject()
  var query_601315 = newJObject()
  add(path_601314, "journey-id", newJString(journeyId))
  add(path_601314, "application-id", newJString(applicationId))
  add(path_601314, "journey-activity-id", newJString(journeyActivityId))
  add(query_601315, "next-token", newJString(nextToken))
  add(query_601315, "page-size", newJString(pageSize))
  result = call_601313.call(path_601314, query_601315, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_601297(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_601298, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_601299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_601316 = ref object of OpenApiRestCall_599352
proc url_GetJourneyExecutionMetrics_601318(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_601317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601319 = path.getOrDefault("journey-id")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "journey-id", valid_601319
  var valid_601320 = path.getOrDefault("application-id")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "application-id", valid_601320
  result.add "path", section
  ## parameters in `query` object:
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601321 = query.getOrDefault("next-token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "next-token", valid_601321
  var valid_601322 = query.getOrDefault("page-size")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "page-size", valid_601322
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601323 = header.getOrDefault("X-Amz-Date")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Date", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Security-Token")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Security-Token", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Content-Sha256", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Algorithm")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Algorithm", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Signature")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Signature", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-SignedHeaders", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Credential")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Credential", valid_601329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601330: Call_GetJourneyExecutionMetrics_601316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_601330.validator(path, query, header, formData, body)
  let scheme = call_601330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601330.url(scheme.get, call_601330.host, call_601330.base,
                         call_601330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601330, url, valid)

proc call*(call_601331: Call_GetJourneyExecutionMetrics_601316; journeyId: string;
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
  var path_601332 = newJObject()
  var query_601333 = newJObject()
  add(path_601332, "journey-id", newJString(journeyId))
  add(path_601332, "application-id", newJString(applicationId))
  add(query_601333, "next-token", newJString(nextToken))
  add(query_601333, "page-size", newJString(pageSize))
  result = call_601331.call(path_601332, query_601333, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_601316(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_601317, base: "/",
    url: url_GetJourneyExecutionMetrics_601318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_601334 = ref object of OpenApiRestCall_599352
proc url_GetSegmentExportJobs_601336(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_601335(path: JsonNode; query: JsonNode;
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
  var valid_601337 = path.getOrDefault("segment-id")
  valid_601337 = validateParameter(valid_601337, JString, required = true,
                                 default = nil)
  if valid_601337 != nil:
    section.add "segment-id", valid_601337
  var valid_601338 = path.getOrDefault("application-id")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = nil)
  if valid_601338 != nil:
    section.add "application-id", valid_601338
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601339 = query.getOrDefault("token")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "token", valid_601339
  var valid_601340 = query.getOrDefault("page-size")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "page-size", valid_601340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601341 = header.getOrDefault("X-Amz-Date")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Date", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Security-Token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Security-Token", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601348: Call_GetSegmentExportJobs_601334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_601348.validator(path, query, header, formData, body)
  let scheme = call_601348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601348.url(scheme.get, call_601348.host, call_601348.base,
                         call_601348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601348, url, valid)

proc call*(call_601349: Call_GetSegmentExportJobs_601334; segmentId: string;
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
  var path_601350 = newJObject()
  var query_601351 = newJObject()
  add(query_601351, "token", newJString(token))
  add(path_601350, "segment-id", newJString(segmentId))
  add(path_601350, "application-id", newJString(applicationId))
  add(query_601351, "page-size", newJString(pageSize))
  result = call_601349.call(path_601350, query_601351, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_601334(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_601335, base: "/",
    url: url_GetSegmentExportJobs_601336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_601352 = ref object of OpenApiRestCall_599352
proc url_GetSegmentImportJobs_601354(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_601353(path: JsonNode; query: JsonNode;
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
  var valid_601355 = path.getOrDefault("segment-id")
  valid_601355 = validateParameter(valid_601355, JString, required = true,
                                 default = nil)
  if valid_601355 != nil:
    section.add "segment-id", valid_601355
  var valid_601356 = path.getOrDefault("application-id")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = nil)
  if valid_601356 != nil:
    section.add "application-id", valid_601356
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601357 = query.getOrDefault("token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "token", valid_601357
  var valid_601358 = query.getOrDefault("page-size")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "page-size", valid_601358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601359 = header.getOrDefault("X-Amz-Date")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Date", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Security-Token")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Security-Token", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Content-Sha256", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Algorithm")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Algorithm", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Signature")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Signature", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-SignedHeaders", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Credential")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Credential", valid_601365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_GetSegmentImportJobs_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601366, url, valid)

proc call*(call_601367: Call_GetSegmentImportJobs_601352; segmentId: string;
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
  var path_601368 = newJObject()
  var query_601369 = newJObject()
  add(query_601369, "token", newJString(token))
  add(path_601368, "segment-id", newJString(segmentId))
  add(path_601368, "application-id", newJString(applicationId))
  add(query_601369, "page-size", newJString(pageSize))
  result = call_601367.call(path_601368, query_601369, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_601352(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_601353, base: "/",
    url: url_GetSegmentImportJobs_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_601370 = ref object of OpenApiRestCall_599352
proc url_GetSegmentVersion_601372(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_601371(path: JsonNode; query: JsonNode;
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
  var valid_601373 = path.getOrDefault("segment-id")
  valid_601373 = validateParameter(valid_601373, JString, required = true,
                                 default = nil)
  if valid_601373 != nil:
    section.add "segment-id", valid_601373
  var valid_601374 = path.getOrDefault("version")
  valid_601374 = validateParameter(valid_601374, JString, required = true,
                                 default = nil)
  if valid_601374 != nil:
    section.add "version", valid_601374
  var valid_601375 = path.getOrDefault("application-id")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = nil)
  if valid_601375 != nil:
    section.add "application-id", valid_601375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601376 = header.getOrDefault("X-Amz-Date")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Date", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Security-Token")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Security-Token", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Content-Sha256", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Algorithm")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Algorithm", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Signature")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Signature", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-SignedHeaders", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Credential")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Credential", valid_601382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601383: Call_GetSegmentVersion_601370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_601383.validator(path, query, header, formData, body)
  let scheme = call_601383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601383.url(scheme.get, call_601383.host, call_601383.base,
                         call_601383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601383, url, valid)

proc call*(call_601384: Call_GetSegmentVersion_601370; segmentId: string;
          version: string; applicationId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601385 = newJObject()
  add(path_601385, "segment-id", newJString(segmentId))
  add(path_601385, "version", newJString(version))
  add(path_601385, "application-id", newJString(applicationId))
  result = call_601384.call(path_601385, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_601370(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_601371, base: "/",
    url: url_GetSegmentVersion_601372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_601386 = ref object of OpenApiRestCall_599352
proc url_GetSegmentVersions_601388(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_601387(path: JsonNode; query: JsonNode;
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
  var valid_601389 = path.getOrDefault("segment-id")
  valid_601389 = validateParameter(valid_601389, JString, required = true,
                                 default = nil)
  if valid_601389 != nil:
    section.add "segment-id", valid_601389
  var valid_601390 = path.getOrDefault("application-id")
  valid_601390 = validateParameter(valid_601390, JString, required = true,
                                 default = nil)
  if valid_601390 != nil:
    section.add "application-id", valid_601390
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601391 = query.getOrDefault("token")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "token", valid_601391
  var valid_601392 = query.getOrDefault("page-size")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "page-size", valid_601392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601393 = header.getOrDefault("X-Amz-Date")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Date", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Security-Token")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Security-Token", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Content-Sha256", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Algorithm")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Algorithm", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Signature")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Signature", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-SignedHeaders", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Credential")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Credential", valid_601399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601400: Call_GetSegmentVersions_601386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601400, url, valid)

proc call*(call_601401: Call_GetSegmentVersions_601386; segmentId: string;
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
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_601402 = newJObject()
  var query_601403 = newJObject()
  add(query_601403, "token", newJString(token))
  add(path_601402, "segment-id", newJString(segmentId))
  add(path_601402, "application-id", newJString(applicationId))
  add(query_601403, "page-size", newJString(pageSize))
  result = call_601401.call(path_601402, query_601403, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_601386(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_601387, base: "/",
    url: url_GetSegmentVersions_601388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601418 = ref object of OpenApiRestCall_599352
proc url_TagResource_601420(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_601419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601421 = path.getOrDefault("resource-arn")
  valid_601421 = validateParameter(valid_601421, JString, required = true,
                                 default = nil)
  if valid_601421 != nil:
    section.add "resource-arn", valid_601421
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Content-Sha256", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Algorithm")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Algorithm", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Signature")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Signature", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-SignedHeaders", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Credential")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Credential", valid_601428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601430: Call_TagResource_601418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_601430.validator(path, query, header, formData, body)
  let scheme = call_601430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601430.url(scheme.get, call_601430.host, call_601430.base,
                         call_601430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601430, url, valid)

proc call*(call_601431: Call_TagResource_601418; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_601432 = newJObject()
  var body_601433 = newJObject()
  add(path_601432, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_601433 = body
  result = call_601431.call(path_601432, nil, nil, nil, body_601433)

var tagResource* = Call_TagResource_601418(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_601419,
                                        base: "/", url: url_TagResource_601420,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601404 = ref object of OpenApiRestCall_599352
proc url_ListTagsForResource_601406(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_601405(path: JsonNode; query: JsonNode;
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
  var valid_601407 = path.getOrDefault("resource-arn")
  valid_601407 = validateParameter(valid_601407, JString, required = true,
                                 default = nil)
  if valid_601407 != nil:
    section.add "resource-arn", valid_601407
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601408 = header.getOrDefault("X-Amz-Date")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Date", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Security-Token")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Security-Token", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Content-Sha256", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Algorithm")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Algorithm", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Signature")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Signature", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-SignedHeaders", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Credential")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Credential", valid_601414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601415: Call_ListTagsForResource_601404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_601415.validator(path, query, header, formData, body)
  let scheme = call_601415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601415.url(scheme.get, call_601415.host, call_601415.base,
                         call_601415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601415, url, valid)

proc call*(call_601416: Call_ListTagsForResource_601404; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_601417 = newJObject()
  add(path_601417, "resource-arn", newJString(resourceArn))
  result = call_601416.call(path_601417, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601404(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_601405, base: "/",
    url: url_ListTagsForResource_601406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_601434 = ref object of OpenApiRestCall_599352
proc url_ListTemplates_601436(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTemplates_601435(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   template-type: JString
  ##                : The type of message template to include in the results. Valid values are: EMAIL, SMS, PUSH, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   prefix: JString
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_601437 = query.getOrDefault("template-type")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "template-type", valid_601437
  var valid_601438 = query.getOrDefault("next-token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "next-token", valid_601438
  var valid_601439 = query.getOrDefault("prefix")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "prefix", valid_601439
  var valid_601440 = query.getOrDefault("page-size")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "page-size", valid_601440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601441 = header.getOrDefault("X-Amz-Date")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Date", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Security-Token")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Security-Token", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Content-Sha256", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Algorithm")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Algorithm", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Signature")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Signature", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-SignedHeaders", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Credential")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Credential", valid_601447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601448: Call_ListTemplates_601434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_601448.validator(path, query, header, formData, body)
  let scheme = call_601448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601448.url(scheme.get, call_601448.host, call_601448.base,
                         call_601448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601448, url, valid)

proc call*(call_601449: Call_ListTemplates_601434; templateType: string = "";
          nextToken: string = ""; prefix: string = ""; pageSize: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, SMS, PUSH, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_601450 = newJObject()
  add(query_601450, "template-type", newJString(templateType))
  add(query_601450, "next-token", newJString(nextToken))
  add(query_601450, "prefix", newJString(prefix))
  add(query_601450, "page-size", newJString(pageSize))
  result = call_601449.call(nil, query_601450, nil, nil, nil)

var listTemplates* = Call_ListTemplates_601434(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_601435, base: "/",
    url: url_ListTemplates_601436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_601451 = ref object of OpenApiRestCall_599352
proc url_PhoneNumberValidate_601453(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PhoneNumberValidate_601452(path: JsonNode; query: JsonNode;
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
  var valid_601454 = header.getOrDefault("X-Amz-Date")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Date", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Security-Token")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Security-Token", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Content-Sha256", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Algorithm")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Algorithm", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Signature")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Signature", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-SignedHeaders", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Credential")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Credential", valid_601460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601462: Call_PhoneNumberValidate_601451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_601462.validator(path, query, header, formData, body)
  let scheme = call_601462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601462.url(scheme.get, call_601462.host, call_601462.base,
                         call_601462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601462, url, valid)

proc call*(call_601463: Call_PhoneNumberValidate_601451; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_601464 = newJObject()
  if body != nil:
    body_601464 = body
  result = call_601463.call(nil, nil, nil, nil, body_601464)

var phoneNumberValidate* = Call_PhoneNumberValidate_601451(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_601452, base: "/",
    url: url_PhoneNumberValidate_601453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_601465 = ref object of OpenApiRestCall_599352
proc url_PutEvents_601467(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_601466(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601468 = path.getOrDefault("application-id")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = nil)
  if valid_601468 != nil:
    section.add "application-id", valid_601468
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601469 = header.getOrDefault("X-Amz-Date")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Date", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Security-Token")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Security-Token", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Content-Sha256", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Algorithm")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Algorithm", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Signature")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Signature", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-SignedHeaders", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Credential")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Credential", valid_601475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601477: Call_PutEvents_601465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_601477.validator(path, query, header, formData, body)
  let scheme = call_601477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601477.url(scheme.get, call_601477.host, call_601477.base,
                         call_601477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601477, url, valid)

proc call*(call_601478: Call_PutEvents_601465; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601479 = newJObject()
  var body_601480 = newJObject()
  add(path_601479, "application-id", newJString(applicationId))
  if body != nil:
    body_601480 = body
  result = call_601478.call(path_601479, nil, nil, nil, body_601480)

var putEvents* = Call_PutEvents_601465(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_601466,
                                    base: "/", url: url_PutEvents_601467,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_601481 = ref object of OpenApiRestCall_599352
proc url_RemoveAttributes_601483(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_601482(path: JsonNode; query: JsonNode;
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
  var valid_601484 = path.getOrDefault("attribute-type")
  valid_601484 = validateParameter(valid_601484, JString, required = true,
                                 default = nil)
  if valid_601484 != nil:
    section.add "attribute-type", valid_601484
  var valid_601485 = path.getOrDefault("application-id")
  valid_601485 = validateParameter(valid_601485, JString, required = true,
                                 default = nil)
  if valid_601485 != nil:
    section.add "application-id", valid_601485
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601486 = header.getOrDefault("X-Amz-Date")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Date", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Security-Token")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Security-Token", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Content-Sha256", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Algorithm")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Algorithm", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Signature")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Signature", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-SignedHeaders", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Credential")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Credential", valid_601492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_RemoveAttributes_601481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601494, url, valid)

proc call*(call_601495: Call_RemoveAttributes_601481; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601496 = newJObject()
  var body_601497 = newJObject()
  add(path_601496, "attribute-type", newJString(attributeType))
  add(path_601496, "application-id", newJString(applicationId))
  if body != nil:
    body_601497 = body
  result = call_601495.call(path_601496, nil, nil, nil, body_601497)

var removeAttributes* = Call_RemoveAttributes_601481(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_601482, base: "/",
    url: url_RemoveAttributes_601483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_601498 = ref object of OpenApiRestCall_599352
proc url_SendMessages_601500(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_601499(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601501 = path.getOrDefault("application-id")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "application-id", valid_601501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601502 = header.getOrDefault("X-Amz-Date")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Date", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Security-Token")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Security-Token", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Content-Sha256", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Algorithm")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Algorithm", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Signature")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Signature", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-SignedHeaders", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Credential")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Credential", valid_601508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601510: Call_SendMessages_601498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_601510.validator(path, query, header, formData, body)
  let scheme = call_601510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601510.url(scheme.get, call_601510.host, call_601510.base,
                         call_601510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601510, url, valid)

proc call*(call_601511: Call_SendMessages_601498; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601512 = newJObject()
  var body_601513 = newJObject()
  add(path_601512, "application-id", newJString(applicationId))
  if body != nil:
    body_601513 = body
  result = call_601511.call(path_601512, nil, nil, nil, body_601513)

var sendMessages* = Call_SendMessages_601498(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_601499,
    base: "/", url: url_SendMessages_601500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_601514 = ref object of OpenApiRestCall_599352
proc url_SendUsersMessages_601516(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_601515(path: JsonNode; query: JsonNode;
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
  var valid_601517 = path.getOrDefault("application-id")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = nil)
  if valid_601517 != nil:
    section.add "application-id", valid_601517
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601518 = header.getOrDefault("X-Amz-Date")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Date", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Security-Token")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Security-Token", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Content-Sha256", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Algorithm")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Algorithm", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Signature")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Signature", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-SignedHeaders", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Credential")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Credential", valid_601524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601526: Call_SendUsersMessages_601514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_601526.validator(path, query, header, formData, body)
  let scheme = call_601526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601526.url(scheme.get, call_601526.host, call_601526.base,
                         call_601526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601526, url, valid)

proc call*(call_601527: Call_SendUsersMessages_601514; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601528 = newJObject()
  var body_601529 = newJObject()
  add(path_601528, "application-id", newJString(applicationId))
  if body != nil:
    body_601529 = body
  result = call_601527.call(path_601528, nil, nil, nil, body_601529)

var sendUsersMessages* = Call_SendUsersMessages_601514(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_601515, base: "/",
    url: url_SendUsersMessages_601516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601530 = ref object of OpenApiRestCall_599352
proc url_UntagResource_601532(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_601531(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601533 = path.getOrDefault("resource-arn")
  valid_601533 = validateParameter(valid_601533, JString, required = true,
                                 default = nil)
  if valid_601533 != nil:
    section.add "resource-arn", valid_601533
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601534 = query.getOrDefault("tagKeys")
  valid_601534 = validateParameter(valid_601534, JArray, required = true, default = nil)
  if valid_601534 != nil:
    section.add "tagKeys", valid_601534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601535 = header.getOrDefault("X-Amz-Date")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Date", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Security-Token")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Security-Token", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Content-Sha256", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Algorithm")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Algorithm", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Signature")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Signature", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-SignedHeaders", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Credential")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Credential", valid_601541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601542: Call_UntagResource_601530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_601542.validator(path, query, header, formData, body)
  let scheme = call_601542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601542.url(scheme.get, call_601542.host, call_601542.base,
                         call_601542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601542, url, valid)

proc call*(call_601543: Call_UntagResource_601530; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_601544 = newJObject()
  var query_601545 = newJObject()
  if tagKeys != nil:
    query_601545.add "tagKeys", tagKeys
  add(path_601544, "resource-arn", newJString(resourceArn))
  result = call_601543.call(path_601544, query_601545, nil, nil, nil)

var untagResource* = Call_UntagResource_601530(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_601531,
    base: "/", url: url_UntagResource_601532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_601546 = ref object of OpenApiRestCall_599352
proc url_UpdateEndpointsBatch_601548(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_601547(path: JsonNode; query: JsonNode;
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
  var valid_601549 = path.getOrDefault("application-id")
  valid_601549 = validateParameter(valid_601549, JString, required = true,
                                 default = nil)
  if valid_601549 != nil:
    section.add "application-id", valid_601549
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601550 = header.getOrDefault("X-Amz-Date")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Date", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Security-Token")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Security-Token", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Content-Sha256", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Algorithm")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Algorithm", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Signature")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Signature", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-SignedHeaders", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Credential")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Credential", valid_601556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601558: Call_UpdateEndpointsBatch_601546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_601558.validator(path, query, header, formData, body)
  let scheme = call_601558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601558.url(scheme.get, call_601558.host, call_601558.base,
                         call_601558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601558, url, valid)

proc call*(call_601559: Call_UpdateEndpointsBatch_601546; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601560 = newJObject()
  var body_601561 = newJObject()
  add(path_601560, "application-id", newJString(applicationId))
  if body != nil:
    body_601561 = body
  result = call_601559.call(path_601560, nil, nil, nil, body_601561)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_601546(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_601547, base: "/",
    url: url_UpdateEndpointsBatch_601548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_601562 = ref object of OpenApiRestCall_599352
proc url_UpdateJourneyState_601564(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_601563(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Cancels an active journey.
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
  var valid_601565 = path.getOrDefault("journey-id")
  valid_601565 = validateParameter(valid_601565, JString, required = true,
                                 default = nil)
  if valid_601565 != nil:
    section.add "journey-id", valid_601565
  var valid_601566 = path.getOrDefault("application-id")
  valid_601566 = validateParameter(valid_601566, JString, required = true,
                                 default = nil)
  if valid_601566 != nil:
    section.add "application-id", valid_601566
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601567 = header.getOrDefault("X-Amz-Date")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Date", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Security-Token")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Security-Token", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Content-Sha256", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Algorithm")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Algorithm", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Signature")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Signature", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-SignedHeaders", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Credential")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Credential", valid_601573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601575: Call_UpdateJourneyState_601562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an active journey.
  ## 
  let valid = call_601575.validator(path, query, header, formData, body)
  let scheme = call_601575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601575.url(scheme.get, call_601575.host, call_601575.base,
                         call_601575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601575, url, valid)

proc call*(call_601576: Call_UpdateJourneyState_601562; journeyId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateJourneyState
  ## Cancels an active journey.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601577 = newJObject()
  var body_601578 = newJObject()
  add(path_601577, "journey-id", newJString(journeyId))
  add(path_601577, "application-id", newJString(applicationId))
  if body != nil:
    body_601578 = body
  result = call_601576.call(path_601577, nil, nil, nil, body_601578)

var updateJourneyState* = Call_UpdateJourneyState_601562(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_601563, base: "/",
    url: url_UpdateJourneyState_601564, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
