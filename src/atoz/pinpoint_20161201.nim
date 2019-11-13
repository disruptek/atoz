
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

  OpenApiRestCall_593373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593373): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_593968 = ref object of OpenApiRestCall_593373
proc url_CreateApp_593970(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_593969(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593971 = header.getOrDefault("X-Amz-Signature")
  valid_593971 = validateParameter(valid_593971, JString, required = false,
                                 default = nil)
  if valid_593971 != nil:
    section.add "X-Amz-Signature", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Content-Sha256", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-Date")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Date", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Credential")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Credential", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Security-Token")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Security-Token", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Algorithm")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Algorithm", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-SignedHeaders", valid_593977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593979: Call_CreateApp_593968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_593979.validator(path, query, header, formData, body)
  let scheme = call_593979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593979.url(scheme.get, call_593979.host, call_593979.base,
                         call_593979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593979, url, valid)

proc call*(call_593980: Call_CreateApp_593968; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_593981 = newJObject()
  if body != nil:
    body_593981 = body
  result = call_593980.call(nil, nil, nil, nil, body_593981)

var createApp* = Call_CreateApp_593968(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_593969,
                                    base: "/", url: url_CreateApp_593970,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_593711 = ref object of OpenApiRestCall_593373
proc url_GetApps_593713(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApps_593712(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all of your applications.
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
  var valid_593825 = query.getOrDefault("page-size")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "page-size", valid_593825
  var valid_593826 = query.getOrDefault("token")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "token", valid_593826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593827 = header.getOrDefault("X-Amz-Signature")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "X-Amz-Signature", valid_593827
  var valid_593828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593828 = validateParameter(valid_593828, JString, required = false,
                                 default = nil)
  if valid_593828 != nil:
    section.add "X-Amz-Content-Sha256", valid_593828
  var valid_593829 = header.getOrDefault("X-Amz-Date")
  valid_593829 = validateParameter(valid_593829, JString, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "X-Amz-Date", valid_593829
  var valid_593830 = header.getOrDefault("X-Amz-Credential")
  valid_593830 = validateParameter(valid_593830, JString, required = false,
                                 default = nil)
  if valid_593830 != nil:
    section.add "X-Amz-Credential", valid_593830
  var valid_593831 = header.getOrDefault("X-Amz-Security-Token")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-Security-Token", valid_593831
  var valid_593832 = header.getOrDefault("X-Amz-Algorithm")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "X-Amz-Algorithm", valid_593832
  var valid_593833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-SignedHeaders", valid_593833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593856: Call_GetApps_593711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_593856.validator(path, query, header, formData, body)
  let scheme = call_593856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593856.url(scheme.get, call_593856.host, call_593856.base,
                         call_593856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593856, url, valid)

proc call*(call_593927: Call_GetApps_593711; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_593928 = newJObject()
  add(query_593928, "page-size", newJString(pageSize))
  add(query_593928, "token", newJString(token))
  result = call_593927.call(nil, query_593928, nil, nil, nil)

var getApps* = Call_GetApps_593711(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_593712, base: "/",
                                url: url_GetApps_593713,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_594013 = ref object of OpenApiRestCall_593373
proc url_CreateCampaign_594015(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_594014(path: JsonNode; query: JsonNode;
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
  var valid_594016 = path.getOrDefault("application-id")
  valid_594016 = validateParameter(valid_594016, JString, required = true,
                                 default = nil)
  if valid_594016 != nil:
    section.add "application-id", valid_594016
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594017 = header.getOrDefault("X-Amz-Signature")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Signature", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Content-Sha256", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Date")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Date", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Credential")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Credential", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Security-Token")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Security-Token", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Algorithm")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Algorithm", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-SignedHeaders", valid_594023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594025: Call_CreateCampaign_594013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_594025.validator(path, query, header, formData, body)
  let scheme = call_594025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594025.url(scheme.get, call_594025.host, call_594025.base,
                         call_594025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594025, url, valid)

proc call*(call_594026: Call_CreateCampaign_594013; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594027 = newJObject()
  var body_594028 = newJObject()
  add(path_594027, "application-id", newJString(applicationId))
  if body != nil:
    body_594028 = body
  result = call_594026.call(path_594027, nil, nil, nil, body_594028)

var createCampaign* = Call_CreateCampaign_594013(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_594014, base: "/", url: url_CreateCampaign_594015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_593982 = ref object of OpenApiRestCall_593373
proc url_GetCampaigns_593984(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_593983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593999 = path.getOrDefault("application-id")
  valid_593999 = validateParameter(valid_593999, JString, required = true,
                                 default = nil)
  if valid_593999 != nil:
    section.add "application-id", valid_593999
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_594000 = query.getOrDefault("page-size")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "page-size", valid_594000
  var valid_594001 = query.getOrDefault("token")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "token", valid_594001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594002 = header.getOrDefault("X-Amz-Signature")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Signature", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Content-Sha256", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Date")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Date", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Credential")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Credential", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Security-Token")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Security-Token", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Algorithm")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Algorithm", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-SignedHeaders", valid_594008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594009: Call_GetCampaigns_593982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_594009.validator(path, query, header, formData, body)
  let scheme = call_594009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594009.url(scheme.get, call_594009.host, call_594009.base,
                         call_594009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594009, url, valid)

proc call*(call_594010: Call_GetCampaigns_593982; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_594011 = newJObject()
  var query_594012 = newJObject()
  add(path_594011, "application-id", newJString(applicationId))
  add(query_594012, "page-size", newJString(pageSize))
  add(query_594012, "token", newJString(token))
  result = call_594010.call(path_594011, query_594012, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_593982(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_593983, base: "/", url: url_GetCampaigns_593984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_594043 = ref object of OpenApiRestCall_593373
proc url_UpdateEmailTemplate_594045(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_594044(path: JsonNode; query: JsonNode;
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
  var valid_594046 = path.getOrDefault("template-name")
  valid_594046 = validateParameter(valid_594046, JString, required = true,
                                 default = nil)
  if valid_594046 != nil:
    section.add "template-name", valid_594046
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594047 = header.getOrDefault("X-Amz-Signature")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Signature", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Content-Sha256", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Date")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Date", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Credential")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Credential", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Security-Token")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Security-Token", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Algorithm")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Algorithm", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-SignedHeaders", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_UpdateEmailTemplate_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_UpdateEmailTemplate_594043; templateName: string;
          body: JsonNode): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594057 = newJObject()
  var body_594058 = newJObject()
  add(path_594057, "template-name", newJString(templateName))
  if body != nil:
    body_594058 = body
  result = call_594056.call(path_594057, nil, nil, nil, body_594058)

var updateEmailTemplate* = Call_UpdateEmailTemplate_594043(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_594044, base: "/",
    url: url_UpdateEmailTemplate_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_594059 = ref object of OpenApiRestCall_593373
proc url_CreateEmailTemplate_594061(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_594060(path: JsonNode; query: JsonNode;
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
  var valid_594062 = path.getOrDefault("template-name")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = nil)
  if valid_594062 != nil:
    section.add "template-name", valid_594062
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594063 = header.getOrDefault("X-Amz-Signature")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Signature", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Date")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Date", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Credential")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Credential", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Security-Token")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Security-Token", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Algorithm")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Algorithm", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_CreateEmailTemplate_594059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_CreateEmailTemplate_594059; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594073 = newJObject()
  var body_594074 = newJObject()
  add(path_594073, "template-name", newJString(templateName))
  if body != nil:
    body_594074 = body
  result = call_594072.call(path_594073, nil, nil, nil, body_594074)

var createEmailTemplate* = Call_CreateEmailTemplate_594059(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_594060, base: "/",
    url: url_CreateEmailTemplate_594061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_594029 = ref object of OpenApiRestCall_593373
proc url_GetEmailTemplate_594031(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_594030(path: JsonNode; query: JsonNode;
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
  var valid_594032 = path.getOrDefault("template-name")
  valid_594032 = validateParameter(valid_594032, JString, required = true,
                                 default = nil)
  if valid_594032 != nil:
    section.add "template-name", valid_594032
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594033 = header.getOrDefault("X-Amz-Signature")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Signature", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Content-Sha256", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Credential")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Credential", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Security-Token")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Security-Token", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-SignedHeaders", valid_594039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594040: Call_GetEmailTemplate_594029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_594040.validator(path, query, header, formData, body)
  let scheme = call_594040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594040.url(scheme.get, call_594040.host, call_594040.base,
                         call_594040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594040, url, valid)

proc call*(call_594041: Call_GetEmailTemplate_594029; templateName: string): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594042 = newJObject()
  add(path_594042, "template-name", newJString(templateName))
  result = call_594041.call(path_594042, nil, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_594029(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_594030, base: "/",
    url: url_GetEmailTemplate_594031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_594075 = ref object of OpenApiRestCall_593373
proc url_DeleteEmailTemplate_594077(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_594076(path: JsonNode; query: JsonNode;
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
  var valid_594078 = path.getOrDefault("template-name")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "template-name", valid_594078
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594079 = header.getOrDefault("X-Amz-Signature")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Signature", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Date")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Date", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Credential")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Credential", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Security-Token")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Security-Token", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Algorithm")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Algorithm", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-SignedHeaders", valid_594085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_DeleteEmailTemplate_594075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_DeleteEmailTemplate_594075; templateName: string): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594088 = newJObject()
  add(path_594088, "template-name", newJString(templateName))
  result = call_594087.call(path_594088, nil, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_594075(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_594076, base: "/",
    url: url_DeleteEmailTemplate_594077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_594106 = ref object of OpenApiRestCall_593373
proc url_CreateExportJob_594108(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_594107(path: JsonNode; query: JsonNode;
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
  var valid_594109 = path.getOrDefault("application-id")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = nil)
  if valid_594109 != nil:
    section.add "application-id", valid_594109
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Date")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Date", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Security-Token")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Security-Token", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Algorithm")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Algorithm", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-SignedHeaders", valid_594116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594118: Call_CreateExportJob_594106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_594118.validator(path, query, header, formData, body)
  let scheme = call_594118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594118.url(scheme.get, call_594118.host, call_594118.base,
                         call_594118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594118, url, valid)

proc call*(call_594119: Call_CreateExportJob_594106; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594120 = newJObject()
  var body_594121 = newJObject()
  add(path_594120, "application-id", newJString(applicationId))
  if body != nil:
    body_594121 = body
  result = call_594119.call(path_594120, nil, nil, nil, body_594121)

var createExportJob* = Call_CreateExportJob_594106(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_594107, base: "/", url: url_CreateExportJob_594108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_594089 = ref object of OpenApiRestCall_593373
proc url_GetExportJobs_594091(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_594090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594092 = path.getOrDefault("application-id")
  valid_594092 = validateParameter(valid_594092, JString, required = true,
                                 default = nil)
  if valid_594092 != nil:
    section.add "application-id", valid_594092
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_594093 = query.getOrDefault("page-size")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "page-size", valid_594093
  var valid_594094 = query.getOrDefault("token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "token", valid_594094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594095 = header.getOrDefault("X-Amz-Signature")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Signature", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Content-Sha256", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Date")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Date", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Security-Token")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Security-Token", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Algorithm")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Algorithm", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-SignedHeaders", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_GetExportJobs_594089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_GetExportJobs_594089; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_594104 = newJObject()
  var query_594105 = newJObject()
  add(path_594104, "application-id", newJString(applicationId))
  add(query_594105, "page-size", newJString(pageSize))
  add(query_594105, "token", newJString(token))
  result = call_594103.call(path_594104, query_594105, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_594089(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_594090, base: "/", url: url_GetExportJobs_594091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_594139 = ref object of OpenApiRestCall_593373
proc url_CreateImportJob_594141(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_594140(path: JsonNode; query: JsonNode;
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
  var valid_594142 = path.getOrDefault("application-id")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "application-id", valid_594142
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594143 = header.getOrDefault("X-Amz-Signature")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Signature", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Content-Sha256", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Date")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Date", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Credential")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Credential", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Security-Token")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Security-Token", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Algorithm")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Algorithm", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-SignedHeaders", valid_594149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594151: Call_CreateImportJob_594139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_594151.validator(path, query, header, formData, body)
  let scheme = call_594151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594151.url(scheme.get, call_594151.host, call_594151.base,
                         call_594151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594151, url, valid)

proc call*(call_594152: Call_CreateImportJob_594139; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594153 = newJObject()
  var body_594154 = newJObject()
  add(path_594153, "application-id", newJString(applicationId))
  if body != nil:
    body_594154 = body
  result = call_594152.call(path_594153, nil, nil, nil, body_594154)

var createImportJob* = Call_CreateImportJob_594139(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_594140, base: "/", url: url_CreateImportJob_594141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_594122 = ref object of OpenApiRestCall_593373
proc url_GetImportJobs_594124(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_594123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594125 = path.getOrDefault("application-id")
  valid_594125 = validateParameter(valid_594125, JString, required = true,
                                 default = nil)
  if valid_594125 != nil:
    section.add "application-id", valid_594125
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_594126 = query.getOrDefault("page-size")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "page-size", valid_594126
  var valid_594127 = query.getOrDefault("token")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "token", valid_594127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594128 = header.getOrDefault("X-Amz-Signature")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Signature", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Content-Sha256", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-SignedHeaders", valid_594134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594135: Call_GetImportJobs_594122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_594135.validator(path, query, header, formData, body)
  let scheme = call_594135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594135.url(scheme.get, call_594135.host, call_594135.base,
                         call_594135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594135, url, valid)

proc call*(call_594136: Call_GetImportJobs_594122; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_594137 = newJObject()
  var query_594138 = newJObject()
  add(path_594137, "application-id", newJString(applicationId))
  add(query_594138, "page-size", newJString(pageSize))
  add(query_594138, "token", newJString(token))
  result = call_594136.call(path_594137, query_594138, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_594122(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_594123, base: "/", url: url_GetImportJobs_594124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_594172 = ref object of OpenApiRestCall_593373
proc url_CreateJourney_594174(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_594173(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594175 = path.getOrDefault("application-id")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "application-id", valid_594175
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594176 = header.getOrDefault("X-Amz-Signature")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Signature", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Content-Sha256", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Credential")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Credential", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Security-Token")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Security-Token", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-SignedHeaders", valid_594182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594184: Call_CreateJourney_594172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_594184.validator(path, query, header, formData, body)
  let scheme = call_594184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594184.url(scheme.get, call_594184.host, call_594184.base,
                         call_594184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594184, url, valid)

proc call*(call_594185: Call_CreateJourney_594172; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594186 = newJObject()
  var body_594187 = newJObject()
  add(path_594186, "application-id", newJString(applicationId))
  if body != nil:
    body_594187 = body
  result = call_594185.call(path_594186, nil, nil, nil, body_594187)

var createJourney* = Call_CreateJourney_594172(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_594173, base: "/", url: url_CreateJourney_594174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_594155 = ref object of OpenApiRestCall_593373
proc url_ListJourneys_594157(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_594156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594158 = path.getOrDefault("application-id")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = nil)
  if valid_594158 != nil:
    section.add "application-id", valid_594158
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_594159 = query.getOrDefault("page-size")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "page-size", valid_594159
  var valid_594160 = query.getOrDefault("token")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "token", valid_594160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594161 = header.getOrDefault("X-Amz-Signature")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Signature", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Content-Sha256", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Date")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Date", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Credential")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Credential", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Security-Token")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Security-Token", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Algorithm")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Algorithm", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-SignedHeaders", valid_594167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_ListJourneys_594155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_ListJourneys_594155; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_594170 = newJObject()
  var query_594171 = newJObject()
  add(path_594170, "application-id", newJString(applicationId))
  add(query_594171, "page-size", newJString(pageSize))
  add(query_594171, "token", newJString(token))
  result = call_594169.call(path_594170, query_594171, nil, nil, nil)

var listJourneys* = Call_ListJourneys_594155(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_594156,
    base: "/", url: url_ListJourneys_594157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_594202 = ref object of OpenApiRestCall_593373
proc url_UpdatePushTemplate_594204(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_594203(path: JsonNode; query: JsonNode;
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
  var valid_594205 = path.getOrDefault("template-name")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = nil)
  if valid_594205 != nil:
    section.add "template-name", valid_594205
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594206 = header.getOrDefault("X-Amz-Signature")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Signature", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Date")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Date", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Credential")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Credential", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Algorithm")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Algorithm", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-SignedHeaders", valid_594212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594214: Call_UpdatePushTemplate_594202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_594214.validator(path, query, header, formData, body)
  let scheme = call_594214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594214.url(scheme.get, call_594214.host, call_594214.base,
                         call_594214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594214, url, valid)

proc call*(call_594215: Call_UpdatePushTemplate_594202; templateName: string;
          body: JsonNode): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594216 = newJObject()
  var body_594217 = newJObject()
  add(path_594216, "template-name", newJString(templateName))
  if body != nil:
    body_594217 = body
  result = call_594215.call(path_594216, nil, nil, nil, body_594217)

var updatePushTemplate* = Call_UpdatePushTemplate_594202(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_594203, base: "/",
    url: url_UpdatePushTemplate_594204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_594218 = ref object of OpenApiRestCall_593373
proc url_CreatePushTemplate_594220(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_594219(path: JsonNode; query: JsonNode;
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
  var valid_594221 = path.getOrDefault("template-name")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "template-name", valid_594221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594222 = header.getOrDefault("X-Amz-Signature")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Signature", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Content-Sha256", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Date")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Date", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Credential")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Credential", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Security-Token")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Security-Token", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Algorithm")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Algorithm", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-SignedHeaders", valid_594228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_CreatePushTemplate_594218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_CreatePushTemplate_594218; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594232 = newJObject()
  var body_594233 = newJObject()
  add(path_594232, "template-name", newJString(templateName))
  if body != nil:
    body_594233 = body
  result = call_594231.call(path_594232, nil, nil, nil, body_594233)

var createPushTemplate* = Call_CreatePushTemplate_594218(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_594219, base: "/",
    url: url_CreatePushTemplate_594220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_594188 = ref object of OpenApiRestCall_593373
proc url_GetPushTemplate_594190(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_594189(path: JsonNode; query: JsonNode;
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
  var valid_594191 = path.getOrDefault("template-name")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = nil)
  if valid_594191 != nil:
    section.add "template-name", valid_594191
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594192 = header.getOrDefault("X-Amz-Signature")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Signature", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Date")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Date", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Credential")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Credential", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Security-Token")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Security-Token", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Algorithm")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Algorithm", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-SignedHeaders", valid_594198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594199: Call_GetPushTemplate_594188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_594199.validator(path, query, header, formData, body)
  let scheme = call_594199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594199.url(scheme.get, call_594199.host, call_594199.base,
                         call_594199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594199, url, valid)

proc call*(call_594200: Call_GetPushTemplate_594188; templateName: string): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594201 = newJObject()
  add(path_594201, "template-name", newJString(templateName))
  result = call_594200.call(path_594201, nil, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_594188(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_594189, base: "/", url: url_GetPushTemplate_594190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_594234 = ref object of OpenApiRestCall_593373
proc url_DeletePushTemplate_594236(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_594235(path: JsonNode; query: JsonNode;
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
  var valid_594237 = path.getOrDefault("template-name")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = nil)
  if valid_594237 != nil:
    section.add "template-name", valid_594237
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594238 = header.getOrDefault("X-Amz-Signature")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Signature", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Content-Sha256", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Date")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Date", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Credential")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Credential", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Algorithm")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Algorithm", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-SignedHeaders", valid_594244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594245: Call_DeletePushTemplate_594234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ## 
  let valid = call_594245.validator(path, query, header, formData, body)
  let scheme = call_594245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594245.url(scheme.get, call_594245.host, call_594245.base,
                         call_594245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594245, url, valid)

proc call*(call_594246: Call_DeletePushTemplate_594234; templateName: string): Recallable =
  ## deletePushTemplate
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594247 = newJObject()
  add(path_594247, "template-name", newJString(templateName))
  result = call_594246.call(path_594247, nil, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_594234(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_594235, base: "/",
    url: url_DeletePushTemplate_594236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_594265 = ref object of OpenApiRestCall_593373
proc url_CreateSegment_594267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_594266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594268 = path.getOrDefault("application-id")
  valid_594268 = validateParameter(valid_594268, JString, required = true,
                                 default = nil)
  if valid_594268 != nil:
    section.add "application-id", valid_594268
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594269 = header.getOrDefault("X-Amz-Signature")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Signature", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Content-Sha256", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Credential")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Credential", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Security-Token")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Security-Token", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Algorithm")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Algorithm", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-SignedHeaders", valid_594275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594277: Call_CreateSegment_594265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_594277.validator(path, query, header, formData, body)
  let scheme = call_594277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594277.url(scheme.get, call_594277.host, call_594277.base,
                         call_594277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594277, url, valid)

proc call*(call_594278: Call_CreateSegment_594265; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594279 = newJObject()
  var body_594280 = newJObject()
  add(path_594279, "application-id", newJString(applicationId))
  if body != nil:
    body_594280 = body
  result = call_594278.call(path_594279, nil, nil, nil, body_594280)

var createSegment* = Call_CreateSegment_594265(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_594266, base: "/", url: url_CreateSegment_594267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_594248 = ref object of OpenApiRestCall_593373
proc url_GetSegments_594250(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_594249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594251 = path.getOrDefault("application-id")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = nil)
  if valid_594251 != nil:
    section.add "application-id", valid_594251
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_594252 = query.getOrDefault("page-size")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "page-size", valid_594252
  var valid_594253 = query.getOrDefault("token")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "token", valid_594253
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Content-Sha256", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Credential")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Credential", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Security-Token")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Security-Token", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Algorithm")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Algorithm", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-SignedHeaders", valid_594260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594261: Call_GetSegments_594248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_594261.validator(path, query, header, formData, body)
  let scheme = call_594261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594261.url(scheme.get, call_594261.host, call_594261.base,
                         call_594261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594261, url, valid)

proc call*(call_594262: Call_GetSegments_594248; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_594263 = newJObject()
  var query_594264 = newJObject()
  add(path_594263, "application-id", newJString(applicationId))
  add(query_594264, "page-size", newJString(pageSize))
  add(query_594264, "token", newJString(token))
  result = call_594262.call(path_594263, query_594264, nil, nil, nil)

var getSegments* = Call_GetSegments_594248(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_594249,
                                        base: "/", url: url_GetSegments_594250,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_594295 = ref object of OpenApiRestCall_593373
proc url_UpdateSmsTemplate_594297(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_594296(path: JsonNode; query: JsonNode;
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
  var valid_594298 = path.getOrDefault("template-name")
  valid_594298 = validateParameter(valid_594298, JString, required = true,
                                 default = nil)
  if valid_594298 != nil:
    section.add "template-name", valid_594298
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594299 = header.getOrDefault("X-Amz-Signature")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Signature", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Content-Sha256", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Credential")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Credential", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Security-Token")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Security-Token", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Algorithm")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Algorithm", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-SignedHeaders", valid_594305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594307: Call_UpdateSmsTemplate_594295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_594307.validator(path, query, header, formData, body)
  let scheme = call_594307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594307.url(scheme.get, call_594307.host, call_594307.base,
                         call_594307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594307, url, valid)

proc call*(call_594308: Call_UpdateSmsTemplate_594295; templateName: string;
          body: JsonNode): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594309 = newJObject()
  var body_594310 = newJObject()
  add(path_594309, "template-name", newJString(templateName))
  if body != nil:
    body_594310 = body
  result = call_594308.call(path_594309, nil, nil, nil, body_594310)

var updateSmsTemplate* = Call_UpdateSmsTemplate_594295(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_594296, base: "/",
    url: url_UpdateSmsTemplate_594297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_594311 = ref object of OpenApiRestCall_593373
proc url_CreateSmsTemplate_594313(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_594312(path: JsonNode; query: JsonNode;
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
  var valid_594314 = path.getOrDefault("template-name")
  valid_594314 = validateParameter(valid_594314, JString, required = true,
                                 default = nil)
  if valid_594314 != nil:
    section.add "template-name", valid_594314
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594315 = header.getOrDefault("X-Amz-Signature")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Signature", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Content-Sha256", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Date")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Date", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Credential")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Credential", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Security-Token")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Security-Token", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-SignedHeaders", valid_594321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_CreateSmsTemplate_594311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_CreateSmsTemplate_594311; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_594325 = newJObject()
  var body_594326 = newJObject()
  add(path_594325, "template-name", newJString(templateName))
  if body != nil:
    body_594326 = body
  result = call_594324.call(path_594325, nil, nil, nil, body_594326)

var createSmsTemplate* = Call_CreateSmsTemplate_594311(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_594312, base: "/",
    url: url_CreateSmsTemplate_594313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_594281 = ref object of OpenApiRestCall_593373
proc url_GetSmsTemplate_594283(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_594282(path: JsonNode; query: JsonNode;
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
  var valid_594284 = path.getOrDefault("template-name")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = nil)
  if valid_594284 != nil:
    section.add "template-name", valid_594284
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Content-Sha256", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Credential")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Credential", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Security-Token")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Security-Token", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594292: Call_GetSmsTemplate_594281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_594292.validator(path, query, header, formData, body)
  let scheme = call_594292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594292.url(scheme.get, call_594292.host, call_594292.base,
                         call_594292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594292, url, valid)

proc call*(call_594293: Call_GetSmsTemplate_594281; templateName: string): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594294 = newJObject()
  add(path_594294, "template-name", newJString(templateName))
  result = call_594293.call(path_594294, nil, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_594281(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_594282, base: "/", url: url_GetSmsTemplate_594283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_594327 = ref object of OpenApiRestCall_593373
proc url_DeleteSmsTemplate_594329(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_594328(path: JsonNode; query: JsonNode;
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
  var valid_594330 = path.getOrDefault("template-name")
  valid_594330 = validateParameter(valid_594330, JString, required = true,
                                 default = nil)
  if valid_594330 != nil:
    section.add "template-name", valid_594330
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594331 = header.getOrDefault("X-Amz-Signature")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Signature", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Date")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Date", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Credential")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Credential", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Security-Token")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Security-Token", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Algorithm")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Algorithm", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_DeleteSmsTemplate_594327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_DeleteSmsTemplate_594327; templateName: string): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_594340 = newJObject()
  add(path_594340, "template-name", newJString(templateName))
  result = call_594339.call(path_594340, nil, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_594327(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_594328, base: "/",
    url: url_DeleteSmsTemplate_594329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_594355 = ref object of OpenApiRestCall_593373
proc url_UpdateAdmChannel_594357(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_594356(path: JsonNode; query: JsonNode;
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
  var valid_594358 = path.getOrDefault("application-id")
  valid_594358 = validateParameter(valid_594358, JString, required = true,
                                 default = nil)
  if valid_594358 != nil:
    section.add "application-id", valid_594358
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594359 = header.getOrDefault("X-Amz-Signature")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Signature", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Content-Sha256", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Credential")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Credential", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Security-Token")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Security-Token", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Algorithm")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Algorithm", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-SignedHeaders", valid_594365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594367: Call_UpdateAdmChannel_594355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_594367.validator(path, query, header, formData, body)
  let scheme = call_594367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594367.url(scheme.get, call_594367.host, call_594367.base,
                         call_594367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594367, url, valid)

proc call*(call_594368: Call_UpdateAdmChannel_594355; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594369 = newJObject()
  var body_594370 = newJObject()
  add(path_594369, "application-id", newJString(applicationId))
  if body != nil:
    body_594370 = body
  result = call_594368.call(path_594369, nil, nil, nil, body_594370)

var updateAdmChannel* = Call_UpdateAdmChannel_594355(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_594356, base: "/",
    url: url_UpdateAdmChannel_594357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_594341 = ref object of OpenApiRestCall_593373
proc url_GetAdmChannel_594343(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_594342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594344 = path.getOrDefault("application-id")
  valid_594344 = validateParameter(valid_594344, JString, required = true,
                                 default = nil)
  if valid_594344 != nil:
    section.add "application-id", valid_594344
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594345 = header.getOrDefault("X-Amz-Signature")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Signature", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Content-Sha256", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Date")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Date", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Credential")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Credential", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Security-Token")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Security-Token", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-SignedHeaders", valid_594351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594352: Call_GetAdmChannel_594341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_594352.validator(path, query, header, formData, body)
  let scheme = call_594352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594352.url(scheme.get, call_594352.host, call_594352.base,
                         call_594352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594352, url, valid)

proc call*(call_594353: Call_GetAdmChannel_594341; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594354 = newJObject()
  add(path_594354, "application-id", newJString(applicationId))
  result = call_594353.call(path_594354, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_594341(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_594342, base: "/", url: url_GetAdmChannel_594343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_594371 = ref object of OpenApiRestCall_593373
proc url_DeleteAdmChannel_594373(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_594372(path: JsonNode; query: JsonNode;
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
  var valid_594374 = path.getOrDefault("application-id")
  valid_594374 = validateParameter(valid_594374, JString, required = true,
                                 default = nil)
  if valid_594374 != nil:
    section.add "application-id", valid_594374
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594375 = header.getOrDefault("X-Amz-Signature")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Signature", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Content-Sha256", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Date")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Date", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Credential")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Credential", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Security-Token")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Security-Token", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-SignedHeaders", valid_594381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594382: Call_DeleteAdmChannel_594371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594382.validator(path, query, header, formData, body)
  let scheme = call_594382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594382.url(scheme.get, call_594382.host, call_594382.base,
                         call_594382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594382, url, valid)

proc call*(call_594383: Call_DeleteAdmChannel_594371; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594384 = newJObject()
  add(path_594384, "application-id", newJString(applicationId))
  result = call_594383.call(path_594384, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_594371(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_594372, base: "/",
    url: url_DeleteAdmChannel_594373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_594399 = ref object of OpenApiRestCall_593373
proc url_UpdateApnsChannel_594401(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_594400(path: JsonNode; query: JsonNode;
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
  var valid_594402 = path.getOrDefault("application-id")
  valid_594402 = validateParameter(valid_594402, JString, required = true,
                                 default = nil)
  if valid_594402 != nil:
    section.add "application-id", valid_594402
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594403 = header.getOrDefault("X-Amz-Signature")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Signature", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Content-Sha256", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Date")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Date", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Credential")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Credential", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Algorithm")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Algorithm", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-SignedHeaders", valid_594409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594411: Call_UpdateApnsChannel_594399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_594411.validator(path, query, header, formData, body)
  let scheme = call_594411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594411.url(scheme.get, call_594411.host, call_594411.base,
                         call_594411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594411, url, valid)

proc call*(call_594412: Call_UpdateApnsChannel_594399; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594413 = newJObject()
  var body_594414 = newJObject()
  add(path_594413, "application-id", newJString(applicationId))
  if body != nil:
    body_594414 = body
  result = call_594412.call(path_594413, nil, nil, nil, body_594414)

var updateApnsChannel* = Call_UpdateApnsChannel_594399(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_594400, base: "/",
    url: url_UpdateApnsChannel_594401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_594385 = ref object of OpenApiRestCall_593373
proc url_GetApnsChannel_594387(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_594386(path: JsonNode; query: JsonNode;
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
  var valid_594388 = path.getOrDefault("application-id")
  valid_594388 = validateParameter(valid_594388, JString, required = true,
                                 default = nil)
  if valid_594388 != nil:
    section.add "application-id", valid_594388
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594389 = header.getOrDefault("X-Amz-Signature")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Signature", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Content-Sha256", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Credential")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Credential", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Algorithm")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Algorithm", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-SignedHeaders", valid_594395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594396: Call_GetApnsChannel_594385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_594396.validator(path, query, header, formData, body)
  let scheme = call_594396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594396.url(scheme.get, call_594396.host, call_594396.base,
                         call_594396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594396, url, valid)

proc call*(call_594397: Call_GetApnsChannel_594385; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594398 = newJObject()
  add(path_594398, "application-id", newJString(applicationId))
  result = call_594397.call(path_594398, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_594385(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_594386, base: "/", url: url_GetApnsChannel_594387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_594415 = ref object of OpenApiRestCall_593373
proc url_DeleteApnsChannel_594417(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_594416(path: JsonNode; query: JsonNode;
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
  var valid_594418 = path.getOrDefault("application-id")
  valid_594418 = validateParameter(valid_594418, JString, required = true,
                                 default = nil)
  if valid_594418 != nil:
    section.add "application-id", valid_594418
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594419 = header.getOrDefault("X-Amz-Signature")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Signature", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Content-Sha256", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Credential")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Credential", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Security-Token")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Security-Token", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Algorithm")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Algorithm", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-SignedHeaders", valid_594425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594426: Call_DeleteApnsChannel_594415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594426.validator(path, query, header, formData, body)
  let scheme = call_594426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594426.url(scheme.get, call_594426.host, call_594426.base,
                         call_594426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594426, url, valid)

proc call*(call_594427: Call_DeleteApnsChannel_594415; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594428 = newJObject()
  add(path_594428, "application-id", newJString(applicationId))
  result = call_594427.call(path_594428, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_594415(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_594416, base: "/",
    url: url_DeleteApnsChannel_594417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_594443 = ref object of OpenApiRestCall_593373
proc url_UpdateApnsSandboxChannel_594445(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_594444(path: JsonNode; query: JsonNode;
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
  var valid_594446 = path.getOrDefault("application-id")
  valid_594446 = validateParameter(valid_594446, JString, required = true,
                                 default = nil)
  if valid_594446 != nil:
    section.add "application-id", valid_594446
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594447 = header.getOrDefault("X-Amz-Signature")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Signature", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Content-Sha256", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Date")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Date", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Credential")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Credential", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Security-Token")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Security-Token", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Algorithm")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Algorithm", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-SignedHeaders", valid_594453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594455: Call_UpdateApnsSandboxChannel_594443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_594455.validator(path, query, header, formData, body)
  let scheme = call_594455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594455.url(scheme.get, call_594455.host, call_594455.base,
                         call_594455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594455, url, valid)

proc call*(call_594456: Call_UpdateApnsSandboxChannel_594443;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594457 = newJObject()
  var body_594458 = newJObject()
  add(path_594457, "application-id", newJString(applicationId))
  if body != nil:
    body_594458 = body
  result = call_594456.call(path_594457, nil, nil, nil, body_594458)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_594443(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_594444, base: "/",
    url: url_UpdateApnsSandboxChannel_594445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_594429 = ref object of OpenApiRestCall_593373
proc url_GetApnsSandboxChannel_594431(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_594430(path: JsonNode; query: JsonNode;
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
  var valid_594432 = path.getOrDefault("application-id")
  valid_594432 = validateParameter(valid_594432, JString, required = true,
                                 default = nil)
  if valid_594432 != nil:
    section.add "application-id", valid_594432
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594433 = header.getOrDefault("X-Amz-Signature")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Signature", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Content-Sha256", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Date")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Date", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Credential")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Credential", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Security-Token")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Security-Token", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Algorithm")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Algorithm", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-SignedHeaders", valid_594439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594440: Call_GetApnsSandboxChannel_594429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_594440.validator(path, query, header, formData, body)
  let scheme = call_594440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594440.url(scheme.get, call_594440.host, call_594440.base,
                         call_594440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594440, url, valid)

proc call*(call_594441: Call_GetApnsSandboxChannel_594429; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594442 = newJObject()
  add(path_594442, "application-id", newJString(applicationId))
  result = call_594441.call(path_594442, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_594429(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_594430, base: "/",
    url: url_GetApnsSandboxChannel_594431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_594459 = ref object of OpenApiRestCall_593373
proc url_DeleteApnsSandboxChannel_594461(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_594460(path: JsonNode; query: JsonNode;
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
  var valid_594462 = path.getOrDefault("application-id")
  valid_594462 = validateParameter(valid_594462, JString, required = true,
                                 default = nil)
  if valid_594462 != nil:
    section.add "application-id", valid_594462
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594463 = header.getOrDefault("X-Amz-Signature")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Signature", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Content-Sha256", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Date")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Date", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Credential")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Credential", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-Algorithm")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Algorithm", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-SignedHeaders", valid_594469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594470: Call_DeleteApnsSandboxChannel_594459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594470.validator(path, query, header, formData, body)
  let scheme = call_594470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594470.url(scheme.get, call_594470.host, call_594470.base,
                         call_594470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594470, url, valid)

proc call*(call_594471: Call_DeleteApnsSandboxChannel_594459; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594472 = newJObject()
  add(path_594472, "application-id", newJString(applicationId))
  result = call_594471.call(path_594472, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_594459(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_594460, base: "/",
    url: url_DeleteApnsSandboxChannel_594461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_594487 = ref object of OpenApiRestCall_593373
proc url_UpdateApnsVoipChannel_594489(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_594488(path: JsonNode; query: JsonNode;
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
  var valid_594490 = path.getOrDefault("application-id")
  valid_594490 = validateParameter(valid_594490, JString, required = true,
                                 default = nil)
  if valid_594490 != nil:
    section.add "application-id", valid_594490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594491 = header.getOrDefault("X-Amz-Signature")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Signature", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Content-Sha256", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Date")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Date", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Credential")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Credential", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Security-Token")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Security-Token", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Algorithm")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Algorithm", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-SignedHeaders", valid_594497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594499: Call_UpdateApnsVoipChannel_594487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_594499.validator(path, query, header, formData, body)
  let scheme = call_594499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594499.url(scheme.get, call_594499.host, call_594499.base,
                         call_594499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594499, url, valid)

proc call*(call_594500: Call_UpdateApnsVoipChannel_594487; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594501 = newJObject()
  var body_594502 = newJObject()
  add(path_594501, "application-id", newJString(applicationId))
  if body != nil:
    body_594502 = body
  result = call_594500.call(path_594501, nil, nil, nil, body_594502)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_594487(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_594488, base: "/",
    url: url_UpdateApnsVoipChannel_594489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_594473 = ref object of OpenApiRestCall_593373
proc url_GetApnsVoipChannel_594475(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_594474(path: JsonNode; query: JsonNode;
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
  var valid_594476 = path.getOrDefault("application-id")
  valid_594476 = validateParameter(valid_594476, JString, required = true,
                                 default = nil)
  if valid_594476 != nil:
    section.add "application-id", valid_594476
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594477 = header.getOrDefault("X-Amz-Signature")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Signature", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Content-Sha256", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Date")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Date", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Credential")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Credential", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Security-Token")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Security-Token", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Algorithm")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Algorithm", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-SignedHeaders", valid_594483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594484: Call_GetApnsVoipChannel_594473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_594484.validator(path, query, header, formData, body)
  let scheme = call_594484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594484.url(scheme.get, call_594484.host, call_594484.base,
                         call_594484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594484, url, valid)

proc call*(call_594485: Call_GetApnsVoipChannel_594473; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594486 = newJObject()
  add(path_594486, "application-id", newJString(applicationId))
  result = call_594485.call(path_594486, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_594473(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_594474, base: "/",
    url: url_GetApnsVoipChannel_594475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_594503 = ref object of OpenApiRestCall_593373
proc url_DeleteApnsVoipChannel_594505(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_594504(path: JsonNode; query: JsonNode;
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
  var valid_594506 = path.getOrDefault("application-id")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = nil)
  if valid_594506 != nil:
    section.add "application-id", valid_594506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594507 = header.getOrDefault("X-Amz-Signature")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Signature", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Content-Sha256", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Date")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Date", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Credential")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Credential", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Security-Token")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Security-Token", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Algorithm")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Algorithm", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-SignedHeaders", valid_594513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594514: Call_DeleteApnsVoipChannel_594503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594514.validator(path, query, header, formData, body)
  let scheme = call_594514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594514.url(scheme.get, call_594514.host, call_594514.base,
                         call_594514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594514, url, valid)

proc call*(call_594515: Call_DeleteApnsVoipChannel_594503; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594516 = newJObject()
  add(path_594516, "application-id", newJString(applicationId))
  result = call_594515.call(path_594516, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_594503(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_594504, base: "/",
    url: url_DeleteApnsVoipChannel_594505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_594531 = ref object of OpenApiRestCall_593373
proc url_UpdateApnsVoipSandboxChannel_594533(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_594532(path: JsonNode; query: JsonNode;
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
  var valid_594534 = path.getOrDefault("application-id")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = nil)
  if valid_594534 != nil:
    section.add "application-id", valid_594534
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594535 = header.getOrDefault("X-Amz-Signature")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Signature", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Content-Sha256", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Date")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Date", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Credential")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Credential", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Security-Token")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Security-Token", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Algorithm")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Algorithm", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-SignedHeaders", valid_594541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594543: Call_UpdateApnsVoipSandboxChannel_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_594543.validator(path, query, header, formData, body)
  let scheme = call_594543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594543.url(scheme.get, call_594543.host, call_594543.base,
                         call_594543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594543, url, valid)

proc call*(call_594544: Call_UpdateApnsVoipSandboxChannel_594531;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594545 = newJObject()
  var body_594546 = newJObject()
  add(path_594545, "application-id", newJString(applicationId))
  if body != nil:
    body_594546 = body
  result = call_594544.call(path_594545, nil, nil, nil, body_594546)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_594531(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_594532, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_594533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_594517 = ref object of OpenApiRestCall_593373
proc url_GetApnsVoipSandboxChannel_594519(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_594518(path: JsonNode; query: JsonNode;
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
  var valid_594520 = path.getOrDefault("application-id")
  valid_594520 = validateParameter(valid_594520, JString, required = true,
                                 default = nil)
  if valid_594520 != nil:
    section.add "application-id", valid_594520
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594521 = header.getOrDefault("X-Amz-Signature")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Signature", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Content-Sha256", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Date")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Date", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Security-Token")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Security-Token", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Algorithm")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Algorithm", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-SignedHeaders", valid_594527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594528: Call_GetApnsVoipSandboxChannel_594517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_594528.validator(path, query, header, formData, body)
  let scheme = call_594528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594528.url(scheme.get, call_594528.host, call_594528.base,
                         call_594528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594528, url, valid)

proc call*(call_594529: Call_GetApnsVoipSandboxChannel_594517;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594530 = newJObject()
  add(path_594530, "application-id", newJString(applicationId))
  result = call_594529.call(path_594530, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_594517(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_594518, base: "/",
    url: url_GetApnsVoipSandboxChannel_594519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_594547 = ref object of OpenApiRestCall_593373
proc url_DeleteApnsVoipSandboxChannel_594549(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_594548(path: JsonNode; query: JsonNode;
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
  var valid_594550 = path.getOrDefault("application-id")
  valid_594550 = validateParameter(valid_594550, JString, required = true,
                                 default = nil)
  if valid_594550 != nil:
    section.add "application-id", valid_594550
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594551 = header.getOrDefault("X-Amz-Signature")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Signature", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Content-Sha256", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Date")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Date", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Credential")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Credential", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Security-Token")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Security-Token", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Algorithm")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Algorithm", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-SignedHeaders", valid_594557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594558: Call_DeleteApnsVoipSandboxChannel_594547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594558.validator(path, query, header, formData, body)
  let scheme = call_594558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594558.url(scheme.get, call_594558.host, call_594558.base,
                         call_594558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594558, url, valid)

proc call*(call_594559: Call_DeleteApnsVoipSandboxChannel_594547;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594560 = newJObject()
  add(path_594560, "application-id", newJString(applicationId))
  result = call_594559.call(path_594560, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_594547(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_594548, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_594549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_594561 = ref object of OpenApiRestCall_593373
proc url_GetApp_594563(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_594562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594564 = path.getOrDefault("application-id")
  valid_594564 = validateParameter(valid_594564, JString, required = true,
                                 default = nil)
  if valid_594564 != nil:
    section.add "application-id", valid_594564
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594565 = header.getOrDefault("X-Amz-Signature")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Signature", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Content-Sha256", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Credential")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Credential", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Security-Token")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Security-Token", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Algorithm")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Algorithm", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-SignedHeaders", valid_594571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594572: Call_GetApp_594561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_594572.validator(path, query, header, formData, body)
  let scheme = call_594572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594572.url(scheme.get, call_594572.host, call_594572.base,
                         call_594572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594572, url, valid)

proc call*(call_594573: Call_GetApp_594561; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594574 = newJObject()
  add(path_594574, "application-id", newJString(applicationId))
  result = call_594573.call(path_594574, nil, nil, nil, nil)

var getApp* = Call_GetApp_594561(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_594562, base: "/",
                              url: url_GetApp_594563,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_594575 = ref object of OpenApiRestCall_593373
proc url_DeleteApp_594577(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_594576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594578 = path.getOrDefault("application-id")
  valid_594578 = validateParameter(valid_594578, JString, required = true,
                                 default = nil)
  if valid_594578 != nil:
    section.add "application-id", valid_594578
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594579 = header.getOrDefault("X-Amz-Signature")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Signature", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Content-Sha256", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Date")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Date", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Credential")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Credential", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Security-Token")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Security-Token", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-Algorithm")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-Algorithm", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-SignedHeaders", valid_594585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594586: Call_DeleteApp_594575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_594586.validator(path, query, header, formData, body)
  let scheme = call_594586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594586.url(scheme.get, call_594586.host, call_594586.base,
                         call_594586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594586, url, valid)

proc call*(call_594587: Call_DeleteApp_594575; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594588 = newJObject()
  add(path_594588, "application-id", newJString(applicationId))
  result = call_594587.call(path_594588, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_594575(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_594576,
                                    base: "/", url: url_DeleteApp_594577,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_594603 = ref object of OpenApiRestCall_593373
proc url_UpdateBaiduChannel_594605(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_594604(path: JsonNode; query: JsonNode;
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
  var valid_594606 = path.getOrDefault("application-id")
  valid_594606 = validateParameter(valid_594606, JString, required = true,
                                 default = nil)
  if valid_594606 != nil:
    section.add "application-id", valid_594606
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594607 = header.getOrDefault("X-Amz-Signature")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Signature", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Content-Sha256", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Date")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Date", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Credential")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Credential", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Security-Token")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Security-Token", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Algorithm")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Algorithm", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-SignedHeaders", valid_594613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594615: Call_UpdateBaiduChannel_594603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_594615.validator(path, query, header, formData, body)
  let scheme = call_594615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594615.url(scheme.get, call_594615.host, call_594615.base,
                         call_594615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594615, url, valid)

proc call*(call_594616: Call_UpdateBaiduChannel_594603; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594617 = newJObject()
  var body_594618 = newJObject()
  add(path_594617, "application-id", newJString(applicationId))
  if body != nil:
    body_594618 = body
  result = call_594616.call(path_594617, nil, nil, nil, body_594618)

var updateBaiduChannel* = Call_UpdateBaiduChannel_594603(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_594604, base: "/",
    url: url_UpdateBaiduChannel_594605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_594589 = ref object of OpenApiRestCall_593373
proc url_GetBaiduChannel_594591(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_594590(path: JsonNode; query: JsonNode;
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
  var valid_594592 = path.getOrDefault("application-id")
  valid_594592 = validateParameter(valid_594592, JString, required = true,
                                 default = nil)
  if valid_594592 != nil:
    section.add "application-id", valid_594592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594593 = header.getOrDefault("X-Amz-Signature")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Signature", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Content-Sha256", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Date")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Date", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Credential")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Credential", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Security-Token")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Security-Token", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Algorithm")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Algorithm", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-SignedHeaders", valid_594599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594600: Call_GetBaiduChannel_594589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_594600.validator(path, query, header, formData, body)
  let scheme = call_594600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594600.url(scheme.get, call_594600.host, call_594600.base,
                         call_594600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594600, url, valid)

proc call*(call_594601: Call_GetBaiduChannel_594589; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594602 = newJObject()
  add(path_594602, "application-id", newJString(applicationId))
  result = call_594601.call(path_594602, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_594589(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_594590, base: "/", url: url_GetBaiduChannel_594591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_594619 = ref object of OpenApiRestCall_593373
proc url_DeleteBaiduChannel_594621(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_594620(path: JsonNode; query: JsonNode;
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
  var valid_594622 = path.getOrDefault("application-id")
  valid_594622 = validateParameter(valid_594622, JString, required = true,
                                 default = nil)
  if valid_594622 != nil:
    section.add "application-id", valid_594622
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594623 = header.getOrDefault("X-Amz-Signature")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Signature", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Content-Sha256", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Date")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Date", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Credential")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Credential", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Security-Token")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Security-Token", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Algorithm")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Algorithm", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-SignedHeaders", valid_594629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594630: Call_DeleteBaiduChannel_594619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594630.validator(path, query, header, formData, body)
  let scheme = call_594630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594630.url(scheme.get, call_594630.host, call_594630.base,
                         call_594630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594630, url, valid)

proc call*(call_594631: Call_DeleteBaiduChannel_594619; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594632 = newJObject()
  add(path_594632, "application-id", newJString(applicationId))
  result = call_594631.call(path_594632, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_594619(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_594620, base: "/",
    url: url_DeleteBaiduChannel_594621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_594648 = ref object of OpenApiRestCall_593373
proc url_UpdateCampaign_594650(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_594649(path: JsonNode; query: JsonNode;
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
  var valid_594651 = path.getOrDefault("application-id")
  valid_594651 = validateParameter(valid_594651, JString, required = true,
                                 default = nil)
  if valid_594651 != nil:
    section.add "application-id", valid_594651
  var valid_594652 = path.getOrDefault("campaign-id")
  valid_594652 = validateParameter(valid_594652, JString, required = true,
                                 default = nil)
  if valid_594652 != nil:
    section.add "campaign-id", valid_594652
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594653 = header.getOrDefault("X-Amz-Signature")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Signature", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Content-Sha256", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Date")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Date", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Credential")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Credential", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Security-Token")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Security-Token", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Algorithm")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Algorithm", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-SignedHeaders", valid_594659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594661: Call_UpdateCampaign_594648; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_594661.validator(path, query, header, formData, body)
  let scheme = call_594661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594661.url(scheme.get, call_594661.host, call_594661.base,
                         call_594661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594661, url, valid)

proc call*(call_594662: Call_UpdateCampaign_594648; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_594663 = newJObject()
  var body_594664 = newJObject()
  add(path_594663, "application-id", newJString(applicationId))
  if body != nil:
    body_594664 = body
  add(path_594663, "campaign-id", newJString(campaignId))
  result = call_594662.call(path_594663, nil, nil, nil, body_594664)

var updateCampaign* = Call_UpdateCampaign_594648(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_594649, base: "/", url: url_UpdateCampaign_594650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_594633 = ref object of OpenApiRestCall_593373
proc url_GetCampaign_594635(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_594634(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594636 = path.getOrDefault("application-id")
  valid_594636 = validateParameter(valid_594636, JString, required = true,
                                 default = nil)
  if valid_594636 != nil:
    section.add "application-id", valid_594636
  var valid_594637 = path.getOrDefault("campaign-id")
  valid_594637 = validateParameter(valid_594637, JString, required = true,
                                 default = nil)
  if valid_594637 != nil:
    section.add "campaign-id", valid_594637
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594638 = header.getOrDefault("X-Amz-Signature")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Signature", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Content-Sha256", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Date")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Date", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Credential")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Credential", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Security-Token")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Security-Token", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Algorithm")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Algorithm", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-SignedHeaders", valid_594644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594645: Call_GetCampaign_594633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_594645.validator(path, query, header, formData, body)
  let scheme = call_594645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594645.url(scheme.get, call_594645.host, call_594645.base,
                         call_594645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594645, url, valid)

proc call*(call_594646: Call_GetCampaign_594633; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_594647 = newJObject()
  add(path_594647, "application-id", newJString(applicationId))
  add(path_594647, "campaign-id", newJString(campaignId))
  result = call_594646.call(path_594647, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_594633(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_594634,
                                        base: "/", url: url_GetCampaign_594635,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_594665 = ref object of OpenApiRestCall_593373
proc url_DeleteCampaign_594667(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_594666(path: JsonNode; query: JsonNode;
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
  var valid_594668 = path.getOrDefault("application-id")
  valid_594668 = validateParameter(valid_594668, JString, required = true,
                                 default = nil)
  if valid_594668 != nil:
    section.add "application-id", valid_594668
  var valid_594669 = path.getOrDefault("campaign-id")
  valid_594669 = validateParameter(valid_594669, JString, required = true,
                                 default = nil)
  if valid_594669 != nil:
    section.add "campaign-id", valid_594669
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594670 = header.getOrDefault("X-Amz-Signature")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Signature", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Content-Sha256", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Date")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Date", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Credential")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Credential", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Security-Token")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Security-Token", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Algorithm")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Algorithm", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-SignedHeaders", valid_594676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594677: Call_DeleteCampaign_594665; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_594677.validator(path, query, header, formData, body)
  let scheme = call_594677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594677.url(scheme.get, call_594677.host, call_594677.base,
                         call_594677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594677, url, valid)

proc call*(call_594678: Call_DeleteCampaign_594665; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_594679 = newJObject()
  add(path_594679, "application-id", newJString(applicationId))
  add(path_594679, "campaign-id", newJString(campaignId))
  result = call_594678.call(path_594679, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_594665(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_594666, base: "/", url: url_DeleteCampaign_594667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_594694 = ref object of OpenApiRestCall_593373
proc url_UpdateEmailChannel_594696(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_594695(path: JsonNode; query: JsonNode;
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
  var valid_594697 = path.getOrDefault("application-id")
  valid_594697 = validateParameter(valid_594697, JString, required = true,
                                 default = nil)
  if valid_594697 != nil:
    section.add "application-id", valid_594697
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594698 = header.getOrDefault("X-Amz-Signature")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Signature", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Content-Sha256", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Date")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Date", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Credential")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Credential", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Security-Token")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Security-Token", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Algorithm")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Algorithm", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-SignedHeaders", valid_594704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594706: Call_UpdateEmailChannel_594694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_594706.validator(path, query, header, formData, body)
  let scheme = call_594706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594706.url(scheme.get, call_594706.host, call_594706.base,
                         call_594706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594706, url, valid)

proc call*(call_594707: Call_UpdateEmailChannel_594694; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594708 = newJObject()
  var body_594709 = newJObject()
  add(path_594708, "application-id", newJString(applicationId))
  if body != nil:
    body_594709 = body
  result = call_594707.call(path_594708, nil, nil, nil, body_594709)

var updateEmailChannel* = Call_UpdateEmailChannel_594694(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_594695, base: "/",
    url: url_UpdateEmailChannel_594696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_594680 = ref object of OpenApiRestCall_593373
proc url_GetEmailChannel_594682(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_594681(path: JsonNode; query: JsonNode;
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
  var valid_594683 = path.getOrDefault("application-id")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = nil)
  if valid_594683 != nil:
    section.add "application-id", valid_594683
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594684 = header.getOrDefault("X-Amz-Signature")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Signature", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Content-Sha256", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Date")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Date", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Credential")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Credential", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Security-Token")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Security-Token", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Algorithm")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Algorithm", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-SignedHeaders", valid_594690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594691: Call_GetEmailChannel_594680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_594691.validator(path, query, header, formData, body)
  let scheme = call_594691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594691.url(scheme.get, call_594691.host, call_594691.base,
                         call_594691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594691, url, valid)

proc call*(call_594692: Call_GetEmailChannel_594680; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594693 = newJObject()
  add(path_594693, "application-id", newJString(applicationId))
  result = call_594692.call(path_594693, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_594680(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_594681, base: "/", url: url_GetEmailChannel_594682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_594710 = ref object of OpenApiRestCall_593373
proc url_DeleteEmailChannel_594712(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_594711(path: JsonNode; query: JsonNode;
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
  var valid_594713 = path.getOrDefault("application-id")
  valid_594713 = validateParameter(valid_594713, JString, required = true,
                                 default = nil)
  if valid_594713 != nil:
    section.add "application-id", valid_594713
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594714 = header.getOrDefault("X-Amz-Signature")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Signature", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Content-Sha256", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Date")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Date", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Credential")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Credential", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-Security-Token")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-Security-Token", valid_594718
  var valid_594719 = header.getOrDefault("X-Amz-Algorithm")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Algorithm", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-SignedHeaders", valid_594720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594721: Call_DeleteEmailChannel_594710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594721.validator(path, query, header, formData, body)
  let scheme = call_594721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594721.url(scheme.get, call_594721.host, call_594721.base,
                         call_594721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594721, url, valid)

proc call*(call_594722: Call_DeleteEmailChannel_594710; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594723 = newJObject()
  add(path_594723, "application-id", newJString(applicationId))
  result = call_594722.call(path_594723, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_594710(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_594711, base: "/",
    url: url_DeleteEmailChannel_594712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_594739 = ref object of OpenApiRestCall_593373
proc url_UpdateEndpoint_594741(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_594740(path: JsonNode; query: JsonNode;
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
  var valid_594742 = path.getOrDefault("application-id")
  valid_594742 = validateParameter(valid_594742, JString, required = true,
                                 default = nil)
  if valid_594742 != nil:
    section.add "application-id", valid_594742
  var valid_594743 = path.getOrDefault("endpoint-id")
  valid_594743 = validateParameter(valid_594743, JString, required = true,
                                 default = nil)
  if valid_594743 != nil:
    section.add "endpoint-id", valid_594743
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594744 = header.getOrDefault("X-Amz-Signature")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Signature", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Content-Sha256", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Date")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Date", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Credential")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Credential", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Security-Token")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Security-Token", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Algorithm")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Algorithm", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-SignedHeaders", valid_594750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_UpdateEndpoint_594739; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_UpdateEndpoint_594739; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_594754 = newJObject()
  var body_594755 = newJObject()
  add(path_594754, "application-id", newJString(applicationId))
  if body != nil:
    body_594755 = body
  add(path_594754, "endpoint-id", newJString(endpointId))
  result = call_594753.call(path_594754, nil, nil, nil, body_594755)

var updateEndpoint* = Call_UpdateEndpoint_594739(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_594740, base: "/", url: url_UpdateEndpoint_594741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_594724 = ref object of OpenApiRestCall_593373
proc url_GetEndpoint_594726(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_594725(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594727 = path.getOrDefault("application-id")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = nil)
  if valid_594727 != nil:
    section.add "application-id", valid_594727
  var valid_594728 = path.getOrDefault("endpoint-id")
  valid_594728 = validateParameter(valid_594728, JString, required = true,
                                 default = nil)
  if valid_594728 != nil:
    section.add "endpoint-id", valid_594728
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594729 = header.getOrDefault("X-Amz-Signature")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Signature", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Content-Sha256", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Date")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Date", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Credential")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Credential", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-Security-Token")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-Security-Token", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Algorithm")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Algorithm", valid_594734
  var valid_594735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-SignedHeaders", valid_594735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594736: Call_GetEndpoint_594724; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_594736.validator(path, query, header, formData, body)
  let scheme = call_594736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594736.url(scheme.get, call_594736.host, call_594736.base,
                         call_594736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594736, url, valid)

proc call*(call_594737: Call_GetEndpoint_594724; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_594738 = newJObject()
  add(path_594738, "application-id", newJString(applicationId))
  add(path_594738, "endpoint-id", newJString(endpointId))
  result = call_594737.call(path_594738, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_594724(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_594725,
                                        base: "/", url: url_GetEndpoint_594726,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_594756 = ref object of OpenApiRestCall_593373
proc url_DeleteEndpoint_594758(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_594757(path: JsonNode; query: JsonNode;
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
  var valid_594759 = path.getOrDefault("application-id")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = nil)
  if valid_594759 != nil:
    section.add "application-id", valid_594759
  var valid_594760 = path.getOrDefault("endpoint-id")
  valid_594760 = validateParameter(valid_594760, JString, required = true,
                                 default = nil)
  if valid_594760 != nil:
    section.add "endpoint-id", valid_594760
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594761 = header.getOrDefault("X-Amz-Signature")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Signature", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Content-Sha256", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Date")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Date", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Credential")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Credential", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Security-Token")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Security-Token", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Algorithm")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Algorithm", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-SignedHeaders", valid_594767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594768: Call_DeleteEndpoint_594756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_594768.validator(path, query, header, formData, body)
  let scheme = call_594768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594768.url(scheme.get, call_594768.host, call_594768.base,
                         call_594768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594768, url, valid)

proc call*(call_594769: Call_DeleteEndpoint_594756; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_594770 = newJObject()
  add(path_594770, "application-id", newJString(applicationId))
  add(path_594770, "endpoint-id", newJString(endpointId))
  result = call_594769.call(path_594770, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_594756(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_594757, base: "/", url: url_DeleteEndpoint_594758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_594785 = ref object of OpenApiRestCall_593373
proc url_PutEventStream_594787(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_594786(path: JsonNode; query: JsonNode;
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
  var valid_594788 = path.getOrDefault("application-id")
  valid_594788 = validateParameter(valid_594788, JString, required = true,
                                 default = nil)
  if valid_594788 != nil:
    section.add "application-id", valid_594788
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594789 = header.getOrDefault("X-Amz-Signature")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Signature", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Content-Sha256", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Date")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Date", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Credential")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Credential", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Security-Token")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Security-Token", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Algorithm")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Algorithm", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-SignedHeaders", valid_594795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594797: Call_PutEventStream_594785; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_594797.validator(path, query, header, formData, body)
  let scheme = call_594797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594797.url(scheme.get, call_594797.host, call_594797.base,
                         call_594797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594797, url, valid)

proc call*(call_594798: Call_PutEventStream_594785; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594799 = newJObject()
  var body_594800 = newJObject()
  add(path_594799, "application-id", newJString(applicationId))
  if body != nil:
    body_594800 = body
  result = call_594798.call(path_594799, nil, nil, nil, body_594800)

var putEventStream* = Call_PutEventStream_594785(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_594786, base: "/", url: url_PutEventStream_594787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_594771 = ref object of OpenApiRestCall_593373
proc url_GetEventStream_594773(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_594772(path: JsonNode; query: JsonNode;
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
  var valid_594774 = path.getOrDefault("application-id")
  valid_594774 = validateParameter(valid_594774, JString, required = true,
                                 default = nil)
  if valid_594774 != nil:
    section.add "application-id", valid_594774
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594775 = header.getOrDefault("X-Amz-Signature")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Signature", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Content-Sha256", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Date")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Date", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Credential")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Credential", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Security-Token")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Security-Token", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Algorithm")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Algorithm", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-SignedHeaders", valid_594781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594782: Call_GetEventStream_594771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_594782.validator(path, query, header, formData, body)
  let scheme = call_594782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594782.url(scheme.get, call_594782.host, call_594782.base,
                         call_594782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594782, url, valid)

proc call*(call_594783: Call_GetEventStream_594771; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594784 = newJObject()
  add(path_594784, "application-id", newJString(applicationId))
  result = call_594783.call(path_594784, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_594771(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_594772, base: "/", url: url_GetEventStream_594773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_594801 = ref object of OpenApiRestCall_593373
proc url_DeleteEventStream_594803(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_594802(path: JsonNode; query: JsonNode;
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
  var valid_594804 = path.getOrDefault("application-id")
  valid_594804 = validateParameter(valid_594804, JString, required = true,
                                 default = nil)
  if valid_594804 != nil:
    section.add "application-id", valid_594804
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594805 = header.getOrDefault("X-Amz-Signature")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Signature", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Content-Sha256", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Date")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Date", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Credential")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Credential", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Security-Token")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Security-Token", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Algorithm")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Algorithm", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-SignedHeaders", valid_594811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594812: Call_DeleteEventStream_594801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_594812.validator(path, query, header, formData, body)
  let scheme = call_594812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594812.url(scheme.get, call_594812.host, call_594812.base,
                         call_594812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594812, url, valid)

proc call*(call_594813: Call_DeleteEventStream_594801; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594814 = newJObject()
  add(path_594814, "application-id", newJString(applicationId))
  result = call_594813.call(path_594814, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_594801(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_594802, base: "/",
    url: url_DeleteEventStream_594803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_594829 = ref object of OpenApiRestCall_593373
proc url_UpdateGcmChannel_594831(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_594830(path: JsonNode; query: JsonNode;
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
  var valid_594832 = path.getOrDefault("application-id")
  valid_594832 = validateParameter(valid_594832, JString, required = true,
                                 default = nil)
  if valid_594832 != nil:
    section.add "application-id", valid_594832
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594833 = header.getOrDefault("X-Amz-Signature")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Signature", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Content-Sha256", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Date")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Date", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Credential")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Credential", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Security-Token")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Security-Token", valid_594837
  var valid_594838 = header.getOrDefault("X-Amz-Algorithm")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Algorithm", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-SignedHeaders", valid_594839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594841: Call_UpdateGcmChannel_594829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_594841.validator(path, query, header, formData, body)
  let scheme = call_594841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594841.url(scheme.get, call_594841.host, call_594841.base,
                         call_594841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594841, url, valid)

proc call*(call_594842: Call_UpdateGcmChannel_594829; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594843 = newJObject()
  var body_594844 = newJObject()
  add(path_594843, "application-id", newJString(applicationId))
  if body != nil:
    body_594844 = body
  result = call_594842.call(path_594843, nil, nil, nil, body_594844)

var updateGcmChannel* = Call_UpdateGcmChannel_594829(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_594830, base: "/",
    url: url_UpdateGcmChannel_594831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_594815 = ref object of OpenApiRestCall_593373
proc url_GetGcmChannel_594817(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_594816(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594818 = path.getOrDefault("application-id")
  valid_594818 = validateParameter(valid_594818, JString, required = true,
                                 default = nil)
  if valid_594818 != nil:
    section.add "application-id", valid_594818
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594819 = header.getOrDefault("X-Amz-Signature")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Signature", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Content-Sha256", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Date")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Date", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-Credential")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Credential", valid_594822
  var valid_594823 = header.getOrDefault("X-Amz-Security-Token")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "X-Amz-Security-Token", valid_594823
  var valid_594824 = header.getOrDefault("X-Amz-Algorithm")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Algorithm", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-SignedHeaders", valid_594825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594826: Call_GetGcmChannel_594815; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_594826.validator(path, query, header, formData, body)
  let scheme = call_594826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594826.url(scheme.get, call_594826.host, call_594826.base,
                         call_594826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594826, url, valid)

proc call*(call_594827: Call_GetGcmChannel_594815; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594828 = newJObject()
  add(path_594828, "application-id", newJString(applicationId))
  result = call_594827.call(path_594828, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_594815(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_594816, base: "/", url: url_GetGcmChannel_594817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_594845 = ref object of OpenApiRestCall_593373
proc url_DeleteGcmChannel_594847(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_594846(path: JsonNode; query: JsonNode;
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
  var valid_594848 = path.getOrDefault("application-id")
  valid_594848 = validateParameter(valid_594848, JString, required = true,
                                 default = nil)
  if valid_594848 != nil:
    section.add "application-id", valid_594848
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594849 = header.getOrDefault("X-Amz-Signature")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Signature", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Content-Sha256", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Date")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Date", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-Credential")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Credential", valid_594852
  var valid_594853 = header.getOrDefault("X-Amz-Security-Token")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Security-Token", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-Algorithm")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-Algorithm", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-SignedHeaders", valid_594855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594856: Call_DeleteGcmChannel_594845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594856.validator(path, query, header, formData, body)
  let scheme = call_594856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594856.url(scheme.get, call_594856.host, call_594856.base,
                         call_594856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594856, url, valid)

proc call*(call_594857: Call_DeleteGcmChannel_594845; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594858 = newJObject()
  add(path_594858, "application-id", newJString(applicationId))
  result = call_594857.call(path_594858, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_594845(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_594846, base: "/",
    url: url_DeleteGcmChannel_594847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_594874 = ref object of OpenApiRestCall_593373
proc url_UpdateJourney_594876(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_594875(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594877 = path.getOrDefault("application-id")
  valid_594877 = validateParameter(valid_594877, JString, required = true,
                                 default = nil)
  if valid_594877 != nil:
    section.add "application-id", valid_594877
  var valid_594878 = path.getOrDefault("journey-id")
  valid_594878 = validateParameter(valid_594878, JString, required = true,
                                 default = nil)
  if valid_594878 != nil:
    section.add "journey-id", valid_594878
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594879 = header.getOrDefault("X-Amz-Signature")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Signature", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-Content-Sha256", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Credential")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Credential", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Security-Token")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Security-Token", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Algorithm")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Algorithm", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-SignedHeaders", valid_594885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594887: Call_UpdateJourney_594874; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_594887.validator(path, query, header, formData, body)
  let scheme = call_594887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594887.url(scheme.get, call_594887.host, call_594887.base,
                         call_594887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594887, url, valid)

proc call*(call_594888: Call_UpdateJourney_594874; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_594889 = newJObject()
  var body_594890 = newJObject()
  add(path_594889, "application-id", newJString(applicationId))
  if body != nil:
    body_594890 = body
  add(path_594889, "journey-id", newJString(journeyId))
  result = call_594888.call(path_594889, nil, nil, nil, body_594890)

var updateJourney* = Call_UpdateJourney_594874(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_594875, base: "/", url: url_UpdateJourney_594876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_594859 = ref object of OpenApiRestCall_593373
proc url_GetJourney_594861(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJourney_594860(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594862 = path.getOrDefault("application-id")
  valid_594862 = validateParameter(valid_594862, JString, required = true,
                                 default = nil)
  if valid_594862 != nil:
    section.add "application-id", valid_594862
  var valid_594863 = path.getOrDefault("journey-id")
  valid_594863 = validateParameter(valid_594863, JString, required = true,
                                 default = nil)
  if valid_594863 != nil:
    section.add "journey-id", valid_594863
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594864 = header.getOrDefault("X-Amz-Signature")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Signature", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Content-Sha256", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Credential")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Credential", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Security-Token")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Security-Token", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Algorithm")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Algorithm", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-SignedHeaders", valid_594870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594871: Call_GetJourney_594859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_594871.validator(path, query, header, formData, body)
  let scheme = call_594871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594871.url(scheme.get, call_594871.host, call_594871.base,
                         call_594871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594871, url, valid)

proc call*(call_594872: Call_GetJourney_594859; applicationId: string;
          journeyId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_594873 = newJObject()
  add(path_594873, "application-id", newJString(applicationId))
  add(path_594873, "journey-id", newJString(journeyId))
  result = call_594872.call(path_594873, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_594859(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_594860,
                                      base: "/", url: url_GetJourney_594861,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_594891 = ref object of OpenApiRestCall_593373
proc url_DeleteJourney_594893(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_594892(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594894 = path.getOrDefault("application-id")
  valid_594894 = validateParameter(valid_594894, JString, required = true,
                                 default = nil)
  if valid_594894 != nil:
    section.add "application-id", valid_594894
  var valid_594895 = path.getOrDefault("journey-id")
  valid_594895 = validateParameter(valid_594895, JString, required = true,
                                 default = nil)
  if valid_594895 != nil:
    section.add "journey-id", valid_594895
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594896 = header.getOrDefault("X-Amz-Signature")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Signature", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Content-Sha256", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Date")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Date", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Credential")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Credential", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-Security-Token")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-Security-Token", valid_594900
  var valid_594901 = header.getOrDefault("X-Amz-Algorithm")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-Algorithm", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-SignedHeaders", valid_594902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594903: Call_DeleteJourney_594891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_594903.validator(path, query, header, formData, body)
  let scheme = call_594903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594903.url(scheme.get, call_594903.host, call_594903.base,
                         call_594903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594903, url, valid)

proc call*(call_594904: Call_DeleteJourney_594891; applicationId: string;
          journeyId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_594905 = newJObject()
  add(path_594905, "application-id", newJString(applicationId))
  add(path_594905, "journey-id", newJString(journeyId))
  result = call_594904.call(path_594905, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_594891(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_594892, base: "/", url: url_DeleteJourney_594893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_594921 = ref object of OpenApiRestCall_593373
proc url_UpdateSegment_594923(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_594922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594924 = path.getOrDefault("application-id")
  valid_594924 = validateParameter(valid_594924, JString, required = true,
                                 default = nil)
  if valid_594924 != nil:
    section.add "application-id", valid_594924
  var valid_594925 = path.getOrDefault("segment-id")
  valid_594925 = validateParameter(valid_594925, JString, required = true,
                                 default = nil)
  if valid_594925 != nil:
    section.add "segment-id", valid_594925
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594926 = header.getOrDefault("X-Amz-Signature")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Signature", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Content-Sha256", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-Date")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-Date", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Credential")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Credential", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Security-Token")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Security-Token", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-Algorithm")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Algorithm", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-SignedHeaders", valid_594932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594934: Call_UpdateSegment_594921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_594934.validator(path, query, header, formData, body)
  let scheme = call_594934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594934.url(scheme.get, call_594934.host, call_594934.base,
                         call_594934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594934, url, valid)

proc call*(call_594935: Call_UpdateSegment_594921; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_594936 = newJObject()
  var body_594937 = newJObject()
  add(path_594936, "application-id", newJString(applicationId))
  add(path_594936, "segment-id", newJString(segmentId))
  if body != nil:
    body_594937 = body
  result = call_594935.call(path_594936, nil, nil, nil, body_594937)

var updateSegment* = Call_UpdateSegment_594921(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_594922, base: "/", url: url_UpdateSegment_594923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_594906 = ref object of OpenApiRestCall_593373
proc url_GetSegment_594908(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_594907(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594909 = path.getOrDefault("application-id")
  valid_594909 = validateParameter(valid_594909, JString, required = true,
                                 default = nil)
  if valid_594909 != nil:
    section.add "application-id", valid_594909
  var valid_594910 = path.getOrDefault("segment-id")
  valid_594910 = validateParameter(valid_594910, JString, required = true,
                                 default = nil)
  if valid_594910 != nil:
    section.add "segment-id", valid_594910
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594911 = header.getOrDefault("X-Amz-Signature")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Signature", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Content-Sha256", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-Date")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-Date", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Credential")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Credential", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-Security-Token")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-Security-Token", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-Algorithm")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Algorithm", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-SignedHeaders", valid_594917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594918: Call_GetSegment_594906; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_594918.validator(path, query, header, formData, body)
  let scheme = call_594918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594918.url(scheme.get, call_594918.host, call_594918.base,
                         call_594918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594918, url, valid)

proc call*(call_594919: Call_GetSegment_594906; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_594920 = newJObject()
  add(path_594920, "application-id", newJString(applicationId))
  add(path_594920, "segment-id", newJString(segmentId))
  result = call_594919.call(path_594920, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_594906(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_594907,
                                      base: "/", url: url_GetSegment_594908,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_594938 = ref object of OpenApiRestCall_593373
proc url_DeleteSegment_594940(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_594939(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594941 = path.getOrDefault("application-id")
  valid_594941 = validateParameter(valid_594941, JString, required = true,
                                 default = nil)
  if valid_594941 != nil:
    section.add "application-id", valid_594941
  var valid_594942 = path.getOrDefault("segment-id")
  valid_594942 = validateParameter(valid_594942, JString, required = true,
                                 default = nil)
  if valid_594942 != nil:
    section.add "segment-id", valid_594942
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594943 = header.getOrDefault("X-Amz-Signature")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Signature", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Content-Sha256", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Date")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Date", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-Credential")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Credential", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-Security-Token")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-Security-Token", valid_594947
  var valid_594948 = header.getOrDefault("X-Amz-Algorithm")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "X-Amz-Algorithm", valid_594948
  var valid_594949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "X-Amz-SignedHeaders", valid_594949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594950: Call_DeleteSegment_594938; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_594950.validator(path, query, header, formData, body)
  let scheme = call_594950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594950.url(scheme.get, call_594950.host, call_594950.base,
                         call_594950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594950, url, valid)

proc call*(call_594951: Call_DeleteSegment_594938; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_594952 = newJObject()
  add(path_594952, "application-id", newJString(applicationId))
  add(path_594952, "segment-id", newJString(segmentId))
  result = call_594951.call(path_594952, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_594938(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_594939, base: "/", url: url_DeleteSegment_594940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_594967 = ref object of OpenApiRestCall_593373
proc url_UpdateSmsChannel_594969(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_594968(path: JsonNode; query: JsonNode;
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
  var valid_594970 = path.getOrDefault("application-id")
  valid_594970 = validateParameter(valid_594970, JString, required = true,
                                 default = nil)
  if valid_594970 != nil:
    section.add "application-id", valid_594970
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594971 = header.getOrDefault("X-Amz-Signature")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Signature", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Content-Sha256", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Date")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Date", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Credential")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Credential", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Security-Token")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Security-Token", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Algorithm")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Algorithm", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-SignedHeaders", valid_594977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594979: Call_UpdateSmsChannel_594967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_594979.validator(path, query, header, formData, body)
  let scheme = call_594979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594979.url(scheme.get, call_594979.host, call_594979.base,
                         call_594979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594979, url, valid)

proc call*(call_594980: Call_UpdateSmsChannel_594967; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_594981 = newJObject()
  var body_594982 = newJObject()
  add(path_594981, "application-id", newJString(applicationId))
  if body != nil:
    body_594982 = body
  result = call_594980.call(path_594981, nil, nil, nil, body_594982)

var updateSmsChannel* = Call_UpdateSmsChannel_594967(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_594968, base: "/",
    url: url_UpdateSmsChannel_594969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_594953 = ref object of OpenApiRestCall_593373
proc url_GetSmsChannel_594955(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_594954(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594956 = path.getOrDefault("application-id")
  valid_594956 = validateParameter(valid_594956, JString, required = true,
                                 default = nil)
  if valid_594956 != nil:
    section.add "application-id", valid_594956
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594957 = header.getOrDefault("X-Amz-Signature")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Signature", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Content-Sha256", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Date")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Date", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Credential")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Credential", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Security-Token")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Security-Token", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Algorithm")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Algorithm", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-SignedHeaders", valid_594963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594964: Call_GetSmsChannel_594953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_594964.validator(path, query, header, formData, body)
  let scheme = call_594964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594964.url(scheme.get, call_594964.host, call_594964.base,
                         call_594964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594964, url, valid)

proc call*(call_594965: Call_GetSmsChannel_594953; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594966 = newJObject()
  add(path_594966, "application-id", newJString(applicationId))
  result = call_594965.call(path_594966, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_594953(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_594954, base: "/", url: url_GetSmsChannel_594955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_594983 = ref object of OpenApiRestCall_593373
proc url_DeleteSmsChannel_594985(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_594984(path: JsonNode; query: JsonNode;
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
  var valid_594986 = path.getOrDefault("application-id")
  valid_594986 = validateParameter(valid_594986, JString, required = true,
                                 default = nil)
  if valid_594986 != nil:
    section.add "application-id", valid_594986
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594987 = header.getOrDefault("X-Amz-Signature")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Signature", valid_594987
  var valid_594988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Content-Sha256", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Date")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Date", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Credential")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Credential", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Security-Token")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Security-Token", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Algorithm")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Algorithm", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-SignedHeaders", valid_594993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594994: Call_DeleteSmsChannel_594983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_594994.validator(path, query, header, formData, body)
  let scheme = call_594994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594994.url(scheme.get, call_594994.host, call_594994.base,
                         call_594994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594994, url, valid)

proc call*(call_594995: Call_DeleteSmsChannel_594983; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_594996 = newJObject()
  add(path_594996, "application-id", newJString(applicationId))
  result = call_594995.call(path_594996, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_594983(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_594984, base: "/",
    url: url_DeleteSmsChannel_594985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_594997 = ref object of OpenApiRestCall_593373
proc url_GetUserEndpoints_594999(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_594998(path: JsonNode; query: JsonNode;
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
  var valid_595000 = path.getOrDefault("application-id")
  valid_595000 = validateParameter(valid_595000, JString, required = true,
                                 default = nil)
  if valid_595000 != nil:
    section.add "application-id", valid_595000
  var valid_595001 = path.getOrDefault("user-id")
  valid_595001 = validateParameter(valid_595001, JString, required = true,
                                 default = nil)
  if valid_595001 != nil:
    section.add "user-id", valid_595001
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595002 = header.getOrDefault("X-Amz-Signature")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Signature", valid_595002
  var valid_595003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "X-Amz-Content-Sha256", valid_595003
  var valid_595004 = header.getOrDefault("X-Amz-Date")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Date", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Credential")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Credential", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Security-Token")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Security-Token", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Algorithm")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Algorithm", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-SignedHeaders", valid_595008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595009: Call_GetUserEndpoints_594997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_595009.validator(path, query, header, formData, body)
  let scheme = call_595009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595009.url(scheme.get, call_595009.host, call_595009.base,
                         call_595009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595009, url, valid)

proc call*(call_595010: Call_GetUserEndpoints_594997; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_595011 = newJObject()
  add(path_595011, "application-id", newJString(applicationId))
  add(path_595011, "user-id", newJString(userId))
  result = call_595010.call(path_595011, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_594997(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_594998, base: "/",
    url: url_GetUserEndpoints_594999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_595012 = ref object of OpenApiRestCall_593373
proc url_DeleteUserEndpoints_595014(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_595013(path: JsonNode; query: JsonNode;
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
  var valid_595015 = path.getOrDefault("application-id")
  valid_595015 = validateParameter(valid_595015, JString, required = true,
                                 default = nil)
  if valid_595015 != nil:
    section.add "application-id", valid_595015
  var valid_595016 = path.getOrDefault("user-id")
  valid_595016 = validateParameter(valid_595016, JString, required = true,
                                 default = nil)
  if valid_595016 != nil:
    section.add "user-id", valid_595016
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595017 = header.getOrDefault("X-Amz-Signature")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Signature", valid_595017
  var valid_595018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "X-Amz-Content-Sha256", valid_595018
  var valid_595019 = header.getOrDefault("X-Amz-Date")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Date", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Credential")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Credential", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-Security-Token")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Security-Token", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Algorithm")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Algorithm", valid_595022
  var valid_595023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "X-Amz-SignedHeaders", valid_595023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595024: Call_DeleteUserEndpoints_595012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_595024.validator(path, query, header, formData, body)
  let scheme = call_595024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595024.url(scheme.get, call_595024.host, call_595024.base,
                         call_595024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595024, url, valid)

proc call*(call_595025: Call_DeleteUserEndpoints_595012; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_595026 = newJObject()
  add(path_595026, "application-id", newJString(applicationId))
  add(path_595026, "user-id", newJString(userId))
  result = call_595025.call(path_595026, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_595012(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_595013, base: "/",
    url: url_DeleteUserEndpoints_595014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_595041 = ref object of OpenApiRestCall_593373
proc url_UpdateVoiceChannel_595043(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_595042(path: JsonNode; query: JsonNode;
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
  var valid_595044 = path.getOrDefault("application-id")
  valid_595044 = validateParameter(valid_595044, JString, required = true,
                                 default = nil)
  if valid_595044 != nil:
    section.add "application-id", valid_595044
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595045 = header.getOrDefault("X-Amz-Signature")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Signature", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Date")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Date", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Credential")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Credential", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Security-Token")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Security-Token", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Algorithm")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Algorithm", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-SignedHeaders", valid_595051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595053: Call_UpdateVoiceChannel_595041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_595053.validator(path, query, header, formData, body)
  let scheme = call_595053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595053.url(scheme.get, call_595053.host, call_595053.base,
                         call_595053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595053, url, valid)

proc call*(call_595054: Call_UpdateVoiceChannel_595041; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595055 = newJObject()
  var body_595056 = newJObject()
  add(path_595055, "application-id", newJString(applicationId))
  if body != nil:
    body_595056 = body
  result = call_595054.call(path_595055, nil, nil, nil, body_595056)

var updateVoiceChannel* = Call_UpdateVoiceChannel_595041(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_595042, base: "/",
    url: url_UpdateVoiceChannel_595043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_595027 = ref object of OpenApiRestCall_593373
proc url_GetVoiceChannel_595029(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_595028(path: JsonNode; query: JsonNode;
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
  var valid_595030 = path.getOrDefault("application-id")
  valid_595030 = validateParameter(valid_595030, JString, required = true,
                                 default = nil)
  if valid_595030 != nil:
    section.add "application-id", valid_595030
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595031 = header.getOrDefault("X-Amz-Signature")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Signature", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Content-Sha256", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Date")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Date", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Credential")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Credential", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Security-Token")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Security-Token", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Algorithm")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Algorithm", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-SignedHeaders", valid_595037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595038: Call_GetVoiceChannel_595027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_595038.validator(path, query, header, formData, body)
  let scheme = call_595038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595038.url(scheme.get, call_595038.host, call_595038.base,
                         call_595038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595038, url, valid)

proc call*(call_595039: Call_GetVoiceChannel_595027; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595040 = newJObject()
  add(path_595040, "application-id", newJString(applicationId))
  result = call_595039.call(path_595040, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_595027(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_595028, base: "/", url: url_GetVoiceChannel_595029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_595057 = ref object of OpenApiRestCall_593373
proc url_DeleteVoiceChannel_595059(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_595058(path: JsonNode; query: JsonNode;
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
  var valid_595060 = path.getOrDefault("application-id")
  valid_595060 = validateParameter(valid_595060, JString, required = true,
                                 default = nil)
  if valid_595060 != nil:
    section.add "application-id", valid_595060
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595061 = header.getOrDefault("X-Amz-Signature")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Signature", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-Content-Sha256", valid_595062
  var valid_595063 = header.getOrDefault("X-Amz-Date")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Date", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-Credential")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Credential", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Security-Token")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Security-Token", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Algorithm")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Algorithm", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-SignedHeaders", valid_595067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595068: Call_DeleteVoiceChannel_595057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_595068.validator(path, query, header, formData, body)
  let scheme = call_595068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595068.url(scheme.get, call_595068.host, call_595068.base,
                         call_595068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595068, url, valid)

proc call*(call_595069: Call_DeleteVoiceChannel_595057; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595070 = newJObject()
  add(path_595070, "application-id", newJString(applicationId))
  result = call_595069.call(path_595070, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_595057(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_595058, base: "/",
    url: url_DeleteVoiceChannel_595059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_595071 = ref object of OpenApiRestCall_593373
proc url_GetApplicationDateRangeKpi_595073(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_595072(path: JsonNode; query: JsonNode;
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
  var valid_595074 = path.getOrDefault("kpi-name")
  valid_595074 = validateParameter(valid_595074, JString, required = true,
                                 default = nil)
  if valid_595074 != nil:
    section.add "kpi-name", valid_595074
  var valid_595075 = path.getOrDefault("application-id")
  valid_595075 = validateParameter(valid_595075, JString, required = true,
                                 default = nil)
  if valid_595075 != nil:
    section.add "application-id", valid_595075
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
  var valid_595076 = query.getOrDefault("end-time")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "end-time", valid_595076
  var valid_595077 = query.getOrDefault("page-size")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "page-size", valid_595077
  var valid_595078 = query.getOrDefault("start-time")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "start-time", valid_595078
  var valid_595079 = query.getOrDefault("next-token")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "next-token", valid_595079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595080 = header.getOrDefault("X-Amz-Signature")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Signature", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Content-Sha256", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Date")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Date", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-Credential")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-Credential", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-Security-Token")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Security-Token", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Algorithm")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Algorithm", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-SignedHeaders", valid_595086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595087: Call_GetApplicationDateRangeKpi_595071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_595087.validator(path, query, header, formData, body)
  let scheme = call_595087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595087.url(scheme.get, call_595087.host, call_595087.base,
                         call_595087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595087, url, valid)

proc call*(call_595088: Call_GetApplicationDateRangeKpi_595071; kpiName: string;
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
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_595089 = newJObject()
  var query_595090 = newJObject()
  add(path_595089, "kpi-name", newJString(kpiName))
  add(path_595089, "application-id", newJString(applicationId))
  add(query_595090, "end-time", newJString(endTime))
  add(query_595090, "page-size", newJString(pageSize))
  add(query_595090, "start-time", newJString(startTime))
  add(query_595090, "next-token", newJString(nextToken))
  result = call_595088.call(path_595089, query_595090, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_595071(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_595072, base: "/",
    url: url_GetApplicationDateRangeKpi_595073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_595105 = ref object of OpenApiRestCall_593373
proc url_UpdateApplicationSettings_595107(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_595106(path: JsonNode; query: JsonNode;
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
  var valid_595108 = path.getOrDefault("application-id")
  valid_595108 = validateParameter(valid_595108, JString, required = true,
                                 default = nil)
  if valid_595108 != nil:
    section.add "application-id", valid_595108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595109 = header.getOrDefault("X-Amz-Signature")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Signature", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Content-Sha256", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Date")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Date", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Credential")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Credential", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Security-Token")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Security-Token", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Algorithm")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Algorithm", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-SignedHeaders", valid_595115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595117: Call_UpdateApplicationSettings_595105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_595117.validator(path, query, header, formData, body)
  let scheme = call_595117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595117.url(scheme.get, call_595117.host, call_595117.base,
                         call_595117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595117, url, valid)

proc call*(call_595118: Call_UpdateApplicationSettings_595105;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595119 = newJObject()
  var body_595120 = newJObject()
  add(path_595119, "application-id", newJString(applicationId))
  if body != nil:
    body_595120 = body
  result = call_595118.call(path_595119, nil, nil, nil, body_595120)

var updateApplicationSettings* = Call_UpdateApplicationSettings_595105(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_595106, base: "/",
    url: url_UpdateApplicationSettings_595107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_595091 = ref object of OpenApiRestCall_593373
proc url_GetApplicationSettings_595093(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_595092(path: JsonNode; query: JsonNode;
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
  var valid_595094 = path.getOrDefault("application-id")
  valid_595094 = validateParameter(valid_595094, JString, required = true,
                                 default = nil)
  if valid_595094 != nil:
    section.add "application-id", valid_595094
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595095 = header.getOrDefault("X-Amz-Signature")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Signature", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Content-Sha256", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Date")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Date", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Credential")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Credential", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Security-Token")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Security-Token", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Algorithm")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Algorithm", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-SignedHeaders", valid_595101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595102: Call_GetApplicationSettings_595091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_595102.validator(path, query, header, formData, body)
  let scheme = call_595102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595102.url(scheme.get, call_595102.host, call_595102.base,
                         call_595102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595102, url, valid)

proc call*(call_595103: Call_GetApplicationSettings_595091; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595104 = newJObject()
  add(path_595104, "application-id", newJString(applicationId))
  result = call_595103.call(path_595104, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_595091(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_595092, base: "/",
    url: url_GetApplicationSettings_595093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_595121 = ref object of OpenApiRestCall_593373
proc url_GetCampaignActivities_595123(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_595122(path: JsonNode; query: JsonNode;
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
  var valid_595124 = path.getOrDefault("application-id")
  valid_595124 = validateParameter(valid_595124, JString, required = true,
                                 default = nil)
  if valid_595124 != nil:
    section.add "application-id", valid_595124
  var valid_595125 = path.getOrDefault("campaign-id")
  valid_595125 = validateParameter(valid_595125, JString, required = true,
                                 default = nil)
  if valid_595125 != nil:
    section.add "campaign-id", valid_595125
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_595126 = query.getOrDefault("page-size")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "page-size", valid_595126
  var valid_595127 = query.getOrDefault("token")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "token", valid_595127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595128 = header.getOrDefault("X-Amz-Signature")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Signature", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-Content-Sha256", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Date")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Date", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Credential")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Credential", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-Security-Token")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-Security-Token", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Algorithm")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Algorithm", valid_595133
  var valid_595134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595134 = validateParameter(valid_595134, JString, required = false,
                                 default = nil)
  if valid_595134 != nil:
    section.add "X-Amz-SignedHeaders", valid_595134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595135: Call_GetCampaignActivities_595121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_595135.validator(path, query, header, formData, body)
  let scheme = call_595135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595135.url(scheme.get, call_595135.host, call_595135.base,
                         call_595135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595135, url, valid)

proc call*(call_595136: Call_GetCampaignActivities_595121; applicationId: string;
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
  var path_595137 = newJObject()
  var query_595138 = newJObject()
  add(path_595137, "application-id", newJString(applicationId))
  add(query_595138, "page-size", newJString(pageSize))
  add(path_595137, "campaign-id", newJString(campaignId))
  add(query_595138, "token", newJString(token))
  result = call_595136.call(path_595137, query_595138, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_595121(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_595122, base: "/",
    url: url_GetCampaignActivities_595123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_595139 = ref object of OpenApiRestCall_593373
proc url_GetCampaignDateRangeKpi_595141(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_595140(path: JsonNode; query: JsonNode;
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
  var valid_595142 = path.getOrDefault("kpi-name")
  valid_595142 = validateParameter(valid_595142, JString, required = true,
                                 default = nil)
  if valid_595142 != nil:
    section.add "kpi-name", valid_595142
  var valid_595143 = path.getOrDefault("application-id")
  valid_595143 = validateParameter(valid_595143, JString, required = true,
                                 default = nil)
  if valid_595143 != nil:
    section.add "application-id", valid_595143
  var valid_595144 = path.getOrDefault("campaign-id")
  valid_595144 = validateParameter(valid_595144, JString, required = true,
                                 default = nil)
  if valid_595144 != nil:
    section.add "campaign-id", valid_595144
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
  var valid_595145 = query.getOrDefault("end-time")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "end-time", valid_595145
  var valid_595146 = query.getOrDefault("page-size")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "page-size", valid_595146
  var valid_595147 = query.getOrDefault("start-time")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "start-time", valid_595147
  var valid_595148 = query.getOrDefault("next-token")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "next-token", valid_595148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595149 = header.getOrDefault("X-Amz-Signature")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Signature", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-Content-Sha256", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-Date")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-Date", valid_595151
  var valid_595152 = header.getOrDefault("X-Amz-Credential")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "X-Amz-Credential", valid_595152
  var valid_595153 = header.getOrDefault("X-Amz-Security-Token")
  valid_595153 = validateParameter(valid_595153, JString, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "X-Amz-Security-Token", valid_595153
  var valid_595154 = header.getOrDefault("X-Amz-Algorithm")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "X-Amz-Algorithm", valid_595154
  var valid_595155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "X-Amz-SignedHeaders", valid_595155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595156: Call_GetCampaignDateRangeKpi_595139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_595156.validator(path, query, header, formData, body)
  let scheme = call_595156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595156.url(scheme.get, call_595156.host, call_595156.base,
                         call_595156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595156, url, valid)

proc call*(call_595157: Call_GetCampaignDateRangeKpi_595139; kpiName: string;
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
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var path_595158 = newJObject()
  var query_595159 = newJObject()
  add(path_595158, "kpi-name", newJString(kpiName))
  add(path_595158, "application-id", newJString(applicationId))
  add(query_595159, "end-time", newJString(endTime))
  add(query_595159, "page-size", newJString(pageSize))
  add(path_595158, "campaign-id", newJString(campaignId))
  add(query_595159, "start-time", newJString(startTime))
  add(query_595159, "next-token", newJString(nextToken))
  result = call_595157.call(path_595158, query_595159, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_595139(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_595140, base: "/",
    url: url_GetCampaignDateRangeKpi_595141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_595160 = ref object of OpenApiRestCall_593373
proc url_GetCampaignVersion_595162(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_595161(path: JsonNode; query: JsonNode;
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
  var valid_595163 = path.getOrDefault("version")
  valid_595163 = validateParameter(valid_595163, JString, required = true,
                                 default = nil)
  if valid_595163 != nil:
    section.add "version", valid_595163
  var valid_595164 = path.getOrDefault("application-id")
  valid_595164 = validateParameter(valid_595164, JString, required = true,
                                 default = nil)
  if valid_595164 != nil:
    section.add "application-id", valid_595164
  var valid_595165 = path.getOrDefault("campaign-id")
  valid_595165 = validateParameter(valid_595165, JString, required = true,
                                 default = nil)
  if valid_595165 != nil:
    section.add "campaign-id", valid_595165
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595166 = header.getOrDefault("X-Amz-Signature")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "X-Amz-Signature", valid_595166
  var valid_595167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "X-Amz-Content-Sha256", valid_595167
  var valid_595168 = header.getOrDefault("X-Amz-Date")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-Date", valid_595168
  var valid_595169 = header.getOrDefault("X-Amz-Credential")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "X-Amz-Credential", valid_595169
  var valid_595170 = header.getOrDefault("X-Amz-Security-Token")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "X-Amz-Security-Token", valid_595170
  var valid_595171 = header.getOrDefault("X-Amz-Algorithm")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Algorithm", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-SignedHeaders", valid_595172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595173: Call_GetCampaignVersion_595160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_595173.validator(path, query, header, formData, body)
  let scheme = call_595173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595173.url(scheme.get, call_595173.host, call_595173.base,
                         call_595173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595173, url, valid)

proc call*(call_595174: Call_GetCampaignVersion_595160; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_595175 = newJObject()
  add(path_595175, "version", newJString(version))
  add(path_595175, "application-id", newJString(applicationId))
  add(path_595175, "campaign-id", newJString(campaignId))
  result = call_595174.call(path_595175, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_595160(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_595161, base: "/",
    url: url_GetCampaignVersion_595162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_595176 = ref object of OpenApiRestCall_593373
proc url_GetCampaignVersions_595178(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_595177(path: JsonNode; query: JsonNode;
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
  var valid_595179 = path.getOrDefault("application-id")
  valid_595179 = validateParameter(valid_595179, JString, required = true,
                                 default = nil)
  if valid_595179 != nil:
    section.add "application-id", valid_595179
  var valid_595180 = path.getOrDefault("campaign-id")
  valid_595180 = validateParameter(valid_595180, JString, required = true,
                                 default = nil)
  if valid_595180 != nil:
    section.add "campaign-id", valid_595180
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_595181 = query.getOrDefault("page-size")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "page-size", valid_595181
  var valid_595182 = query.getOrDefault("token")
  valid_595182 = validateParameter(valid_595182, JString, required = false,
                                 default = nil)
  if valid_595182 != nil:
    section.add "token", valid_595182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595183 = header.getOrDefault("X-Amz-Signature")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Signature", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Content-Sha256", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Date")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Date", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Credential")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Credential", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Security-Token")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Security-Token", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-Algorithm")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-Algorithm", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-SignedHeaders", valid_595189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595190: Call_GetCampaignVersions_595176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_595190.validator(path, query, header, formData, body)
  let scheme = call_595190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595190.url(scheme.get, call_595190.host, call_595190.base,
                         call_595190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595190, url, valid)

proc call*(call_595191: Call_GetCampaignVersions_595176; applicationId: string;
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
  var path_595192 = newJObject()
  var query_595193 = newJObject()
  add(path_595192, "application-id", newJString(applicationId))
  add(query_595193, "page-size", newJString(pageSize))
  add(path_595192, "campaign-id", newJString(campaignId))
  add(query_595193, "token", newJString(token))
  result = call_595191.call(path_595192, query_595193, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_595176(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_595177, base: "/",
    url: url_GetCampaignVersions_595178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_595194 = ref object of OpenApiRestCall_593373
proc url_GetChannels_595196(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_595195(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595197 = path.getOrDefault("application-id")
  valid_595197 = validateParameter(valid_595197, JString, required = true,
                                 default = nil)
  if valid_595197 != nil:
    section.add "application-id", valid_595197
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595198 = header.getOrDefault("X-Amz-Signature")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Signature", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Content-Sha256", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-Date")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-Date", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Credential")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Credential", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Security-Token")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Security-Token", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Algorithm")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Algorithm", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-SignedHeaders", valid_595204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595205: Call_GetChannels_595194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_595205.validator(path, query, header, formData, body)
  let scheme = call_595205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595205.url(scheme.get, call_595205.host, call_595205.base,
                         call_595205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595205, url, valid)

proc call*(call_595206: Call_GetChannels_595194; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595207 = newJObject()
  add(path_595207, "application-id", newJString(applicationId))
  result = call_595206.call(path_595207, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_595194(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_595195,
                                        base: "/", url: url_GetChannels_595196,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_595208 = ref object of OpenApiRestCall_593373
proc url_GetExportJob_595210(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_595209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595211 = path.getOrDefault("job-id")
  valid_595211 = validateParameter(valid_595211, JString, required = true,
                                 default = nil)
  if valid_595211 != nil:
    section.add "job-id", valid_595211
  var valid_595212 = path.getOrDefault("application-id")
  valid_595212 = validateParameter(valid_595212, JString, required = true,
                                 default = nil)
  if valid_595212 != nil:
    section.add "application-id", valid_595212
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595213 = header.getOrDefault("X-Amz-Signature")
  valid_595213 = validateParameter(valid_595213, JString, required = false,
                                 default = nil)
  if valid_595213 != nil:
    section.add "X-Amz-Signature", valid_595213
  var valid_595214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595214 = validateParameter(valid_595214, JString, required = false,
                                 default = nil)
  if valid_595214 != nil:
    section.add "X-Amz-Content-Sha256", valid_595214
  var valid_595215 = header.getOrDefault("X-Amz-Date")
  valid_595215 = validateParameter(valid_595215, JString, required = false,
                                 default = nil)
  if valid_595215 != nil:
    section.add "X-Amz-Date", valid_595215
  var valid_595216 = header.getOrDefault("X-Amz-Credential")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "X-Amz-Credential", valid_595216
  var valid_595217 = header.getOrDefault("X-Amz-Security-Token")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Security-Token", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Algorithm")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Algorithm", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-SignedHeaders", valid_595219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595220: Call_GetExportJob_595208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_595220.validator(path, query, header, formData, body)
  let scheme = call_595220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595220.url(scheme.get, call_595220.host, call_595220.base,
                         call_595220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595220, url, valid)

proc call*(call_595221: Call_GetExportJob_595208; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595222 = newJObject()
  add(path_595222, "job-id", newJString(jobId))
  add(path_595222, "application-id", newJString(applicationId))
  result = call_595221.call(path_595222, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_595208(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_595209, base: "/", url: url_GetExportJob_595210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_595223 = ref object of OpenApiRestCall_593373
proc url_GetImportJob_595225(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_595224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595226 = path.getOrDefault("job-id")
  valid_595226 = validateParameter(valid_595226, JString, required = true,
                                 default = nil)
  if valid_595226 != nil:
    section.add "job-id", valid_595226
  var valid_595227 = path.getOrDefault("application-id")
  valid_595227 = validateParameter(valid_595227, JString, required = true,
                                 default = nil)
  if valid_595227 != nil:
    section.add "application-id", valid_595227
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595228 = header.getOrDefault("X-Amz-Signature")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "X-Amz-Signature", valid_595228
  var valid_595229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-Content-Sha256", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Date")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Date", valid_595230
  var valid_595231 = header.getOrDefault("X-Amz-Credential")
  valid_595231 = validateParameter(valid_595231, JString, required = false,
                                 default = nil)
  if valid_595231 != nil:
    section.add "X-Amz-Credential", valid_595231
  var valid_595232 = header.getOrDefault("X-Amz-Security-Token")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-Security-Token", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Algorithm")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Algorithm", valid_595233
  var valid_595234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595234 = validateParameter(valid_595234, JString, required = false,
                                 default = nil)
  if valid_595234 != nil:
    section.add "X-Amz-SignedHeaders", valid_595234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595235: Call_GetImportJob_595223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_595235.validator(path, query, header, formData, body)
  let scheme = call_595235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595235.url(scheme.get, call_595235.host, call_595235.base,
                         call_595235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595235, url, valid)

proc call*(call_595236: Call_GetImportJob_595223; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_595237 = newJObject()
  add(path_595237, "job-id", newJString(jobId))
  add(path_595237, "application-id", newJString(applicationId))
  result = call_595236.call(path_595237, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_595223(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_595224, base: "/", url: url_GetImportJob_595225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_595238 = ref object of OpenApiRestCall_593373
proc url_GetJourneyDateRangeKpi_595240(protocol: Scheme; host: string; base: string;
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

proc validate_GetJourneyDateRangeKpi_595239(path: JsonNode; query: JsonNode;
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
  var valid_595241 = path.getOrDefault("kpi-name")
  valid_595241 = validateParameter(valid_595241, JString, required = true,
                                 default = nil)
  if valid_595241 != nil:
    section.add "kpi-name", valid_595241
  var valid_595242 = path.getOrDefault("application-id")
  valid_595242 = validateParameter(valid_595242, JString, required = true,
                                 default = nil)
  if valid_595242 != nil:
    section.add "application-id", valid_595242
  var valid_595243 = path.getOrDefault("journey-id")
  valid_595243 = validateParameter(valid_595243, JString, required = true,
                                 default = nil)
  if valid_595243 != nil:
    section.add "journey-id", valid_595243
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
  var valid_595244 = query.getOrDefault("end-time")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "end-time", valid_595244
  var valid_595245 = query.getOrDefault("page-size")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "page-size", valid_595245
  var valid_595246 = query.getOrDefault("start-time")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "start-time", valid_595246
  var valid_595247 = query.getOrDefault("next-token")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "next-token", valid_595247
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595248 = header.getOrDefault("X-Amz-Signature")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "X-Amz-Signature", valid_595248
  var valid_595249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "X-Amz-Content-Sha256", valid_595249
  var valid_595250 = header.getOrDefault("X-Amz-Date")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Date", valid_595250
  var valid_595251 = header.getOrDefault("X-Amz-Credential")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Credential", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Security-Token")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Security-Token", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Algorithm")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Algorithm", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-SignedHeaders", valid_595254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595255: Call_GetJourneyDateRangeKpi_595238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_595255.validator(path, query, header, formData, body)
  let scheme = call_595255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595255.url(scheme.get, call_595255.host, call_595255.base,
                         call_595255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595255, url, valid)

proc call*(call_595256: Call_GetJourneyDateRangeKpi_595238; kpiName: string;
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
  var path_595257 = newJObject()
  var query_595258 = newJObject()
  add(path_595257, "kpi-name", newJString(kpiName))
  add(path_595257, "application-id", newJString(applicationId))
  add(query_595258, "end-time", newJString(endTime))
  add(query_595258, "page-size", newJString(pageSize))
  add(path_595257, "journey-id", newJString(journeyId))
  add(query_595258, "start-time", newJString(startTime))
  add(query_595258, "next-token", newJString(nextToken))
  result = call_595256.call(path_595257, query_595258, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_595238(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_595239, base: "/",
    url: url_GetJourneyDateRangeKpi_595240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_595259 = ref object of OpenApiRestCall_593373
proc url_GetJourneyExecutionActivityMetrics_595261(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionActivityMetrics_595260(path: JsonNode;
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
  var valid_595262 = path.getOrDefault("application-id")
  valid_595262 = validateParameter(valid_595262, JString, required = true,
                                 default = nil)
  if valid_595262 != nil:
    section.add "application-id", valid_595262
  var valid_595263 = path.getOrDefault("journey-activity-id")
  valid_595263 = validateParameter(valid_595263, JString, required = true,
                                 default = nil)
  if valid_595263 != nil:
    section.add "journey-activity-id", valid_595263
  var valid_595264 = path.getOrDefault("journey-id")
  valid_595264 = validateParameter(valid_595264, JString, required = true,
                                 default = nil)
  if valid_595264 != nil:
    section.add "journey-id", valid_595264
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_595265 = query.getOrDefault("page-size")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "page-size", valid_595265
  var valid_595266 = query.getOrDefault("next-token")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "next-token", valid_595266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595267 = header.getOrDefault("X-Amz-Signature")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "X-Amz-Signature", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-Content-Sha256", valid_595268
  var valid_595269 = header.getOrDefault("X-Amz-Date")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Date", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Credential")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Credential", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Security-Token")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Security-Token", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Algorithm")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Algorithm", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-SignedHeaders", valid_595273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595274: Call_GetJourneyExecutionActivityMetrics_595259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_595274.validator(path, query, header, formData, body)
  let scheme = call_595274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595274.url(scheme.get, call_595274.host, call_595274.base,
                         call_595274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595274, url, valid)

proc call*(call_595275: Call_GetJourneyExecutionActivityMetrics_595259;
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
  var path_595276 = newJObject()
  var query_595277 = newJObject()
  add(path_595276, "application-id", newJString(applicationId))
  add(query_595277, "page-size", newJString(pageSize))
  add(path_595276, "journey-activity-id", newJString(journeyActivityId))
  add(path_595276, "journey-id", newJString(journeyId))
  add(query_595277, "next-token", newJString(nextToken))
  result = call_595275.call(path_595276, query_595277, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_595259(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_595260, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_595261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_595278 = ref object of OpenApiRestCall_593373
proc url_GetJourneyExecutionMetrics_595280(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_595279(path: JsonNode; query: JsonNode;
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
  var valid_595281 = path.getOrDefault("application-id")
  valid_595281 = validateParameter(valid_595281, JString, required = true,
                                 default = nil)
  if valid_595281 != nil:
    section.add "application-id", valid_595281
  var valid_595282 = path.getOrDefault("journey-id")
  valid_595282 = validateParameter(valid_595282, JString, required = true,
                                 default = nil)
  if valid_595282 != nil:
    section.add "journey-id", valid_595282
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_595283 = query.getOrDefault("page-size")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "page-size", valid_595283
  var valid_595284 = query.getOrDefault("next-token")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "next-token", valid_595284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595285 = header.getOrDefault("X-Amz-Signature")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Signature", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Content-Sha256", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Date")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Date", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Credential")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Credential", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Security-Token")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Security-Token", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Algorithm")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Algorithm", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-SignedHeaders", valid_595291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595292: Call_GetJourneyExecutionMetrics_595278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_595292.validator(path, query, header, formData, body)
  let scheme = call_595292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595292.url(scheme.get, call_595292.host, call_595292.base,
                         call_595292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595292, url, valid)

proc call*(call_595293: Call_GetJourneyExecutionMetrics_595278;
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
  var path_595294 = newJObject()
  var query_595295 = newJObject()
  add(path_595294, "application-id", newJString(applicationId))
  add(query_595295, "page-size", newJString(pageSize))
  add(path_595294, "journey-id", newJString(journeyId))
  add(query_595295, "next-token", newJString(nextToken))
  result = call_595293.call(path_595294, query_595295, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_595278(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_595279, base: "/",
    url: url_GetJourneyExecutionMetrics_595280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_595296 = ref object of OpenApiRestCall_593373
proc url_GetSegmentExportJobs_595298(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_595297(path: JsonNode; query: JsonNode;
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
  var valid_595299 = path.getOrDefault("application-id")
  valid_595299 = validateParameter(valid_595299, JString, required = true,
                                 default = nil)
  if valid_595299 != nil:
    section.add "application-id", valid_595299
  var valid_595300 = path.getOrDefault("segment-id")
  valid_595300 = validateParameter(valid_595300, JString, required = true,
                                 default = nil)
  if valid_595300 != nil:
    section.add "segment-id", valid_595300
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_595301 = query.getOrDefault("page-size")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "page-size", valid_595301
  var valid_595302 = query.getOrDefault("token")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "token", valid_595302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595303 = header.getOrDefault("X-Amz-Signature")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "X-Amz-Signature", valid_595303
  var valid_595304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "X-Amz-Content-Sha256", valid_595304
  var valid_595305 = header.getOrDefault("X-Amz-Date")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "X-Amz-Date", valid_595305
  var valid_595306 = header.getOrDefault("X-Amz-Credential")
  valid_595306 = validateParameter(valid_595306, JString, required = false,
                                 default = nil)
  if valid_595306 != nil:
    section.add "X-Amz-Credential", valid_595306
  var valid_595307 = header.getOrDefault("X-Amz-Security-Token")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "X-Amz-Security-Token", valid_595307
  var valid_595308 = header.getOrDefault("X-Amz-Algorithm")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "X-Amz-Algorithm", valid_595308
  var valid_595309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595309 = validateParameter(valid_595309, JString, required = false,
                                 default = nil)
  if valid_595309 != nil:
    section.add "X-Amz-SignedHeaders", valid_595309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595310: Call_GetSegmentExportJobs_595296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_595310.validator(path, query, header, formData, body)
  let scheme = call_595310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595310.url(scheme.get, call_595310.host, call_595310.base,
                         call_595310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595310, url, valid)

proc call*(call_595311: Call_GetSegmentExportJobs_595296; applicationId: string;
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
  var path_595312 = newJObject()
  var query_595313 = newJObject()
  add(path_595312, "application-id", newJString(applicationId))
  add(path_595312, "segment-id", newJString(segmentId))
  add(query_595313, "page-size", newJString(pageSize))
  add(query_595313, "token", newJString(token))
  result = call_595311.call(path_595312, query_595313, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_595296(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_595297, base: "/",
    url: url_GetSegmentExportJobs_595298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_595314 = ref object of OpenApiRestCall_593373
proc url_GetSegmentImportJobs_595316(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_595315(path: JsonNode; query: JsonNode;
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
  var valid_595317 = path.getOrDefault("application-id")
  valid_595317 = validateParameter(valid_595317, JString, required = true,
                                 default = nil)
  if valid_595317 != nil:
    section.add "application-id", valid_595317
  var valid_595318 = path.getOrDefault("segment-id")
  valid_595318 = validateParameter(valid_595318, JString, required = true,
                                 default = nil)
  if valid_595318 != nil:
    section.add "segment-id", valid_595318
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_595319 = query.getOrDefault("page-size")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "page-size", valid_595319
  var valid_595320 = query.getOrDefault("token")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "token", valid_595320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595321 = header.getOrDefault("X-Amz-Signature")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Signature", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-Content-Sha256", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Date")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Date", valid_595323
  var valid_595324 = header.getOrDefault("X-Amz-Credential")
  valid_595324 = validateParameter(valid_595324, JString, required = false,
                                 default = nil)
  if valid_595324 != nil:
    section.add "X-Amz-Credential", valid_595324
  var valid_595325 = header.getOrDefault("X-Amz-Security-Token")
  valid_595325 = validateParameter(valid_595325, JString, required = false,
                                 default = nil)
  if valid_595325 != nil:
    section.add "X-Amz-Security-Token", valid_595325
  var valid_595326 = header.getOrDefault("X-Amz-Algorithm")
  valid_595326 = validateParameter(valid_595326, JString, required = false,
                                 default = nil)
  if valid_595326 != nil:
    section.add "X-Amz-Algorithm", valid_595326
  var valid_595327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595327 = validateParameter(valid_595327, JString, required = false,
                                 default = nil)
  if valid_595327 != nil:
    section.add "X-Amz-SignedHeaders", valid_595327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595328: Call_GetSegmentImportJobs_595314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_595328.validator(path, query, header, formData, body)
  let scheme = call_595328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595328.url(scheme.get, call_595328.host, call_595328.base,
                         call_595328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595328, url, valid)

proc call*(call_595329: Call_GetSegmentImportJobs_595314; applicationId: string;
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
  var path_595330 = newJObject()
  var query_595331 = newJObject()
  add(path_595330, "application-id", newJString(applicationId))
  add(path_595330, "segment-id", newJString(segmentId))
  add(query_595331, "page-size", newJString(pageSize))
  add(query_595331, "token", newJString(token))
  result = call_595329.call(path_595330, query_595331, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_595314(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_595315, base: "/",
    url: url_GetSegmentImportJobs_595316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_595332 = ref object of OpenApiRestCall_593373
proc url_GetSegmentVersion_595334(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_595333(path: JsonNode; query: JsonNode;
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
  var valid_595335 = path.getOrDefault("version")
  valid_595335 = validateParameter(valid_595335, JString, required = true,
                                 default = nil)
  if valid_595335 != nil:
    section.add "version", valid_595335
  var valid_595336 = path.getOrDefault("application-id")
  valid_595336 = validateParameter(valid_595336, JString, required = true,
                                 default = nil)
  if valid_595336 != nil:
    section.add "application-id", valid_595336
  var valid_595337 = path.getOrDefault("segment-id")
  valid_595337 = validateParameter(valid_595337, JString, required = true,
                                 default = nil)
  if valid_595337 != nil:
    section.add "segment-id", valid_595337
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595338 = header.getOrDefault("X-Amz-Signature")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Signature", valid_595338
  var valid_595339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595339 = validateParameter(valid_595339, JString, required = false,
                                 default = nil)
  if valid_595339 != nil:
    section.add "X-Amz-Content-Sha256", valid_595339
  var valid_595340 = header.getOrDefault("X-Amz-Date")
  valid_595340 = validateParameter(valid_595340, JString, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "X-Amz-Date", valid_595340
  var valid_595341 = header.getOrDefault("X-Amz-Credential")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "X-Amz-Credential", valid_595341
  var valid_595342 = header.getOrDefault("X-Amz-Security-Token")
  valid_595342 = validateParameter(valid_595342, JString, required = false,
                                 default = nil)
  if valid_595342 != nil:
    section.add "X-Amz-Security-Token", valid_595342
  var valid_595343 = header.getOrDefault("X-Amz-Algorithm")
  valid_595343 = validateParameter(valid_595343, JString, required = false,
                                 default = nil)
  if valid_595343 != nil:
    section.add "X-Amz-Algorithm", valid_595343
  var valid_595344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595344 = validateParameter(valid_595344, JString, required = false,
                                 default = nil)
  if valid_595344 != nil:
    section.add "X-Amz-SignedHeaders", valid_595344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595345: Call_GetSegmentVersion_595332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_595345.validator(path, query, header, formData, body)
  let scheme = call_595345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595345.url(scheme.get, call_595345.host, call_595345.base,
                         call_595345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595345, url, valid)

proc call*(call_595346: Call_GetSegmentVersion_595332; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_595347 = newJObject()
  add(path_595347, "version", newJString(version))
  add(path_595347, "application-id", newJString(applicationId))
  add(path_595347, "segment-id", newJString(segmentId))
  result = call_595346.call(path_595347, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_595332(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_595333, base: "/",
    url: url_GetSegmentVersion_595334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_595348 = ref object of OpenApiRestCall_593373
proc url_GetSegmentVersions_595350(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_595349(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
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
  var valid_595351 = path.getOrDefault("application-id")
  valid_595351 = validateParameter(valid_595351, JString, required = true,
                                 default = nil)
  if valid_595351 != nil:
    section.add "application-id", valid_595351
  var valid_595352 = path.getOrDefault("segment-id")
  valid_595352 = validateParameter(valid_595352, JString, required = true,
                                 default = nil)
  if valid_595352 != nil:
    section.add "segment-id", valid_595352
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_595353 = query.getOrDefault("page-size")
  valid_595353 = validateParameter(valid_595353, JString, required = false,
                                 default = nil)
  if valid_595353 != nil:
    section.add "page-size", valid_595353
  var valid_595354 = query.getOrDefault("token")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "token", valid_595354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595355 = header.getOrDefault("X-Amz-Signature")
  valid_595355 = validateParameter(valid_595355, JString, required = false,
                                 default = nil)
  if valid_595355 != nil:
    section.add "X-Amz-Signature", valid_595355
  var valid_595356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595356 = validateParameter(valid_595356, JString, required = false,
                                 default = nil)
  if valid_595356 != nil:
    section.add "X-Amz-Content-Sha256", valid_595356
  var valid_595357 = header.getOrDefault("X-Amz-Date")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "X-Amz-Date", valid_595357
  var valid_595358 = header.getOrDefault("X-Amz-Credential")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Credential", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Security-Token")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Security-Token", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Algorithm")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Algorithm", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-SignedHeaders", valid_595361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595362: Call_GetSegmentVersions_595348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_595362.validator(path, query, header, formData, body)
  let scheme = call_595362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595362.url(scheme.get, call_595362.host, call_595362.base,
                         call_595362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595362, url, valid)

proc call*(call_595363: Call_GetSegmentVersions_595348; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_595364 = newJObject()
  var query_595365 = newJObject()
  add(path_595364, "application-id", newJString(applicationId))
  add(path_595364, "segment-id", newJString(segmentId))
  add(query_595365, "page-size", newJString(pageSize))
  add(query_595365, "token", newJString(token))
  result = call_595363.call(path_595364, query_595365, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_595348(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_595349, base: "/",
    url: url_GetSegmentVersions_595350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_595380 = ref object of OpenApiRestCall_593373
proc url_TagResource_595382(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_595381(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595383 = path.getOrDefault("resource-arn")
  valid_595383 = validateParameter(valid_595383, JString, required = true,
                                 default = nil)
  if valid_595383 != nil:
    section.add "resource-arn", valid_595383
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595384 = header.getOrDefault("X-Amz-Signature")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "X-Amz-Signature", valid_595384
  var valid_595385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595385 = validateParameter(valid_595385, JString, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "X-Amz-Content-Sha256", valid_595385
  var valid_595386 = header.getOrDefault("X-Amz-Date")
  valid_595386 = validateParameter(valid_595386, JString, required = false,
                                 default = nil)
  if valid_595386 != nil:
    section.add "X-Amz-Date", valid_595386
  var valid_595387 = header.getOrDefault("X-Amz-Credential")
  valid_595387 = validateParameter(valid_595387, JString, required = false,
                                 default = nil)
  if valid_595387 != nil:
    section.add "X-Amz-Credential", valid_595387
  var valid_595388 = header.getOrDefault("X-Amz-Security-Token")
  valid_595388 = validateParameter(valid_595388, JString, required = false,
                                 default = nil)
  if valid_595388 != nil:
    section.add "X-Amz-Security-Token", valid_595388
  var valid_595389 = header.getOrDefault("X-Amz-Algorithm")
  valid_595389 = validateParameter(valid_595389, JString, required = false,
                                 default = nil)
  if valid_595389 != nil:
    section.add "X-Amz-Algorithm", valid_595389
  var valid_595390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595390 = validateParameter(valid_595390, JString, required = false,
                                 default = nil)
  if valid_595390 != nil:
    section.add "X-Amz-SignedHeaders", valid_595390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595392: Call_TagResource_595380; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_595392.validator(path, query, header, formData, body)
  let scheme = call_595392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595392.url(scheme.get, call_595392.host, call_595392.base,
                         call_595392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595392, url, valid)

proc call*(call_595393: Call_TagResource_595380; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_595394 = newJObject()
  var body_595395 = newJObject()
  add(path_595394, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_595395 = body
  result = call_595393.call(path_595394, nil, nil, nil, body_595395)

var tagResource* = Call_TagResource_595380(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_595381,
                                        base: "/", url: url_TagResource_595382,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_595366 = ref object of OpenApiRestCall_593373
proc url_ListTagsForResource_595368(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_595367(path: JsonNode; query: JsonNode;
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
  var valid_595369 = path.getOrDefault("resource-arn")
  valid_595369 = validateParameter(valid_595369, JString, required = true,
                                 default = nil)
  if valid_595369 != nil:
    section.add "resource-arn", valid_595369
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595370 = header.getOrDefault("X-Amz-Signature")
  valid_595370 = validateParameter(valid_595370, JString, required = false,
                                 default = nil)
  if valid_595370 != nil:
    section.add "X-Amz-Signature", valid_595370
  var valid_595371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595371 = validateParameter(valid_595371, JString, required = false,
                                 default = nil)
  if valid_595371 != nil:
    section.add "X-Amz-Content-Sha256", valid_595371
  var valid_595372 = header.getOrDefault("X-Amz-Date")
  valid_595372 = validateParameter(valid_595372, JString, required = false,
                                 default = nil)
  if valid_595372 != nil:
    section.add "X-Amz-Date", valid_595372
  var valid_595373 = header.getOrDefault("X-Amz-Credential")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "X-Amz-Credential", valid_595373
  var valid_595374 = header.getOrDefault("X-Amz-Security-Token")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Security-Token", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Algorithm")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Algorithm", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-SignedHeaders", valid_595376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595377: Call_ListTagsForResource_595366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_595377.validator(path, query, header, formData, body)
  let scheme = call_595377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595377.url(scheme.get, call_595377.host, call_595377.base,
                         call_595377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595377, url, valid)

proc call*(call_595378: Call_ListTagsForResource_595366; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_595379 = newJObject()
  add(path_595379, "resource-arn", newJString(resourceArn))
  result = call_595378.call(path_595379, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_595366(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_595367, base: "/",
    url: url_ListTagsForResource_595368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_595396 = ref object of OpenApiRestCall_593373
proc url_ListTemplates_595398(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_595397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##                : The type of message template to include in the results. Valid values are: EMAIL, SMS, and PUSH. To include all types of templates in the results, don't include this parameter in your request.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_595399 = query.getOrDefault("prefix")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "prefix", valid_595399
  var valid_595400 = query.getOrDefault("page-size")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "page-size", valid_595400
  var valid_595401 = query.getOrDefault("template-type")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "template-type", valid_595401
  var valid_595402 = query.getOrDefault("next-token")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "next-token", valid_595402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595403 = header.getOrDefault("X-Amz-Signature")
  valid_595403 = validateParameter(valid_595403, JString, required = false,
                                 default = nil)
  if valid_595403 != nil:
    section.add "X-Amz-Signature", valid_595403
  var valid_595404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595404 = validateParameter(valid_595404, JString, required = false,
                                 default = nil)
  if valid_595404 != nil:
    section.add "X-Amz-Content-Sha256", valid_595404
  var valid_595405 = header.getOrDefault("X-Amz-Date")
  valid_595405 = validateParameter(valid_595405, JString, required = false,
                                 default = nil)
  if valid_595405 != nil:
    section.add "X-Amz-Date", valid_595405
  var valid_595406 = header.getOrDefault("X-Amz-Credential")
  valid_595406 = validateParameter(valid_595406, JString, required = false,
                                 default = nil)
  if valid_595406 != nil:
    section.add "X-Amz-Credential", valid_595406
  var valid_595407 = header.getOrDefault("X-Amz-Security-Token")
  valid_595407 = validateParameter(valid_595407, JString, required = false,
                                 default = nil)
  if valid_595407 != nil:
    section.add "X-Amz-Security-Token", valid_595407
  var valid_595408 = header.getOrDefault("X-Amz-Algorithm")
  valid_595408 = validateParameter(valid_595408, JString, required = false,
                                 default = nil)
  if valid_595408 != nil:
    section.add "X-Amz-Algorithm", valid_595408
  var valid_595409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-SignedHeaders", valid_595409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595410: Call_ListTemplates_595396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_595410.validator(path, query, header, formData, body)
  let scheme = call_595410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595410.url(scheme.get, call_595410.host, call_595410.base,
                         call_595410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595410, url, valid)

proc call*(call_595411: Call_ListTemplates_595396; prefix: string = "";
          pageSize: string = ""; templateType: string = ""; nextToken: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, SMS, and PUSH. To include all types of templates in the results, don't include this parameter in your request.
  ##   nextToken: string
  ##            : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  var query_595412 = newJObject()
  add(query_595412, "prefix", newJString(prefix))
  add(query_595412, "page-size", newJString(pageSize))
  add(query_595412, "template-type", newJString(templateType))
  add(query_595412, "next-token", newJString(nextToken))
  result = call_595411.call(nil, query_595412, nil, nil, nil)

var listTemplates* = Call_ListTemplates_595396(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_595397, base: "/",
    url: url_ListTemplates_595398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_595413 = ref object of OpenApiRestCall_593373
proc url_PhoneNumberValidate_595415(protocol: Scheme; host: string; base: string;
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

proc validate_PhoneNumberValidate_595414(path: JsonNode; query: JsonNode;
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
  var valid_595416 = header.getOrDefault("X-Amz-Signature")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Signature", valid_595416
  var valid_595417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "X-Amz-Content-Sha256", valid_595417
  var valid_595418 = header.getOrDefault("X-Amz-Date")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "X-Amz-Date", valid_595418
  var valid_595419 = header.getOrDefault("X-Amz-Credential")
  valid_595419 = validateParameter(valid_595419, JString, required = false,
                                 default = nil)
  if valid_595419 != nil:
    section.add "X-Amz-Credential", valid_595419
  var valid_595420 = header.getOrDefault("X-Amz-Security-Token")
  valid_595420 = validateParameter(valid_595420, JString, required = false,
                                 default = nil)
  if valid_595420 != nil:
    section.add "X-Amz-Security-Token", valid_595420
  var valid_595421 = header.getOrDefault("X-Amz-Algorithm")
  valid_595421 = validateParameter(valid_595421, JString, required = false,
                                 default = nil)
  if valid_595421 != nil:
    section.add "X-Amz-Algorithm", valid_595421
  var valid_595422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595422 = validateParameter(valid_595422, JString, required = false,
                                 default = nil)
  if valid_595422 != nil:
    section.add "X-Amz-SignedHeaders", valid_595422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595424: Call_PhoneNumberValidate_595413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_595424.validator(path, query, header, formData, body)
  let scheme = call_595424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595424.url(scheme.get, call_595424.host, call_595424.base,
                         call_595424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595424, url, valid)

proc call*(call_595425: Call_PhoneNumberValidate_595413; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_595426 = newJObject()
  if body != nil:
    body_595426 = body
  result = call_595425.call(nil, nil, nil, nil, body_595426)

var phoneNumberValidate* = Call_PhoneNumberValidate_595413(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_595414, base: "/",
    url: url_PhoneNumberValidate_595415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_595427 = ref object of OpenApiRestCall_593373
proc url_PutEvents_595429(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_595428(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595430 = path.getOrDefault("application-id")
  valid_595430 = validateParameter(valid_595430, JString, required = true,
                                 default = nil)
  if valid_595430 != nil:
    section.add "application-id", valid_595430
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595431 = header.getOrDefault("X-Amz-Signature")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "X-Amz-Signature", valid_595431
  var valid_595432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "X-Amz-Content-Sha256", valid_595432
  var valid_595433 = header.getOrDefault("X-Amz-Date")
  valid_595433 = validateParameter(valid_595433, JString, required = false,
                                 default = nil)
  if valid_595433 != nil:
    section.add "X-Amz-Date", valid_595433
  var valid_595434 = header.getOrDefault("X-Amz-Credential")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "X-Amz-Credential", valid_595434
  var valid_595435 = header.getOrDefault("X-Amz-Security-Token")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "X-Amz-Security-Token", valid_595435
  var valid_595436 = header.getOrDefault("X-Amz-Algorithm")
  valid_595436 = validateParameter(valid_595436, JString, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "X-Amz-Algorithm", valid_595436
  var valid_595437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595437 = validateParameter(valid_595437, JString, required = false,
                                 default = nil)
  if valid_595437 != nil:
    section.add "X-Amz-SignedHeaders", valid_595437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595439: Call_PutEvents_595427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_595439.validator(path, query, header, formData, body)
  let scheme = call_595439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595439.url(scheme.get, call_595439.host, call_595439.base,
                         call_595439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595439, url, valid)

proc call*(call_595440: Call_PutEvents_595427; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595441 = newJObject()
  var body_595442 = newJObject()
  add(path_595441, "application-id", newJString(applicationId))
  if body != nil:
    body_595442 = body
  result = call_595440.call(path_595441, nil, nil, nil, body_595442)

var putEvents* = Call_PutEvents_595427(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_595428,
                                    base: "/", url: url_PutEvents_595429,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_595443 = ref object of OpenApiRestCall_593373
proc url_RemoveAttributes_595445(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_595444(path: JsonNode; query: JsonNode;
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
  var valid_595446 = path.getOrDefault("attribute-type")
  valid_595446 = validateParameter(valid_595446, JString, required = true,
                                 default = nil)
  if valid_595446 != nil:
    section.add "attribute-type", valid_595446
  var valid_595447 = path.getOrDefault("application-id")
  valid_595447 = validateParameter(valid_595447, JString, required = true,
                                 default = nil)
  if valid_595447 != nil:
    section.add "application-id", valid_595447
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595448 = header.getOrDefault("X-Amz-Signature")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "X-Amz-Signature", valid_595448
  var valid_595449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "X-Amz-Content-Sha256", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-Date")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-Date", valid_595450
  var valid_595451 = header.getOrDefault("X-Amz-Credential")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Credential", valid_595451
  var valid_595452 = header.getOrDefault("X-Amz-Security-Token")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Security-Token", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-Algorithm")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-Algorithm", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-SignedHeaders", valid_595454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595456: Call_RemoveAttributes_595443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_595456.validator(path, query, header, formData, body)
  let scheme = call_595456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595456.url(scheme.get, call_595456.host, call_595456.base,
                         call_595456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595456, url, valid)

proc call*(call_595457: Call_RemoveAttributes_595443; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595458 = newJObject()
  var body_595459 = newJObject()
  add(path_595458, "attribute-type", newJString(attributeType))
  add(path_595458, "application-id", newJString(applicationId))
  if body != nil:
    body_595459 = body
  result = call_595457.call(path_595458, nil, nil, nil, body_595459)

var removeAttributes* = Call_RemoveAttributes_595443(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_595444, base: "/",
    url: url_RemoveAttributes_595445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_595460 = ref object of OpenApiRestCall_593373
proc url_SendMessages_595462(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_595461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595463 = path.getOrDefault("application-id")
  valid_595463 = validateParameter(valid_595463, JString, required = true,
                                 default = nil)
  if valid_595463 != nil:
    section.add "application-id", valid_595463
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595464 = header.getOrDefault("X-Amz-Signature")
  valid_595464 = validateParameter(valid_595464, JString, required = false,
                                 default = nil)
  if valid_595464 != nil:
    section.add "X-Amz-Signature", valid_595464
  var valid_595465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595465 = validateParameter(valid_595465, JString, required = false,
                                 default = nil)
  if valid_595465 != nil:
    section.add "X-Amz-Content-Sha256", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Date")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Date", valid_595466
  var valid_595467 = header.getOrDefault("X-Amz-Credential")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Credential", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Security-Token")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Security-Token", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Algorithm")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Algorithm", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-SignedHeaders", valid_595470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595472: Call_SendMessages_595460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_595472.validator(path, query, header, formData, body)
  let scheme = call_595472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595472.url(scheme.get, call_595472.host, call_595472.base,
                         call_595472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595472, url, valid)

proc call*(call_595473: Call_SendMessages_595460; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595474 = newJObject()
  var body_595475 = newJObject()
  add(path_595474, "application-id", newJString(applicationId))
  if body != nil:
    body_595475 = body
  result = call_595473.call(path_595474, nil, nil, nil, body_595475)

var sendMessages* = Call_SendMessages_595460(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_595461,
    base: "/", url: url_SendMessages_595462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_595476 = ref object of OpenApiRestCall_593373
proc url_SendUsersMessages_595478(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_595477(path: JsonNode; query: JsonNode;
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
  var valid_595479 = path.getOrDefault("application-id")
  valid_595479 = validateParameter(valid_595479, JString, required = true,
                                 default = nil)
  if valid_595479 != nil:
    section.add "application-id", valid_595479
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595480 = header.getOrDefault("X-Amz-Signature")
  valid_595480 = validateParameter(valid_595480, JString, required = false,
                                 default = nil)
  if valid_595480 != nil:
    section.add "X-Amz-Signature", valid_595480
  var valid_595481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595481 = validateParameter(valid_595481, JString, required = false,
                                 default = nil)
  if valid_595481 != nil:
    section.add "X-Amz-Content-Sha256", valid_595481
  var valid_595482 = header.getOrDefault("X-Amz-Date")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "X-Amz-Date", valid_595482
  var valid_595483 = header.getOrDefault("X-Amz-Credential")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "X-Amz-Credential", valid_595483
  var valid_595484 = header.getOrDefault("X-Amz-Security-Token")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Security-Token", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Algorithm")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Algorithm", valid_595485
  var valid_595486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-SignedHeaders", valid_595486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595488: Call_SendUsersMessages_595476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_595488.validator(path, query, header, formData, body)
  let scheme = call_595488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595488.url(scheme.get, call_595488.host, call_595488.base,
                         call_595488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595488, url, valid)

proc call*(call_595489: Call_SendUsersMessages_595476; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595490 = newJObject()
  var body_595491 = newJObject()
  add(path_595490, "application-id", newJString(applicationId))
  if body != nil:
    body_595491 = body
  result = call_595489.call(path_595490, nil, nil, nil, body_595491)

var sendUsersMessages* = Call_SendUsersMessages_595476(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_595477, base: "/",
    url: url_SendUsersMessages_595478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_595492 = ref object of OpenApiRestCall_593373
proc url_UntagResource_595494(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_595493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595495 = path.getOrDefault("resource-arn")
  valid_595495 = validateParameter(valid_595495, JString, required = true,
                                 default = nil)
  if valid_595495 != nil:
    section.add "resource-arn", valid_595495
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_595496 = query.getOrDefault("tagKeys")
  valid_595496 = validateParameter(valid_595496, JArray, required = true, default = nil)
  if valid_595496 != nil:
    section.add "tagKeys", valid_595496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595497 = header.getOrDefault("X-Amz-Signature")
  valid_595497 = validateParameter(valid_595497, JString, required = false,
                                 default = nil)
  if valid_595497 != nil:
    section.add "X-Amz-Signature", valid_595497
  var valid_595498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595498 = validateParameter(valid_595498, JString, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "X-Amz-Content-Sha256", valid_595498
  var valid_595499 = header.getOrDefault("X-Amz-Date")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-Date", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Credential")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Credential", valid_595500
  var valid_595501 = header.getOrDefault("X-Amz-Security-Token")
  valid_595501 = validateParameter(valid_595501, JString, required = false,
                                 default = nil)
  if valid_595501 != nil:
    section.add "X-Amz-Security-Token", valid_595501
  var valid_595502 = header.getOrDefault("X-Amz-Algorithm")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-Algorithm", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-SignedHeaders", valid_595503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595504: Call_UntagResource_595492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_595504.validator(path, query, header, formData, body)
  let scheme = call_595504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595504.url(scheme.get, call_595504.host, call_595504.base,
                         call_595504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595504, url, valid)

proc call*(call_595505: Call_UntagResource_595492; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_595506 = newJObject()
  var query_595507 = newJObject()
  add(path_595506, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_595507.add "tagKeys", tagKeys
  result = call_595505.call(path_595506, query_595507, nil, nil, nil)

var untagResource* = Call_UntagResource_595492(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_595493,
    base: "/", url: url_UntagResource_595494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_595508 = ref object of OpenApiRestCall_593373
proc url_UpdateEndpointsBatch_595510(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_595509(path: JsonNode; query: JsonNode;
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
  var valid_595511 = path.getOrDefault("application-id")
  valid_595511 = validateParameter(valid_595511, JString, required = true,
                                 default = nil)
  if valid_595511 != nil:
    section.add "application-id", valid_595511
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595512 = header.getOrDefault("X-Amz-Signature")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-Signature", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Content-Sha256", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-Date")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-Date", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Credential")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Credential", valid_595515
  var valid_595516 = header.getOrDefault("X-Amz-Security-Token")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "X-Amz-Security-Token", valid_595516
  var valid_595517 = header.getOrDefault("X-Amz-Algorithm")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-Algorithm", valid_595517
  var valid_595518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-SignedHeaders", valid_595518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595520: Call_UpdateEndpointsBatch_595508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_595520.validator(path, query, header, formData, body)
  let scheme = call_595520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595520.url(scheme.get, call_595520.host, call_595520.base,
                         call_595520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595520, url, valid)

proc call*(call_595521: Call_UpdateEndpointsBatch_595508; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_595522 = newJObject()
  var body_595523 = newJObject()
  add(path_595522, "application-id", newJString(applicationId))
  if body != nil:
    body_595523 = body
  result = call_595521.call(path_595522, nil, nil, nil, body_595523)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_595508(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_595509, base: "/",
    url: url_UpdateEndpointsBatch_595510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_595524 = ref object of OpenApiRestCall_593373
proc url_UpdateJourneyState_595526(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_595525(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Cancels an active journey.
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
  var valid_595527 = path.getOrDefault("application-id")
  valid_595527 = validateParameter(valid_595527, JString, required = true,
                                 default = nil)
  if valid_595527 != nil:
    section.add "application-id", valid_595527
  var valid_595528 = path.getOrDefault("journey-id")
  valid_595528 = validateParameter(valid_595528, JString, required = true,
                                 default = nil)
  if valid_595528 != nil:
    section.add "journey-id", valid_595528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595529 = header.getOrDefault("X-Amz-Signature")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Signature", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Content-Sha256", valid_595530
  var valid_595531 = header.getOrDefault("X-Amz-Date")
  valid_595531 = validateParameter(valid_595531, JString, required = false,
                                 default = nil)
  if valid_595531 != nil:
    section.add "X-Amz-Date", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Credential")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Credential", valid_595532
  var valid_595533 = header.getOrDefault("X-Amz-Security-Token")
  valid_595533 = validateParameter(valid_595533, JString, required = false,
                                 default = nil)
  if valid_595533 != nil:
    section.add "X-Amz-Security-Token", valid_595533
  var valid_595534 = header.getOrDefault("X-Amz-Algorithm")
  valid_595534 = validateParameter(valid_595534, JString, required = false,
                                 default = nil)
  if valid_595534 != nil:
    section.add "X-Amz-Algorithm", valid_595534
  var valid_595535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595535 = validateParameter(valid_595535, JString, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "X-Amz-SignedHeaders", valid_595535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595537: Call_UpdateJourneyState_595524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an active journey.
  ## 
  let valid = call_595537.validator(path, query, header, formData, body)
  let scheme = call_595537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595537.url(scheme.get, call_595537.host, call_595537.base,
                         call_595537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595537, url, valid)

proc call*(call_595538: Call_UpdateJourneyState_595524; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourneyState
  ## Cancels an active journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_595539 = newJObject()
  var body_595540 = newJObject()
  add(path_595539, "application-id", newJString(applicationId))
  if body != nil:
    body_595540 = body
  add(path_595539, "journey-id", newJString(journeyId))
  result = call_595538.call(path_595539, nil, nil, nil, body_595540)

var updateJourneyState* = Call_UpdateJourneyState_595524(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_595525, base: "/",
    url: url_UpdateJourneyState_595526, schemes: {Scheme.Https, Scheme.Http})
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
