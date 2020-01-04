
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  Call_CreateApp_601968 = ref object of OpenApiRestCall_601373
proc url_CreateApp_601970(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_601969(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601971 = header.getOrDefault("X-Amz-Signature")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Signature", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Content-Sha256", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Date")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Date", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-Credential")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Credential", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Security-Token")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Security-Token", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Algorithm")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Algorithm", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-SignedHeaders", valid_601977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601979: Call_CreateApp_601968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_601979.validator(path, query, header, formData, body)
  let scheme = call_601979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601979.url(scheme.get, call_601979.host, call_601979.base,
                         call_601979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601979, url, valid)

proc call*(call_601980: Call_CreateApp_601968; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_601981 = newJObject()
  if body != nil:
    body_601981 = body
  result = call_601980.call(nil, nil, nil, nil, body_601981)

var createApp* = Call_CreateApp_601968(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_601969,
                                    base: "/", url: url_CreateApp_601970,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_601711 = ref object of OpenApiRestCall_601373
proc url_GetApps_601713(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApps_601712(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601825 = query.getOrDefault("page-size")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "page-size", valid_601825
  var valid_601826 = query.getOrDefault("token")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "token", valid_601826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601827 = header.getOrDefault("X-Amz-Signature")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Signature", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Content-Sha256", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Date")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Date", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Credential")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Credential", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Security-Token")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Security-Token", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Algorithm")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Algorithm", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-SignedHeaders", valid_601833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601856: Call_GetApps_601711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_601856.validator(path, query, header, formData, body)
  let scheme = call_601856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601856.url(scheme.get, call_601856.host, call_601856.base,
                         call_601856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601856, url, valid)

proc call*(call_601927: Call_GetApps_601711; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_601928 = newJObject()
  add(query_601928, "page-size", newJString(pageSize))
  add(query_601928, "token", newJString(token))
  result = call_601927.call(nil, query_601928, nil, nil, nil)

var getApps* = Call_GetApps_601711(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_601712, base: "/",
                                url: url_GetApps_601713,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_602013 = ref object of OpenApiRestCall_601373
proc url_CreateCampaign_602015(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_602014(path: JsonNode; query: JsonNode;
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
  var valid_602016 = path.getOrDefault("application-id")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "application-id", valid_602016
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Content-Sha256", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Date")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Date", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Credential")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Credential", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Security-Token")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Security-Token", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Algorithm")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Algorithm", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602025: Call_CreateCampaign_602013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_602025.validator(path, query, header, formData, body)
  let scheme = call_602025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602025.url(scheme.get, call_602025.host, call_602025.base,
                         call_602025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602025, url, valid)

proc call*(call_602026: Call_CreateCampaign_602013; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602027 = newJObject()
  var body_602028 = newJObject()
  add(path_602027, "application-id", newJString(applicationId))
  if body != nil:
    body_602028 = body
  result = call_602026.call(path_602027, nil, nil, nil, body_602028)

var createCampaign* = Call_CreateCampaign_602013(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_602014, base: "/", url: url_CreateCampaign_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_601982 = ref object of OpenApiRestCall_601373
proc url_GetCampaigns_601984(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_601983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601999 = path.getOrDefault("application-id")
  valid_601999 = validateParameter(valid_601999, JString, required = true,
                                 default = nil)
  if valid_601999 != nil:
    section.add "application-id", valid_601999
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_602000 = query.getOrDefault("page-size")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "page-size", valid_602000
  var valid_602001 = query.getOrDefault("token")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "token", valid_602001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602002 = header.getOrDefault("X-Amz-Signature")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Signature", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Content-Sha256", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Date")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Date", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Credential")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Credential", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Security-Token")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Security-Token", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Algorithm")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Algorithm", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-SignedHeaders", valid_602008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_GetCampaigns_601982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_GetCampaigns_601982; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_602011 = newJObject()
  var query_602012 = newJObject()
  add(path_602011, "application-id", newJString(applicationId))
  add(query_602012, "page-size", newJString(pageSize))
  add(query_602012, "token", newJString(token))
  result = call_602010.call(path_602011, query_602012, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_601982(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_601983, base: "/", url: url_GetCampaigns_601984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_602045 = ref object of OpenApiRestCall_601373
proc url_UpdateEmailTemplate_602047(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailTemplate_602046(path: JsonNode; query: JsonNode;
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
  var valid_602048 = path.getOrDefault("template-name")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "template-name", valid_602048
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_602049 = query.getOrDefault("version")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "version", valid_602049
  var valid_602050 = query.getOrDefault("create-new-version")
  valid_602050 = validateParameter(valid_602050, JBool, required = false, default = nil)
  if valid_602050 != nil:
    section.add "create-new-version", valid_602050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602051 = header.getOrDefault("X-Amz-Signature")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Signature", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Date")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Date", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Credential")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Credential", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Security-Token")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Security-Token", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-SignedHeaders", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_UpdateEmailTemplate_602045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the email channel.
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602059, url, valid)

proc call*(call_602060: Call_UpdateEmailTemplate_602045; templateName: string;
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
  var path_602061 = newJObject()
  var query_602062 = newJObject()
  var body_602063 = newJObject()
  add(path_602061, "template-name", newJString(templateName))
  add(query_602062, "version", newJString(version))
  add(query_602062, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_602063 = body
  result = call_602060.call(path_602061, query_602062, nil, nil, body_602063)

var updateEmailTemplate* = Call_UpdateEmailTemplate_602045(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_602046, base: "/",
    url: url_UpdateEmailTemplate_602047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_602064 = ref object of OpenApiRestCall_601373
proc url_CreateEmailTemplate_602066(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailTemplate_602065(path: JsonNode; query: JsonNode;
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
  var valid_602067 = path.getOrDefault("template-name")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = nil)
  if valid_602067 != nil:
    section.add "template-name", valid_602067
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Content-Sha256", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602076: Call_CreateEmailTemplate_602064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the email channel.
  ## 
  let valid = call_602076.validator(path, query, header, formData, body)
  let scheme = call_602076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602076.url(scheme.get, call_602076.host, call_602076.base,
                         call_602076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602076, url, valid)

proc call*(call_602077: Call_CreateEmailTemplate_602064; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_602078 = newJObject()
  var body_602079 = newJObject()
  add(path_602078, "template-name", newJString(templateName))
  if body != nil:
    body_602079 = body
  result = call_602077.call(path_602078, nil, nil, nil, body_602079)

var createEmailTemplate* = Call_CreateEmailTemplate_602064(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_602065, base: "/",
    url: url_CreateEmailTemplate_602066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_602029 = ref object of OpenApiRestCall_601373
proc url_GetEmailTemplate_602031(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailTemplate_602030(path: JsonNode; query: JsonNode;
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
  var valid_602032 = path.getOrDefault("template-name")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "template-name", valid_602032
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602033 = query.getOrDefault("version")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "version", valid_602033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602034 = header.getOrDefault("X-Amz-Signature")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Signature", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Content-Sha256", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Date")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Date", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Credential")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Credential", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Security-Token")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Security-Token", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Algorithm")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Algorithm", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-SignedHeaders", valid_602040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_GetEmailTemplate_602029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ## 
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602041, url, valid)

proc call*(call_602042: Call_GetEmailTemplate_602029; templateName: string;
          version: string = ""): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602043 = newJObject()
  var query_602044 = newJObject()
  add(path_602043, "template-name", newJString(templateName))
  add(query_602044, "version", newJString(version))
  result = call_602042.call(path_602043, query_602044, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_602029(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_602030, base: "/",
    url: url_GetEmailTemplate_602031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_602080 = ref object of OpenApiRestCall_601373
proc url_DeleteEmailTemplate_602082(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailTemplate_602081(path: JsonNode; query: JsonNode;
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
  var valid_602083 = path.getOrDefault("template-name")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "template-name", valid_602083
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602084 = query.getOrDefault("version")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "version", valid_602084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Content-Sha256", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Date")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Date", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Credential")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Credential", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Security-Token")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Security-Token", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Algorithm")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Algorithm", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-SignedHeaders", valid_602091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_DeleteEmailTemplate_602080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the email channel.
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602092, url, valid)

proc call*(call_602093: Call_DeleteEmailTemplate_602080; templateName: string;
          version: string = ""): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template for messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602094 = newJObject()
  var query_602095 = newJObject()
  add(path_602094, "template-name", newJString(templateName))
  add(query_602095, "version", newJString(version))
  result = call_602093.call(path_602094, query_602095, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_602080(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_602081, base: "/",
    url: url_DeleteEmailTemplate_602082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_602113 = ref object of OpenApiRestCall_601373
proc url_CreateExportJob_602115(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = path.getOrDefault("application-id")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = nil)
  if valid_602116 != nil:
    section.add "application-id", valid_602116
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602117 = header.getOrDefault("X-Amz-Signature")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Signature", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Content-Sha256", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Date")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Date", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Credential")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Credential", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Security-Token")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Security-Token", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Algorithm")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Algorithm", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-SignedHeaders", valid_602123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602125: Call_CreateExportJob_602113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_602125.validator(path, query, header, formData, body)
  let scheme = call_602125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602125.url(scheme.get, call_602125.host, call_602125.base,
                         call_602125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602125, url, valid)

proc call*(call_602126: Call_CreateExportJob_602113; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602127 = newJObject()
  var body_602128 = newJObject()
  add(path_602127, "application-id", newJString(applicationId))
  if body != nil:
    body_602128 = body
  result = call_602126.call(path_602127, nil, nil, nil, body_602128)

var createExportJob* = Call_CreateExportJob_602113(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_602114, base: "/", url: url_CreateExportJob_602115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_602096 = ref object of OpenApiRestCall_601373
proc url_GetExportJobs_602098(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_602097(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602099 = path.getOrDefault("application-id")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = nil)
  if valid_602099 != nil:
    section.add "application-id", valid_602099
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_602100 = query.getOrDefault("page-size")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "page-size", valid_602100
  var valid_602101 = query.getOrDefault("token")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "token", valid_602101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602102 = header.getOrDefault("X-Amz-Signature")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Signature", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Content-Sha256", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Date")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Date", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Credential")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Credential", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Security-Token")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Security-Token", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Algorithm")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Algorithm", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-SignedHeaders", valid_602108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602109: Call_GetExportJobs_602096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_602109.validator(path, query, header, formData, body)
  let scheme = call_602109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602109.url(scheme.get, call_602109.host, call_602109.base,
                         call_602109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602109, url, valid)

proc call*(call_602110: Call_GetExportJobs_602096; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_602111 = newJObject()
  var query_602112 = newJObject()
  add(path_602111, "application-id", newJString(applicationId))
  add(query_602112, "page-size", newJString(pageSize))
  add(query_602112, "token", newJString(token))
  result = call_602110.call(path_602111, query_602112, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_602096(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_602097, base: "/", url: url_GetExportJobs_602098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_602146 = ref object of OpenApiRestCall_601373
proc url_CreateImportJob_602148(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_602147(path: JsonNode; query: JsonNode;
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
  var valid_602149 = path.getOrDefault("application-id")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = nil)
  if valid_602149 != nil:
    section.add "application-id", valid_602149
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_CreateImportJob_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_CreateImportJob_602146; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602160 = newJObject()
  var body_602161 = newJObject()
  add(path_602160, "application-id", newJString(applicationId))
  if body != nil:
    body_602161 = body
  result = call_602159.call(path_602160, nil, nil, nil, body_602161)

var createImportJob* = Call_CreateImportJob_602146(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_602147, base: "/", url: url_CreateImportJob_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_602129 = ref object of OpenApiRestCall_601373
proc url_GetImportJobs_602131(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_602130(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602132 = path.getOrDefault("application-id")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "application-id", valid_602132
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_602133 = query.getOrDefault("page-size")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "page-size", valid_602133
  var valid_602134 = query.getOrDefault("token")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "token", valid_602134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_GetImportJobs_602129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_GetImportJobs_602129; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_602144 = newJObject()
  var query_602145 = newJObject()
  add(path_602144, "application-id", newJString(applicationId))
  add(query_602145, "page-size", newJString(pageSize))
  add(query_602145, "token", newJString(token))
  result = call_602143.call(path_602144, query_602145, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_602129(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_602130, base: "/", url: url_GetImportJobs_602131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJourney_602179 = ref object of OpenApiRestCall_601373
proc url_CreateJourney_602181(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJourney_602180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602182 = path.getOrDefault("application-id")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = nil)
  if valid_602182 != nil:
    section.add "application-id", valid_602182
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602183 = header.getOrDefault("X-Amz-Signature")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Signature", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Content-Sha256", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Date")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Date", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Credential")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Credential", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Security-Token")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Security-Token", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Algorithm")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Algorithm", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-SignedHeaders", valid_602189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602191: Call_CreateJourney_602179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a journey for an application.
  ## 
  let valid = call_602191.validator(path, query, header, formData, body)
  let scheme = call_602191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602191.url(scheme.get, call_602191.host, call_602191.base,
                         call_602191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602191, url, valid)

proc call*(call_602192: Call_CreateJourney_602179; applicationId: string;
          body: JsonNode): Recallable =
  ## createJourney
  ## Creates a journey for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602193 = newJObject()
  var body_602194 = newJObject()
  add(path_602193, "application-id", newJString(applicationId))
  if body != nil:
    body_602194 = body
  result = call_602192.call(path_602193, nil, nil, nil, body_602194)

var createJourney* = Call_CreateJourney_602179(name: "createJourney",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys",
    validator: validate_CreateJourney_602180, base: "/", url: url_CreateJourney_602181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJourneys_602162 = ref object of OpenApiRestCall_601373
proc url_ListJourneys_602164(protocol: Scheme; host: string; base: string;
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

proc validate_ListJourneys_602163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602165 = path.getOrDefault("application-id")
  valid_602165 = validateParameter(valid_602165, JString, required = true,
                                 default = nil)
  if valid_602165 != nil:
    section.add "application-id", valid_602165
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_602166 = query.getOrDefault("page-size")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "page-size", valid_602166
  var valid_602167 = query.getOrDefault("token")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "token", valid_602167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602168 = header.getOrDefault("X-Amz-Signature")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Signature", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Content-Sha256", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Date")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Date", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Credential")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Credential", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Security-Token")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Security-Token", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Algorithm")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Algorithm", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-SignedHeaders", valid_602174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602175: Call_ListJourneys_602162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ## 
  let valid = call_602175.validator(path, query, header, formData, body)
  let scheme = call_602175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602175.url(scheme.get, call_602175.host, call_602175.base,
                         call_602175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602175, url, valid)

proc call*(call_602176: Call_ListJourneys_602162; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## listJourneys
  ## Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_602177 = newJObject()
  var query_602178 = newJObject()
  add(path_602177, "application-id", newJString(applicationId))
  add(query_602178, "page-size", newJString(pageSize))
  add(query_602178, "token", newJString(token))
  result = call_602176.call(path_602177, query_602178, nil, nil, nil)

var listJourneys* = Call_ListJourneys_602162(name: "listJourneys",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys", validator: validate_ListJourneys_602163,
    base: "/", url: url_ListJourneys_602164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_602211 = ref object of OpenApiRestCall_601373
proc url_UpdatePushTemplate_602213(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePushTemplate_602212(path: JsonNode; query: JsonNode;
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
  var valid_602214 = path.getOrDefault("template-name")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = nil)
  if valid_602214 != nil:
    section.add "template-name", valid_602214
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_602215 = query.getOrDefault("version")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "version", valid_602215
  var valid_602216 = query.getOrDefault("create-new-version")
  valid_602216 = validateParameter(valid_602216, JBool, required = false, default = nil)
  if valid_602216 != nil:
    section.add "create-new-version", valid_602216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602217 = header.getOrDefault("X-Amz-Signature")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Signature", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Content-Sha256", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Date")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Date", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Credential")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Credential", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Security-Token")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Security-Token", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Algorithm")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Algorithm", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-SignedHeaders", valid_602223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602225: Call_UpdatePushTemplate_602211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_602225.validator(path, query, header, formData, body)
  let scheme = call_602225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602225.url(scheme.get, call_602225.host, call_602225.base,
                         call_602225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602225, url, valid)

proc call*(call_602226: Call_UpdatePushTemplate_602211; templateName: string;
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
  var path_602227 = newJObject()
  var query_602228 = newJObject()
  var body_602229 = newJObject()
  add(path_602227, "template-name", newJString(templateName))
  add(query_602228, "version", newJString(version))
  add(query_602228, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_602229 = body
  result = call_602226.call(path_602227, query_602228, nil, nil, body_602229)

var updatePushTemplate* = Call_UpdatePushTemplate_602211(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_602212, base: "/",
    url: url_UpdatePushTemplate_602213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_602230 = ref object of OpenApiRestCall_601373
proc url_CreatePushTemplate_602232(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePushTemplate_602231(path: JsonNode; query: JsonNode;
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
  var valid_602233 = path.getOrDefault("template-name")
  valid_602233 = validateParameter(valid_602233, JString, required = true,
                                 default = nil)
  if valid_602233 != nil:
    section.add "template-name", valid_602233
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Content-Sha256", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Date")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Date", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Credential")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Credential", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Security-Token")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Security-Token", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Algorithm")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Algorithm", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-SignedHeaders", valid_602240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602242: Call_CreatePushTemplate_602230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_602242.validator(path, query, header, formData, body)
  let scheme = call_602242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602242.url(scheme.get, call_602242.host, call_602242.base,
                         call_602242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602242, url, valid)

proc call*(call_602243: Call_CreatePushTemplate_602230; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_602244 = newJObject()
  var body_602245 = newJObject()
  add(path_602244, "template-name", newJString(templateName))
  if body != nil:
    body_602245 = body
  result = call_602243.call(path_602244, nil, nil, nil, body_602245)

var createPushTemplate* = Call_CreatePushTemplate_602230(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_602231, base: "/",
    url: url_CreatePushTemplate_602232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_602195 = ref object of OpenApiRestCall_601373
proc url_GetPushTemplate_602197(protocol: Scheme; host: string; base: string;
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

proc validate_GetPushTemplate_602196(path: JsonNode; query: JsonNode;
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
  var valid_602198 = path.getOrDefault("template-name")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = nil)
  if valid_602198 != nil:
    section.add "template-name", valid_602198
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602199 = query.getOrDefault("version")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "version", valid_602199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Content-Sha256", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Date")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Date", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Credential")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Credential", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Security-Token")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Security-Token", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Algorithm")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Algorithm", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-SignedHeaders", valid_602206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602207: Call_GetPushTemplate_602195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ## 
  let valid = call_602207.validator(path, query, header, formData, body)
  let scheme = call_602207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602207.url(scheme.get, call_602207.host, call_602207.base,
                         call_602207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602207, url, valid)

proc call*(call_602208: Call_GetPushTemplate_602195; templateName: string;
          version: string = ""): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602209 = newJObject()
  var query_602210 = newJObject()
  add(path_602209, "template-name", newJString(templateName))
  add(query_602210, "version", newJString(version))
  result = call_602208.call(path_602209, query_602210, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_602195(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_602196, base: "/", url: url_GetPushTemplate_602197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_602246 = ref object of OpenApiRestCall_601373
proc url_DeletePushTemplate_602248(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePushTemplate_602247(path: JsonNode; query: JsonNode;
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
  var valid_602249 = path.getOrDefault("template-name")
  valid_602249 = validateParameter(valid_602249, JString, required = true,
                                 default = nil)
  if valid_602249 != nil:
    section.add "template-name", valid_602249
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602250 = query.getOrDefault("version")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "version", valid_602250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602251 = header.getOrDefault("X-Amz-Signature")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Signature", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Content-Sha256", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Date")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Date", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Credential")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Credential", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Security-Token")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Security-Token", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Algorithm")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Algorithm", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-SignedHeaders", valid_602257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_DeletePushTemplate_602246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through a push notification channel.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_DeletePushTemplate_602246; templateName: string;
          version: string = ""): Recallable =
  ## deletePushTemplate
  ## Deletes a message template for messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602260 = newJObject()
  var query_602261 = newJObject()
  add(path_602260, "template-name", newJString(templateName))
  add(query_602261, "version", newJString(version))
  result = call_602259.call(path_602260, query_602261, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_602246(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_602247, base: "/",
    url: url_DeletePushTemplate_602248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_602279 = ref object of OpenApiRestCall_601373
proc url_CreateSegment_602281(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_602280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602282 = path.getOrDefault("application-id")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = nil)
  if valid_602282 != nil:
    section.add "application-id", valid_602282
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Credential")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Credential", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Security-Token")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Security-Token", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Algorithm")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Algorithm", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_CreateSegment_602279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_CreateSegment_602279; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602293 = newJObject()
  var body_602294 = newJObject()
  add(path_602293, "application-id", newJString(applicationId))
  if body != nil:
    body_602294 = body
  result = call_602292.call(path_602293, nil, nil, nil, body_602294)

var createSegment* = Call_CreateSegment_602279(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_602280, base: "/", url: url_CreateSegment_602281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_602262 = ref object of OpenApiRestCall_601373
proc url_GetSegments_602264(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_602263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602265 = path.getOrDefault("application-id")
  valid_602265 = validateParameter(valid_602265, JString, required = true,
                                 default = nil)
  if valid_602265 != nil:
    section.add "application-id", valid_602265
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_602266 = query.getOrDefault("page-size")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "page-size", valid_602266
  var valid_602267 = query.getOrDefault("token")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "token", valid_602267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Date")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Date", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Credential")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Credential", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Algorithm")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Algorithm", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602275: Call_GetSegments_602262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_602275.validator(path, query, header, formData, body)
  let scheme = call_602275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602275.url(scheme.get, call_602275.host, call_602275.base,
                         call_602275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602275, url, valid)

proc call*(call_602276: Call_GetSegments_602262; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_602277 = newJObject()
  var query_602278 = newJObject()
  add(path_602277, "application-id", newJString(applicationId))
  add(query_602278, "page-size", newJString(pageSize))
  add(query_602278, "token", newJString(token))
  result = call_602276.call(path_602277, query_602278, nil, nil, nil)

var getSegments* = Call_GetSegments_602262(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_602263,
                                        base: "/", url: url_GetSegments_602264,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_602311 = ref object of OpenApiRestCall_601373
proc url_UpdateSmsTemplate_602313(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsTemplate_602312(path: JsonNode; query: JsonNode;
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
  var valid_602314 = path.getOrDefault("template-name")
  valid_602314 = validateParameter(valid_602314, JString, required = true,
                                 default = nil)
  if valid_602314 != nil:
    section.add "template-name", valid_602314
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_602315 = query.getOrDefault("version")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "version", valid_602315
  var valid_602316 = query.getOrDefault("create-new-version")
  valid_602316 = validateParameter(valid_602316, JBool, required = false, default = nil)
  if valid_602316 != nil:
    section.add "create-new-version", valid_602316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602317 = header.getOrDefault("X-Amz-Signature")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Signature", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Content-Sha256", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Date")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Date", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Credential")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Credential", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Security-Token")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Security-Token", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Algorithm")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Algorithm", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-SignedHeaders", valid_602323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602325: Call_UpdateSmsTemplate_602311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_602325.validator(path, query, header, formData, body)
  let scheme = call_602325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602325.url(scheme.get, call_602325.host, call_602325.base,
                         call_602325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602325, url, valid)

proc call*(call_602326: Call_UpdateSmsTemplate_602311; templateName: string;
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
  var path_602327 = newJObject()
  var query_602328 = newJObject()
  var body_602329 = newJObject()
  add(path_602327, "template-name", newJString(templateName))
  add(query_602328, "version", newJString(version))
  add(query_602328, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_602329 = body
  result = call_602326.call(path_602327, query_602328, nil, nil, body_602329)

var updateSmsTemplate* = Call_UpdateSmsTemplate_602311(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_602312, base: "/",
    url: url_UpdateSmsTemplate_602313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_602330 = ref object of OpenApiRestCall_601373
proc url_CreateSmsTemplate_602332(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSmsTemplate_602331(path: JsonNode; query: JsonNode;
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
  var valid_602333 = path.getOrDefault("template-name")
  valid_602333 = validateParameter(valid_602333, JString, required = true,
                                 default = nil)
  if valid_602333 != nil:
    section.add "template-name", valid_602333
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602334 = header.getOrDefault("X-Amz-Signature")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Signature", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Content-Sha256", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Date")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Date", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Credential")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Credential", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Security-Token")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Security-Token", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Algorithm")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Algorithm", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-SignedHeaders", valid_602340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602342: Call_CreateSmsTemplate_602330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_602342.validator(path, query, header, formData, body)
  let scheme = call_602342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602342.url(scheme.get, call_602342.host, call_602342.base,
                         call_602342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602342, url, valid)

proc call*(call_602343: Call_CreateSmsTemplate_602330; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_602344 = newJObject()
  var body_602345 = newJObject()
  add(path_602344, "template-name", newJString(templateName))
  if body != nil:
    body_602345 = body
  result = call_602343.call(path_602344, nil, nil, nil, body_602345)

var createSmsTemplate* = Call_CreateSmsTemplate_602330(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_602331, base: "/",
    url: url_CreateSmsTemplate_602332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_602295 = ref object of OpenApiRestCall_601373
proc url_GetSmsTemplate_602297(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsTemplate_602296(path: JsonNode; query: JsonNode;
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
  var valid_602298 = path.getOrDefault("template-name")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = nil)
  if valid_602298 != nil:
    section.add "template-name", valid_602298
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602299 = query.getOrDefault("version")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "version", valid_602299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602307: Call_GetSmsTemplate_602295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ## 
  let valid = call_602307.validator(path, query, header, formData, body)
  let scheme = call_602307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602307.url(scheme.get, call_602307.host, call_602307.base,
                         call_602307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602307, url, valid)

proc call*(call_602308: Call_GetSmsTemplate_602295; templateName: string;
          version: string = ""): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602309 = newJObject()
  var query_602310 = newJObject()
  add(path_602309, "template-name", newJString(templateName))
  add(query_602310, "version", newJString(version))
  result = call_602308.call(path_602309, query_602310, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_602295(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_602296, base: "/", url: url_GetSmsTemplate_602297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_602346 = ref object of OpenApiRestCall_601373
proc url_DeleteSmsTemplate_602348(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsTemplate_602347(path: JsonNode; query: JsonNode;
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
  var valid_602349 = path.getOrDefault("template-name")
  valid_602349 = validateParameter(valid_602349, JString, required = true,
                                 default = nil)
  if valid_602349 != nil:
    section.add "template-name", valid_602349
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602350 = query.getOrDefault("version")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "version", valid_602350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602351 = header.getOrDefault("X-Amz-Signature")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Signature", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Content-Sha256", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Date")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Date", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Credential")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Credential", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Security-Token")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Security-Token", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Algorithm")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Algorithm", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-SignedHeaders", valid_602357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602358: Call_DeleteSmsTemplate_602346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the SMS channel.
  ## 
  let valid = call_602358.validator(path, query, header, formData, body)
  let scheme = call_602358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602358.url(scheme.get, call_602358.host, call_602358.base,
                         call_602358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602358, url, valid)

proc call*(call_602359: Call_DeleteSmsTemplate_602346; templateName: string;
          version: string = ""): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template for messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602360 = newJObject()
  var query_602361 = newJObject()
  add(path_602360, "template-name", newJString(templateName))
  add(query_602361, "version", newJString(version))
  result = call_602359.call(path_602360, query_602361, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_602346(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_602347, base: "/",
    url: url_DeleteSmsTemplate_602348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceTemplate_602378 = ref object of OpenApiRestCall_601373
proc url_UpdateVoiceTemplate_602380(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceTemplate_602379(path: JsonNode; query: JsonNode;
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
  var valid_602381 = path.getOrDefault("template-name")
  valid_602381 = validateParameter(valid_602381, JString, required = true,
                                 default = nil)
  if valid_602381 != nil:
    section.add "template-name", valid_602381
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  ##   create-new-version: JBool
  ##                     : <p>Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to the latest existing version of the template.</p><p> If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.</p>
  section = newJObject()
  var valid_602382 = query.getOrDefault("version")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "version", valid_602382
  var valid_602383 = query.getOrDefault("create-new-version")
  valid_602383 = validateParameter(valid_602383, JBool, required = false, default = nil)
  if valid_602383 != nil:
    section.add "create-new-version", valid_602383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602384 = header.getOrDefault("X-Amz-Signature")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Signature", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Content-Sha256", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Date")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Date", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Credential")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Credential", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Security-Token")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Security-Token", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Algorithm")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Algorithm", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-SignedHeaders", valid_602390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602392: Call_UpdateVoiceTemplate_602378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template for messages that are sent through the voice channel.
  ## 
  let valid = call_602392.validator(path, query, header, formData, body)
  let scheme = call_602392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602392.url(scheme.get, call_602392.host, call_602392.base,
                         call_602392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602392, url, valid)

proc call*(call_602393: Call_UpdateVoiceTemplate_602378; templateName: string;
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
  var path_602394 = newJObject()
  var query_602395 = newJObject()
  var body_602396 = newJObject()
  add(path_602394, "template-name", newJString(templateName))
  add(query_602395, "version", newJString(version))
  add(query_602395, "create-new-version", newJBool(createNewVersion))
  if body != nil:
    body_602396 = body
  result = call_602393.call(path_602394, query_602395, nil, nil, body_602396)

var updateVoiceTemplate* = Call_UpdateVoiceTemplate_602378(
    name: "updateVoiceTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_UpdateVoiceTemplate_602379, base: "/",
    url: url_UpdateVoiceTemplate_602380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceTemplate_602397 = ref object of OpenApiRestCall_601373
proc url_CreateVoiceTemplate_602399(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceTemplate_602398(path: JsonNode; query: JsonNode;
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
  var valid_602400 = path.getOrDefault("template-name")
  valid_602400 = validateParameter(valid_602400, JString, required = true,
                                 default = nil)
  if valid_602400 != nil:
    section.add "template-name", valid_602400
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602401 = header.getOrDefault("X-Amz-Signature")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Signature", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Content-Sha256", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Date")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Date", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Credential")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Credential", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Security-Token")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Security-Token", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Algorithm")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Algorithm", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-SignedHeaders", valid_602407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602409: Call_CreateVoiceTemplate_602397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_602409.validator(path, query, header, formData, body)
  let scheme = call_602409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602409.url(scheme.get, call_602409.host, call_602409.base,
                         call_602409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602409, url, valid)

proc call*(call_602410: Call_CreateVoiceTemplate_602397; templateName: string;
          body: JsonNode): Recallable =
  ## createVoiceTemplate
  ## Creates a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_602411 = newJObject()
  var body_602412 = newJObject()
  add(path_602411, "template-name", newJString(templateName))
  if body != nil:
    body_602412 = body
  result = call_602410.call(path_602411, nil, nil, nil, body_602412)

var createVoiceTemplate* = Call_CreateVoiceTemplate_602397(
    name: "createVoiceTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_CreateVoiceTemplate_602398, base: "/",
    url: url_CreateVoiceTemplate_602399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceTemplate_602362 = ref object of OpenApiRestCall_601373
proc url_GetVoiceTemplate_602364(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceTemplate_602363(path: JsonNode; query: JsonNode;
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
  var valid_602365 = path.getOrDefault("template-name")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = nil)
  if valid_602365 != nil:
    section.add "template-name", valid_602365
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602366 = query.getOrDefault("version")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "version", valid_602366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602367 = header.getOrDefault("X-Amz-Signature")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Signature", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Date")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Date", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Credential")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Credential", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Security-Token")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Security-Token", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Algorithm")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Algorithm", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602374: Call_GetVoiceTemplate_602362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ## 
  let valid = call_602374.validator(path, query, header, formData, body)
  let scheme = call_602374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602374.url(scheme.get, call_602374.host, call_602374.base,
                         call_602374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602374, url, valid)

proc call*(call_602375: Call_GetVoiceTemplate_602362; templateName: string;
          version: string = ""): Recallable =
  ## getVoiceTemplate
  ## Retrieves the content and settings of a message template for messages that are sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602376 = newJObject()
  var query_602377 = newJObject()
  add(path_602376, "template-name", newJString(templateName))
  add(query_602377, "version", newJString(version))
  result = call_602375.call(path_602376, query_602377, nil, nil, nil)

var getVoiceTemplate* = Call_GetVoiceTemplate_602362(name: "getVoiceTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/voice",
    validator: validate_GetVoiceTemplate_602363, base: "/",
    url: url_GetVoiceTemplate_602364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceTemplate_602413 = ref object of OpenApiRestCall_601373
proc url_DeleteVoiceTemplate_602415(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceTemplate_602414(path: JsonNode; query: JsonNode;
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
  var valid_602416 = path.getOrDefault("template-name")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = nil)
  if valid_602416 != nil:
    section.add "template-name", valid_602416
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  section = newJObject()
  var valid_602417 = query.getOrDefault("version")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "version", valid_602417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602418 = header.getOrDefault("X-Amz-Signature")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Signature", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Content-Sha256", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Date")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Date", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Credential")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Credential", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Security-Token")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Security-Token", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Algorithm")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Algorithm", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-SignedHeaders", valid_602424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602425: Call_DeleteVoiceTemplate_602413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template for messages that were sent through the voice channel.
  ## 
  let valid = call_602425.validator(path, query, header, formData, body)
  let scheme = call_602425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602425.url(scheme.get, call_602425.host, call_602425.base,
                         call_602425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602425, url, valid)

proc call*(call_602426: Call_DeleteVoiceTemplate_602413; templateName: string;
          version: string = ""): Recallable =
  ## deleteVoiceTemplate
  ## Deletes a message template for messages that were sent through the voice channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   version: string
  ##          : <p>The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the <link  linkend="templates-template-name-template-type-versions">Template Versions</link> resource.</p> <p>If specified, this value must match the identifier of an existing template version. If specified for an update operation, this value must match the identifier of the latest existing version of the template. This restriction helps ensure that race conditions don't occur.</p> <p>If you don't specify a value for this parameter, Amazon Pinpoint does the following:</p> <ul><li><p>For a get operation, retrieves information about the active version of the template.</p></li> <li><p>For an update operation, saves the updates to the latest existing version of the template, if the create-new-version parameter isn't used or is set to false.</p></li> <li><p>For a delete operation, deletes the template, including all versions of the template.</p></li></ul>
  var path_602427 = newJObject()
  var query_602428 = newJObject()
  add(path_602427, "template-name", newJString(templateName))
  add(query_602428, "version", newJString(version))
  result = call_602426.call(path_602427, query_602428, nil, nil, nil)

var deleteVoiceTemplate* = Call_DeleteVoiceTemplate_602413(
    name: "deleteVoiceTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/voice",
    validator: validate_DeleteVoiceTemplate_602414, base: "/",
    url: url_DeleteVoiceTemplate_602415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_602443 = ref object of OpenApiRestCall_601373
proc url_UpdateAdmChannel_602445(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_602444(path: JsonNode; query: JsonNode;
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
  var valid_602446 = path.getOrDefault("application-id")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "application-id", valid_602446
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602447 = header.getOrDefault("X-Amz-Signature")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Signature", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Content-Sha256", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Date")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Date", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Credential")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Credential", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Security-Token")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Security-Token", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Algorithm")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Algorithm", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-SignedHeaders", valid_602453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602455: Call_UpdateAdmChannel_602443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_602455.validator(path, query, header, formData, body)
  let scheme = call_602455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602455.url(scheme.get, call_602455.host, call_602455.base,
                         call_602455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602455, url, valid)

proc call*(call_602456: Call_UpdateAdmChannel_602443; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602457 = newJObject()
  var body_602458 = newJObject()
  add(path_602457, "application-id", newJString(applicationId))
  if body != nil:
    body_602458 = body
  result = call_602456.call(path_602457, nil, nil, nil, body_602458)

var updateAdmChannel* = Call_UpdateAdmChannel_602443(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_602444, base: "/",
    url: url_UpdateAdmChannel_602445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_602429 = ref object of OpenApiRestCall_601373
proc url_GetAdmChannel_602431(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_602430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602432 = path.getOrDefault("application-id")
  valid_602432 = validateParameter(valid_602432, JString, required = true,
                                 default = nil)
  if valid_602432 != nil:
    section.add "application-id", valid_602432
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602433 = header.getOrDefault("X-Amz-Signature")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Signature", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Content-Sha256", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Date")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Date", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Credential")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Credential", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Algorithm")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Algorithm", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602440: Call_GetAdmChannel_602429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_602440.validator(path, query, header, formData, body)
  let scheme = call_602440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602440.url(scheme.get, call_602440.host, call_602440.base,
                         call_602440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602440, url, valid)

proc call*(call_602441: Call_GetAdmChannel_602429; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602442 = newJObject()
  add(path_602442, "application-id", newJString(applicationId))
  result = call_602441.call(path_602442, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_602429(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_602430, base: "/", url: url_GetAdmChannel_602431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_602459 = ref object of OpenApiRestCall_601373
proc url_DeleteAdmChannel_602461(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_602460(path: JsonNode; query: JsonNode;
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
  var valid_602462 = path.getOrDefault("application-id")
  valid_602462 = validateParameter(valid_602462, JString, required = true,
                                 default = nil)
  if valid_602462 != nil:
    section.add "application-id", valid_602462
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602463 = header.getOrDefault("X-Amz-Signature")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Signature", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Content-Sha256", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Date")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Date", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Credential")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Credential", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Security-Token")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Security-Token", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Algorithm")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Algorithm", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-SignedHeaders", valid_602469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602470: Call_DeleteAdmChannel_602459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602470.validator(path, query, header, formData, body)
  let scheme = call_602470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602470.url(scheme.get, call_602470.host, call_602470.base,
                         call_602470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602470, url, valid)

proc call*(call_602471: Call_DeleteAdmChannel_602459; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602472 = newJObject()
  add(path_602472, "application-id", newJString(applicationId))
  result = call_602471.call(path_602472, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_602459(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_602460, base: "/",
    url: url_DeleteAdmChannel_602461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_602487 = ref object of OpenApiRestCall_601373
proc url_UpdateApnsChannel_602489(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_602488(path: JsonNode; query: JsonNode;
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
  var valid_602490 = path.getOrDefault("application-id")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = nil)
  if valid_602490 != nil:
    section.add "application-id", valid_602490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602491 = header.getOrDefault("X-Amz-Signature")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Signature", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Content-Sha256", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Date")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Date", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Credential")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Credential", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Security-Token")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Security-Token", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Algorithm")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Algorithm", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-SignedHeaders", valid_602497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602499: Call_UpdateApnsChannel_602487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_602499.validator(path, query, header, formData, body)
  let scheme = call_602499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602499.url(scheme.get, call_602499.host, call_602499.base,
                         call_602499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602499, url, valid)

proc call*(call_602500: Call_UpdateApnsChannel_602487; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602501 = newJObject()
  var body_602502 = newJObject()
  add(path_602501, "application-id", newJString(applicationId))
  if body != nil:
    body_602502 = body
  result = call_602500.call(path_602501, nil, nil, nil, body_602502)

var updateApnsChannel* = Call_UpdateApnsChannel_602487(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_602488, base: "/",
    url: url_UpdateApnsChannel_602489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_602473 = ref object of OpenApiRestCall_601373
proc url_GetApnsChannel_602475(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_602474(path: JsonNode; query: JsonNode;
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
  var valid_602476 = path.getOrDefault("application-id")
  valid_602476 = validateParameter(valid_602476, JString, required = true,
                                 default = nil)
  if valid_602476 != nil:
    section.add "application-id", valid_602476
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602477 = header.getOrDefault("X-Amz-Signature")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Signature", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Content-Sha256", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Date")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Date", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Credential")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Credential", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Security-Token")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Security-Token", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Algorithm")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Algorithm", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-SignedHeaders", valid_602483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602484: Call_GetApnsChannel_602473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_602484.validator(path, query, header, formData, body)
  let scheme = call_602484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602484.url(scheme.get, call_602484.host, call_602484.base,
                         call_602484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602484, url, valid)

proc call*(call_602485: Call_GetApnsChannel_602473; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602486 = newJObject()
  add(path_602486, "application-id", newJString(applicationId))
  result = call_602485.call(path_602486, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_602473(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_602474, base: "/", url: url_GetApnsChannel_602475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_602503 = ref object of OpenApiRestCall_601373
proc url_DeleteApnsChannel_602505(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_602504(path: JsonNode; query: JsonNode;
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
  var valid_602506 = path.getOrDefault("application-id")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "application-id", valid_602506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602507 = header.getOrDefault("X-Amz-Signature")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Signature", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Content-Sha256", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Date")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Date", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Credential")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Credential", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Security-Token")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Security-Token", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Algorithm")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Algorithm", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-SignedHeaders", valid_602513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_DeleteApnsChannel_602503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602514, url, valid)

proc call*(call_602515: Call_DeleteApnsChannel_602503; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602516 = newJObject()
  add(path_602516, "application-id", newJString(applicationId))
  result = call_602515.call(path_602516, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_602503(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_602504, base: "/",
    url: url_DeleteApnsChannel_602505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_602531 = ref object of OpenApiRestCall_601373
proc url_UpdateApnsSandboxChannel_602533(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_602532(path: JsonNode; query: JsonNode;
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
  var valid_602534 = path.getOrDefault("application-id")
  valid_602534 = validateParameter(valid_602534, JString, required = true,
                                 default = nil)
  if valid_602534 != nil:
    section.add "application-id", valid_602534
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602535 = header.getOrDefault("X-Amz-Signature")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Signature", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Content-Sha256", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Date")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Date", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Credential")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Credential", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Security-Token")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Security-Token", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Algorithm")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Algorithm", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-SignedHeaders", valid_602541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602543: Call_UpdateApnsSandboxChannel_602531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_602543.validator(path, query, header, formData, body)
  let scheme = call_602543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602543.url(scheme.get, call_602543.host, call_602543.base,
                         call_602543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602543, url, valid)

proc call*(call_602544: Call_UpdateApnsSandboxChannel_602531;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602545 = newJObject()
  var body_602546 = newJObject()
  add(path_602545, "application-id", newJString(applicationId))
  if body != nil:
    body_602546 = body
  result = call_602544.call(path_602545, nil, nil, nil, body_602546)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_602531(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_602532, base: "/",
    url: url_UpdateApnsSandboxChannel_602533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_602517 = ref object of OpenApiRestCall_601373
proc url_GetApnsSandboxChannel_602519(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_602518(path: JsonNode; query: JsonNode;
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
  var valid_602520 = path.getOrDefault("application-id")
  valid_602520 = validateParameter(valid_602520, JString, required = true,
                                 default = nil)
  if valid_602520 != nil:
    section.add "application-id", valid_602520
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602521 = header.getOrDefault("X-Amz-Signature")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Signature", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Content-Sha256", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Date")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Date", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Credential")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Credential", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Security-Token")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Security-Token", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Algorithm")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Algorithm", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-SignedHeaders", valid_602527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602528: Call_GetApnsSandboxChannel_602517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_602528.validator(path, query, header, formData, body)
  let scheme = call_602528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602528.url(scheme.get, call_602528.host, call_602528.base,
                         call_602528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602528, url, valid)

proc call*(call_602529: Call_GetApnsSandboxChannel_602517; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602530 = newJObject()
  add(path_602530, "application-id", newJString(applicationId))
  result = call_602529.call(path_602530, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_602517(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_602518, base: "/",
    url: url_GetApnsSandboxChannel_602519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_602547 = ref object of OpenApiRestCall_601373
proc url_DeleteApnsSandboxChannel_602549(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_602548(path: JsonNode; query: JsonNode;
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
  var valid_602550 = path.getOrDefault("application-id")
  valid_602550 = validateParameter(valid_602550, JString, required = true,
                                 default = nil)
  if valid_602550 != nil:
    section.add "application-id", valid_602550
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602551 = header.getOrDefault("X-Amz-Signature")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Signature", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Content-Sha256", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Date")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Date", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Credential")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Credential", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Security-Token")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Security-Token", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Algorithm")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Algorithm", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-SignedHeaders", valid_602557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602558: Call_DeleteApnsSandboxChannel_602547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602558.validator(path, query, header, formData, body)
  let scheme = call_602558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602558.url(scheme.get, call_602558.host, call_602558.base,
                         call_602558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602558, url, valid)

proc call*(call_602559: Call_DeleteApnsSandboxChannel_602547; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602560 = newJObject()
  add(path_602560, "application-id", newJString(applicationId))
  result = call_602559.call(path_602560, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_602547(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_602548, base: "/",
    url: url_DeleteApnsSandboxChannel_602549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_602575 = ref object of OpenApiRestCall_601373
proc url_UpdateApnsVoipChannel_602577(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_602576(path: JsonNode; query: JsonNode;
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
  var valid_602578 = path.getOrDefault("application-id")
  valid_602578 = validateParameter(valid_602578, JString, required = true,
                                 default = nil)
  if valid_602578 != nil:
    section.add "application-id", valid_602578
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602579 = header.getOrDefault("X-Amz-Signature")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Signature", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Content-Sha256", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Date")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Date", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Credential")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Credential", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Security-Token")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Security-Token", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Algorithm")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Algorithm", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-SignedHeaders", valid_602585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602587: Call_UpdateApnsVoipChannel_602575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_602587.validator(path, query, header, formData, body)
  let scheme = call_602587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602587.url(scheme.get, call_602587.host, call_602587.base,
                         call_602587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602587, url, valid)

proc call*(call_602588: Call_UpdateApnsVoipChannel_602575; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602589 = newJObject()
  var body_602590 = newJObject()
  add(path_602589, "application-id", newJString(applicationId))
  if body != nil:
    body_602590 = body
  result = call_602588.call(path_602589, nil, nil, nil, body_602590)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_602575(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_602576, base: "/",
    url: url_UpdateApnsVoipChannel_602577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_602561 = ref object of OpenApiRestCall_601373
proc url_GetApnsVoipChannel_602563(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_602562(path: JsonNode; query: JsonNode;
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
  var valid_602564 = path.getOrDefault("application-id")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "application-id", valid_602564
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602565 = header.getOrDefault("X-Amz-Signature")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Signature", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Content-Sha256", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Date")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Date", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Credential")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Credential", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Security-Token")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Security-Token", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Algorithm")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Algorithm", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-SignedHeaders", valid_602571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602572: Call_GetApnsVoipChannel_602561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_602572.validator(path, query, header, formData, body)
  let scheme = call_602572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602572.url(scheme.get, call_602572.host, call_602572.base,
                         call_602572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602572, url, valid)

proc call*(call_602573: Call_GetApnsVoipChannel_602561; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602574 = newJObject()
  add(path_602574, "application-id", newJString(applicationId))
  result = call_602573.call(path_602574, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_602561(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_602562, base: "/",
    url: url_GetApnsVoipChannel_602563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_602591 = ref object of OpenApiRestCall_601373
proc url_DeleteApnsVoipChannel_602593(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_602592(path: JsonNode; query: JsonNode;
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
  var valid_602594 = path.getOrDefault("application-id")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = nil)
  if valid_602594 != nil:
    section.add "application-id", valid_602594
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602595 = header.getOrDefault("X-Amz-Signature")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Signature", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Content-Sha256", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Date")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Date", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Credential")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Credential", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Security-Token")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Security-Token", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Algorithm")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Algorithm", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-SignedHeaders", valid_602601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602602: Call_DeleteApnsVoipChannel_602591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602602.validator(path, query, header, formData, body)
  let scheme = call_602602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602602.url(scheme.get, call_602602.host, call_602602.base,
                         call_602602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602602, url, valid)

proc call*(call_602603: Call_DeleteApnsVoipChannel_602591; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602604 = newJObject()
  add(path_602604, "application-id", newJString(applicationId))
  result = call_602603.call(path_602604, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_602591(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_602592, base: "/",
    url: url_DeleteApnsVoipChannel_602593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_602619 = ref object of OpenApiRestCall_601373
proc url_UpdateApnsVoipSandboxChannel_602621(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_602620(path: JsonNode; query: JsonNode;
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
  var valid_602622 = path.getOrDefault("application-id")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = nil)
  if valid_602622 != nil:
    section.add "application-id", valid_602622
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602623 = header.getOrDefault("X-Amz-Signature")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Signature", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Content-Sha256", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Date")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Date", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Credential")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Credential", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Security-Token")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Security-Token", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Algorithm")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Algorithm", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-SignedHeaders", valid_602629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602631: Call_UpdateApnsVoipSandboxChannel_602619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_602631.validator(path, query, header, formData, body)
  let scheme = call_602631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602631.url(scheme.get, call_602631.host, call_602631.base,
                         call_602631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602631, url, valid)

proc call*(call_602632: Call_UpdateApnsVoipSandboxChannel_602619;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602633 = newJObject()
  var body_602634 = newJObject()
  add(path_602633, "application-id", newJString(applicationId))
  if body != nil:
    body_602634 = body
  result = call_602632.call(path_602633, nil, nil, nil, body_602634)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_602619(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_602620, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_602621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_602605 = ref object of OpenApiRestCall_601373
proc url_GetApnsVoipSandboxChannel_602607(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_602606(path: JsonNode; query: JsonNode;
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
  var valid_602608 = path.getOrDefault("application-id")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = nil)
  if valid_602608 != nil:
    section.add "application-id", valid_602608
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Content-Sha256", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Date")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Date", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Credential")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Credential", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Algorithm")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Algorithm", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602616: Call_GetApnsVoipSandboxChannel_602605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_602616.validator(path, query, header, formData, body)
  let scheme = call_602616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602616.url(scheme.get, call_602616.host, call_602616.base,
                         call_602616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602616, url, valid)

proc call*(call_602617: Call_GetApnsVoipSandboxChannel_602605;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602618 = newJObject()
  add(path_602618, "application-id", newJString(applicationId))
  result = call_602617.call(path_602618, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_602605(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_602606, base: "/",
    url: url_GetApnsVoipSandboxChannel_602607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_602635 = ref object of OpenApiRestCall_601373
proc url_DeleteApnsVoipSandboxChannel_602637(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_602636(path: JsonNode; query: JsonNode;
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
  var valid_602638 = path.getOrDefault("application-id")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = nil)
  if valid_602638 != nil:
    section.add "application-id", valid_602638
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Content-Sha256", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Credential")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Credential", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Security-Token")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Security-Token", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-SignedHeaders", valid_602645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602646: Call_DeleteApnsVoipSandboxChannel_602635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602646.validator(path, query, header, formData, body)
  let scheme = call_602646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602646.url(scheme.get, call_602646.host, call_602646.base,
                         call_602646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602646, url, valid)

proc call*(call_602647: Call_DeleteApnsVoipSandboxChannel_602635;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602648 = newJObject()
  add(path_602648, "application-id", newJString(applicationId))
  result = call_602647.call(path_602648, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_602635(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_602636, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_602637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_602649 = ref object of OpenApiRestCall_601373
proc url_GetApp_602651(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_602650(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602652 = path.getOrDefault("application-id")
  valid_602652 = validateParameter(valid_602652, JString, required = true,
                                 default = nil)
  if valid_602652 != nil:
    section.add "application-id", valid_602652
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602653 = header.getOrDefault("X-Amz-Signature")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Signature", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Content-Sha256", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Date")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Date", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Credential")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Credential", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Security-Token")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Security-Token", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Algorithm")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Algorithm", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-SignedHeaders", valid_602659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602660: Call_GetApp_602649; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_602660.validator(path, query, header, formData, body)
  let scheme = call_602660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602660.url(scheme.get, call_602660.host, call_602660.base,
                         call_602660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602660, url, valid)

proc call*(call_602661: Call_GetApp_602649; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602662 = newJObject()
  add(path_602662, "application-id", newJString(applicationId))
  result = call_602661.call(path_602662, nil, nil, nil, nil)

var getApp* = Call_GetApp_602649(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_602650, base: "/",
                              url: url_GetApp_602651,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_602663 = ref object of OpenApiRestCall_601373
proc url_DeleteApp_602665(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_602664(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602666 = path.getOrDefault("application-id")
  valid_602666 = validateParameter(valid_602666, JString, required = true,
                                 default = nil)
  if valid_602666 != nil:
    section.add "application-id", valid_602666
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602667 = header.getOrDefault("X-Amz-Signature")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Signature", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Content-Sha256", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Date")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Date", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-Credential")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-Credential", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Security-Token")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Security-Token", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Algorithm")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Algorithm", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-SignedHeaders", valid_602673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602674: Call_DeleteApp_602663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_602674.validator(path, query, header, formData, body)
  let scheme = call_602674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602674.url(scheme.get, call_602674.host, call_602674.base,
                         call_602674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602674, url, valid)

proc call*(call_602675: Call_DeleteApp_602663; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602676 = newJObject()
  add(path_602676, "application-id", newJString(applicationId))
  result = call_602675.call(path_602676, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_602663(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_602664,
                                    base: "/", url: url_DeleteApp_602665,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_602691 = ref object of OpenApiRestCall_601373
proc url_UpdateBaiduChannel_602693(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_602692(path: JsonNode; query: JsonNode;
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
  var valid_602694 = path.getOrDefault("application-id")
  valid_602694 = validateParameter(valid_602694, JString, required = true,
                                 default = nil)
  if valid_602694 != nil:
    section.add "application-id", valid_602694
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602695 = header.getOrDefault("X-Amz-Signature")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Signature", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Content-Sha256", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Date")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Date", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Credential")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Credential", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Security-Token")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Security-Token", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Algorithm")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Algorithm", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-SignedHeaders", valid_602701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602703: Call_UpdateBaiduChannel_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_602703.validator(path, query, header, formData, body)
  let scheme = call_602703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602703.url(scheme.get, call_602703.host, call_602703.base,
                         call_602703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602703, url, valid)

proc call*(call_602704: Call_UpdateBaiduChannel_602691; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602705 = newJObject()
  var body_602706 = newJObject()
  add(path_602705, "application-id", newJString(applicationId))
  if body != nil:
    body_602706 = body
  result = call_602704.call(path_602705, nil, nil, nil, body_602706)

var updateBaiduChannel* = Call_UpdateBaiduChannel_602691(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_602692, base: "/",
    url: url_UpdateBaiduChannel_602693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_602677 = ref object of OpenApiRestCall_601373
proc url_GetBaiduChannel_602679(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_602678(path: JsonNode; query: JsonNode;
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
  var valid_602680 = path.getOrDefault("application-id")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = nil)
  if valid_602680 != nil:
    section.add "application-id", valid_602680
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Content-Sha256", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Date")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Date", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Credential")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Credential", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602688: Call_GetBaiduChannel_602677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_602688.validator(path, query, header, formData, body)
  let scheme = call_602688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602688.url(scheme.get, call_602688.host, call_602688.base,
                         call_602688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602688, url, valid)

proc call*(call_602689: Call_GetBaiduChannel_602677; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602690 = newJObject()
  add(path_602690, "application-id", newJString(applicationId))
  result = call_602689.call(path_602690, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_602677(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_602678, base: "/", url: url_GetBaiduChannel_602679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_602707 = ref object of OpenApiRestCall_601373
proc url_DeleteBaiduChannel_602709(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_602708(path: JsonNode; query: JsonNode;
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
  var valid_602710 = path.getOrDefault("application-id")
  valid_602710 = validateParameter(valid_602710, JString, required = true,
                                 default = nil)
  if valid_602710 != nil:
    section.add "application-id", valid_602710
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602711 = header.getOrDefault("X-Amz-Signature")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Signature", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Content-Sha256", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Date")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Date", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Credential")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Credential", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Security-Token")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Security-Token", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Algorithm")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Algorithm", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-SignedHeaders", valid_602717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602718: Call_DeleteBaiduChannel_602707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602718.validator(path, query, header, formData, body)
  let scheme = call_602718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602718.url(scheme.get, call_602718.host, call_602718.base,
                         call_602718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602718, url, valid)

proc call*(call_602719: Call_DeleteBaiduChannel_602707; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602720 = newJObject()
  add(path_602720, "application-id", newJString(applicationId))
  result = call_602719.call(path_602720, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_602707(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_602708, base: "/",
    url: url_DeleteBaiduChannel_602709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_602736 = ref object of OpenApiRestCall_601373
proc url_UpdateCampaign_602738(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_602737(path: JsonNode; query: JsonNode;
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
  var valid_602739 = path.getOrDefault("application-id")
  valid_602739 = validateParameter(valid_602739, JString, required = true,
                                 default = nil)
  if valid_602739 != nil:
    section.add "application-id", valid_602739
  var valid_602740 = path.getOrDefault("campaign-id")
  valid_602740 = validateParameter(valid_602740, JString, required = true,
                                 default = nil)
  if valid_602740 != nil:
    section.add "campaign-id", valid_602740
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602741 = header.getOrDefault("X-Amz-Signature")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Signature", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Content-Sha256", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Date")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Date", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Credential")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Credential", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Security-Token")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Security-Token", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Algorithm")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Algorithm", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-SignedHeaders", valid_602747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602749: Call_UpdateCampaign_602736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a campaign.
  ## 
  let valid = call_602749.validator(path, query, header, formData, body)
  let scheme = call_602749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602749.url(scheme.get, call_602749.host, call_602749.base,
                         call_602749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602749, url, valid)

proc call*(call_602750: Call_UpdateCampaign_602736; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the configuration and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_602751 = newJObject()
  var body_602752 = newJObject()
  add(path_602751, "application-id", newJString(applicationId))
  if body != nil:
    body_602752 = body
  add(path_602751, "campaign-id", newJString(campaignId))
  result = call_602750.call(path_602751, nil, nil, nil, body_602752)

var updateCampaign* = Call_UpdateCampaign_602736(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_602737, base: "/", url: url_UpdateCampaign_602738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_602721 = ref object of OpenApiRestCall_601373
proc url_GetCampaign_602723(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_602722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602724 = path.getOrDefault("application-id")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = nil)
  if valid_602724 != nil:
    section.add "application-id", valid_602724
  var valid_602725 = path.getOrDefault("campaign-id")
  valid_602725 = validateParameter(valid_602725, JString, required = true,
                                 default = nil)
  if valid_602725 != nil:
    section.add "campaign-id", valid_602725
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602726 = header.getOrDefault("X-Amz-Signature")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Signature", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Content-Sha256", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Date")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Date", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Credential")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Credential", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Security-Token")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Security-Token", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Algorithm")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Algorithm", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-SignedHeaders", valid_602732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602733: Call_GetCampaign_602721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_602733.validator(path, query, header, formData, body)
  let scheme = call_602733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602733.url(scheme.get, call_602733.host, call_602733.base,
                         call_602733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602733, url, valid)

proc call*(call_602734: Call_GetCampaign_602721; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_602735 = newJObject()
  add(path_602735, "application-id", newJString(applicationId))
  add(path_602735, "campaign-id", newJString(campaignId))
  result = call_602734.call(path_602735, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_602721(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_602722,
                                        base: "/", url: url_GetCampaign_602723,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_602753 = ref object of OpenApiRestCall_601373
proc url_DeleteCampaign_602755(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_602754(path: JsonNode; query: JsonNode;
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
  var valid_602756 = path.getOrDefault("application-id")
  valid_602756 = validateParameter(valid_602756, JString, required = true,
                                 default = nil)
  if valid_602756 != nil:
    section.add "application-id", valid_602756
  var valid_602757 = path.getOrDefault("campaign-id")
  valid_602757 = validateParameter(valid_602757, JString, required = true,
                                 default = nil)
  if valid_602757 != nil:
    section.add "campaign-id", valid_602757
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602758 = header.getOrDefault("X-Amz-Signature")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Signature", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Content-Sha256", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Date")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Date", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Credential")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Credential", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Security-Token")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Security-Token", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Algorithm")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Algorithm", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-SignedHeaders", valid_602764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602765: Call_DeleteCampaign_602753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_602765.validator(path, query, header, formData, body)
  let scheme = call_602765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602765.url(scheme.get, call_602765.host, call_602765.base,
                         call_602765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602765, url, valid)

proc call*(call_602766: Call_DeleteCampaign_602753; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_602767 = newJObject()
  add(path_602767, "application-id", newJString(applicationId))
  add(path_602767, "campaign-id", newJString(campaignId))
  result = call_602766.call(path_602767, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_602753(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_602754, base: "/", url: url_DeleteCampaign_602755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_602782 = ref object of OpenApiRestCall_601373
proc url_UpdateEmailChannel_602784(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_602783(path: JsonNode; query: JsonNode;
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
  var valid_602785 = path.getOrDefault("application-id")
  valid_602785 = validateParameter(valid_602785, JString, required = true,
                                 default = nil)
  if valid_602785 != nil:
    section.add "application-id", valid_602785
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602786 = header.getOrDefault("X-Amz-Signature")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Signature", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Content-Sha256", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Date")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Date", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Credential")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Credential", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Security-Token")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Security-Token", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Algorithm")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Algorithm", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-SignedHeaders", valid_602792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602794: Call_UpdateEmailChannel_602782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_602794.validator(path, query, header, formData, body)
  let scheme = call_602794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602794.url(scheme.get, call_602794.host, call_602794.base,
                         call_602794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602794, url, valid)

proc call*(call_602795: Call_UpdateEmailChannel_602782; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602796 = newJObject()
  var body_602797 = newJObject()
  add(path_602796, "application-id", newJString(applicationId))
  if body != nil:
    body_602797 = body
  result = call_602795.call(path_602796, nil, nil, nil, body_602797)

var updateEmailChannel* = Call_UpdateEmailChannel_602782(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_602783, base: "/",
    url: url_UpdateEmailChannel_602784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_602768 = ref object of OpenApiRestCall_601373
proc url_GetEmailChannel_602770(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_602769(path: JsonNode; query: JsonNode;
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
  var valid_602771 = path.getOrDefault("application-id")
  valid_602771 = validateParameter(valid_602771, JString, required = true,
                                 default = nil)
  if valid_602771 != nil:
    section.add "application-id", valid_602771
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602772 = header.getOrDefault("X-Amz-Signature")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Signature", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Content-Sha256", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Date")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Date", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Credential")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Credential", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Security-Token")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Security-Token", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Algorithm")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Algorithm", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-SignedHeaders", valid_602778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602779: Call_GetEmailChannel_602768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_602779.validator(path, query, header, formData, body)
  let scheme = call_602779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602779.url(scheme.get, call_602779.host, call_602779.base,
                         call_602779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602779, url, valid)

proc call*(call_602780: Call_GetEmailChannel_602768; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602781 = newJObject()
  add(path_602781, "application-id", newJString(applicationId))
  result = call_602780.call(path_602781, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_602768(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_602769, base: "/", url: url_GetEmailChannel_602770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_602798 = ref object of OpenApiRestCall_601373
proc url_DeleteEmailChannel_602800(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_602799(path: JsonNode; query: JsonNode;
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
  var valid_602801 = path.getOrDefault("application-id")
  valid_602801 = validateParameter(valid_602801, JString, required = true,
                                 default = nil)
  if valid_602801 != nil:
    section.add "application-id", valid_602801
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602802 = header.getOrDefault("X-Amz-Signature")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Signature", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Content-Sha256", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Date")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Date", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Credential")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Credential", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Security-Token")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Security-Token", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Algorithm")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Algorithm", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-SignedHeaders", valid_602808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602809: Call_DeleteEmailChannel_602798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602809.validator(path, query, header, formData, body)
  let scheme = call_602809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602809.url(scheme.get, call_602809.host, call_602809.base,
                         call_602809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602809, url, valid)

proc call*(call_602810: Call_DeleteEmailChannel_602798; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602811 = newJObject()
  add(path_602811, "application-id", newJString(applicationId))
  result = call_602810.call(path_602811, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_602798(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_602799, base: "/",
    url: url_DeleteEmailChannel_602800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_602827 = ref object of OpenApiRestCall_601373
proc url_UpdateEndpoint_602829(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_602828(path: JsonNode; query: JsonNode;
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
  var valid_602830 = path.getOrDefault("application-id")
  valid_602830 = validateParameter(valid_602830, JString, required = true,
                                 default = nil)
  if valid_602830 != nil:
    section.add "application-id", valid_602830
  var valid_602831 = path.getOrDefault("endpoint-id")
  valid_602831 = validateParameter(valid_602831, JString, required = true,
                                 default = nil)
  if valid_602831 != nil:
    section.add "endpoint-id", valid_602831
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602832 = header.getOrDefault("X-Amz-Signature")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Signature", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Content-Sha256", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Date")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Date", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Credential")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Credential", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Security-Token")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Security-Token", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Algorithm")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Algorithm", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-SignedHeaders", valid_602838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602840: Call_UpdateEndpoint_602827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_602840.validator(path, query, header, formData, body)
  let scheme = call_602840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602840.url(scheme.get, call_602840.host, call_602840.base,
                         call_602840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602840, url, valid)

proc call*(call_602841: Call_UpdateEndpoint_602827; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_602842 = newJObject()
  var body_602843 = newJObject()
  add(path_602842, "application-id", newJString(applicationId))
  if body != nil:
    body_602843 = body
  add(path_602842, "endpoint-id", newJString(endpointId))
  result = call_602841.call(path_602842, nil, nil, nil, body_602843)

var updateEndpoint* = Call_UpdateEndpoint_602827(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_602828, base: "/", url: url_UpdateEndpoint_602829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_602812 = ref object of OpenApiRestCall_601373
proc url_GetEndpoint_602814(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_602813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602815 = path.getOrDefault("application-id")
  valid_602815 = validateParameter(valid_602815, JString, required = true,
                                 default = nil)
  if valid_602815 != nil:
    section.add "application-id", valid_602815
  var valid_602816 = path.getOrDefault("endpoint-id")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = nil)
  if valid_602816 != nil:
    section.add "endpoint-id", valid_602816
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602817 = header.getOrDefault("X-Amz-Signature")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Signature", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Content-Sha256", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Date")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Date", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Credential")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Credential", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Security-Token")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Security-Token", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Algorithm")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Algorithm", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-SignedHeaders", valid_602823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602824: Call_GetEndpoint_602812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_602824.validator(path, query, header, formData, body)
  let scheme = call_602824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602824.url(scheme.get, call_602824.host, call_602824.base,
                         call_602824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602824, url, valid)

proc call*(call_602825: Call_GetEndpoint_602812; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_602826 = newJObject()
  add(path_602826, "application-id", newJString(applicationId))
  add(path_602826, "endpoint-id", newJString(endpointId))
  result = call_602825.call(path_602826, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_602812(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_602813,
                                        base: "/", url: url_GetEndpoint_602814,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_602844 = ref object of OpenApiRestCall_601373
proc url_DeleteEndpoint_602846(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_602845(path: JsonNode; query: JsonNode;
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
  var valid_602847 = path.getOrDefault("application-id")
  valid_602847 = validateParameter(valid_602847, JString, required = true,
                                 default = nil)
  if valid_602847 != nil:
    section.add "application-id", valid_602847
  var valid_602848 = path.getOrDefault("endpoint-id")
  valid_602848 = validateParameter(valid_602848, JString, required = true,
                                 default = nil)
  if valid_602848 != nil:
    section.add "endpoint-id", valid_602848
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602849 = header.getOrDefault("X-Amz-Signature")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Signature", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Content-Sha256", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Date")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Date", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Credential")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Credential", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-Security-Token")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-Security-Token", valid_602853
  var valid_602854 = header.getOrDefault("X-Amz-Algorithm")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "X-Amz-Algorithm", valid_602854
  var valid_602855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-SignedHeaders", valid_602855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602856: Call_DeleteEndpoint_602844; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_602856.validator(path, query, header, formData, body)
  let scheme = call_602856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602856.url(scheme.get, call_602856.host, call_602856.base,
                         call_602856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602856, url, valid)

proc call*(call_602857: Call_DeleteEndpoint_602844; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_602858 = newJObject()
  add(path_602858, "application-id", newJString(applicationId))
  add(path_602858, "endpoint-id", newJString(endpointId))
  result = call_602857.call(path_602858, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_602844(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_602845, base: "/", url: url_DeleteEndpoint_602846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_602873 = ref object of OpenApiRestCall_601373
proc url_PutEventStream_602875(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_602874(path: JsonNode; query: JsonNode;
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
  var valid_602876 = path.getOrDefault("application-id")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = nil)
  if valid_602876 != nil:
    section.add "application-id", valid_602876
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602877 = header.getOrDefault("X-Amz-Signature")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Signature", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Content-Sha256", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Date")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Date", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Credential")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Credential", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Security-Token")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Security-Token", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Algorithm")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Algorithm", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-SignedHeaders", valid_602883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602885: Call_PutEventStream_602873; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_602885.validator(path, query, header, formData, body)
  let scheme = call_602885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602885.url(scheme.get, call_602885.host, call_602885.base,
                         call_602885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602885, url, valid)

proc call*(call_602886: Call_PutEventStream_602873; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602887 = newJObject()
  var body_602888 = newJObject()
  add(path_602887, "application-id", newJString(applicationId))
  if body != nil:
    body_602888 = body
  result = call_602886.call(path_602887, nil, nil, nil, body_602888)

var putEventStream* = Call_PutEventStream_602873(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_602874, base: "/", url: url_PutEventStream_602875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_602859 = ref object of OpenApiRestCall_601373
proc url_GetEventStream_602861(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_602860(path: JsonNode; query: JsonNode;
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
  var valid_602862 = path.getOrDefault("application-id")
  valid_602862 = validateParameter(valid_602862, JString, required = true,
                                 default = nil)
  if valid_602862 != nil:
    section.add "application-id", valid_602862
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602863 = header.getOrDefault("X-Amz-Signature")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Signature", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Content-Sha256", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Date")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Date", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Credential")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Credential", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Security-Token")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Security-Token", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-Algorithm")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Algorithm", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-SignedHeaders", valid_602869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602870: Call_GetEventStream_602859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_602870.validator(path, query, header, formData, body)
  let scheme = call_602870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602870.url(scheme.get, call_602870.host, call_602870.base,
                         call_602870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602870, url, valid)

proc call*(call_602871: Call_GetEventStream_602859; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602872 = newJObject()
  add(path_602872, "application-id", newJString(applicationId))
  result = call_602871.call(path_602872, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_602859(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_602860, base: "/", url: url_GetEventStream_602861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_602889 = ref object of OpenApiRestCall_601373
proc url_DeleteEventStream_602891(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_602890(path: JsonNode; query: JsonNode;
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
  var valid_602892 = path.getOrDefault("application-id")
  valid_602892 = validateParameter(valid_602892, JString, required = true,
                                 default = nil)
  if valid_602892 != nil:
    section.add "application-id", valid_602892
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602893 = header.getOrDefault("X-Amz-Signature")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Signature", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Content-Sha256", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Date")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Date", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Credential")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Credential", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Security-Token")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Security-Token", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Algorithm")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Algorithm", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-SignedHeaders", valid_602899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602900: Call_DeleteEventStream_602889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_602900.validator(path, query, header, formData, body)
  let scheme = call_602900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602900.url(scheme.get, call_602900.host, call_602900.base,
                         call_602900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602900, url, valid)

proc call*(call_602901: Call_DeleteEventStream_602889; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602902 = newJObject()
  add(path_602902, "application-id", newJString(applicationId))
  result = call_602901.call(path_602902, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_602889(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_602890, base: "/",
    url: url_DeleteEventStream_602891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_602917 = ref object of OpenApiRestCall_601373
proc url_UpdateGcmChannel_602919(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_602918(path: JsonNode; query: JsonNode;
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
  var valid_602920 = path.getOrDefault("application-id")
  valid_602920 = validateParameter(valid_602920, JString, required = true,
                                 default = nil)
  if valid_602920 != nil:
    section.add "application-id", valid_602920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602921 = header.getOrDefault("X-Amz-Signature")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Signature", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Content-Sha256", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Date")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Date", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Credential")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Credential", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Security-Token")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Security-Token", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Algorithm")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Algorithm", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602929: Call_UpdateGcmChannel_602917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_602929.validator(path, query, header, formData, body)
  let scheme = call_602929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602929.url(scheme.get, call_602929.host, call_602929.base,
                         call_602929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602929, url, valid)

proc call*(call_602930: Call_UpdateGcmChannel_602917; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602931 = newJObject()
  var body_602932 = newJObject()
  add(path_602931, "application-id", newJString(applicationId))
  if body != nil:
    body_602932 = body
  result = call_602930.call(path_602931, nil, nil, nil, body_602932)

var updateGcmChannel* = Call_UpdateGcmChannel_602917(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_602918, base: "/",
    url: url_UpdateGcmChannel_602919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_602903 = ref object of OpenApiRestCall_601373
proc url_GetGcmChannel_602905(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_602904(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602906 = path.getOrDefault("application-id")
  valid_602906 = validateParameter(valid_602906, JString, required = true,
                                 default = nil)
  if valid_602906 != nil:
    section.add "application-id", valid_602906
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Content-Sha256", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Date")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Date", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Credential")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Credential", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Security-Token")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Security-Token", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Algorithm")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Algorithm", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-SignedHeaders", valid_602913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_GetGcmChannel_602903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602914, url, valid)

proc call*(call_602915: Call_GetGcmChannel_602903; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602916 = newJObject()
  add(path_602916, "application-id", newJString(applicationId))
  result = call_602915.call(path_602916, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_602903(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_602904, base: "/", url: url_GetGcmChannel_602905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_602933 = ref object of OpenApiRestCall_601373
proc url_DeleteGcmChannel_602935(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_602934(path: JsonNode; query: JsonNode;
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
  var valid_602936 = path.getOrDefault("application-id")
  valid_602936 = validateParameter(valid_602936, JString, required = true,
                                 default = nil)
  if valid_602936 != nil:
    section.add "application-id", valid_602936
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Content-Sha256", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Date")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Date", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Security-Token")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Security-Token", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Algorithm")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Algorithm", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-SignedHeaders", valid_602943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602944: Call_DeleteGcmChannel_602933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_602944.validator(path, query, header, formData, body)
  let scheme = call_602944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602944.url(scheme.get, call_602944.host, call_602944.base,
                         call_602944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602944, url, valid)

proc call*(call_602945: Call_DeleteGcmChannel_602933; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602946 = newJObject()
  add(path_602946, "application-id", newJString(applicationId))
  result = call_602945.call(path_602946, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_602933(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_602934, base: "/",
    url: url_DeleteGcmChannel_602935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourney_602962 = ref object of OpenApiRestCall_601373
proc url_UpdateJourney_602964(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourney_602963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602965 = path.getOrDefault("application-id")
  valid_602965 = validateParameter(valid_602965, JString, required = true,
                                 default = nil)
  if valid_602965 != nil:
    section.add "application-id", valid_602965
  var valid_602966 = path.getOrDefault("journey-id")
  valid_602966 = validateParameter(valid_602966, JString, required = true,
                                 default = nil)
  if valid_602966 != nil:
    section.add "journey-id", valid_602966
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602967 = header.getOrDefault("X-Amz-Signature")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Signature", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Content-Sha256", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Date")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Date", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Credential")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Credential", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Security-Token")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Security-Token", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Algorithm")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Algorithm", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-SignedHeaders", valid_602973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602975: Call_UpdateJourney_602962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration and other settings for a journey.
  ## 
  let valid = call_602975.validator(path, query, header, formData, body)
  let scheme = call_602975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602975.url(scheme.get, call_602975.host, call_602975.base,
                         call_602975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602975, url, valid)

proc call*(call_602976: Call_UpdateJourney_602962; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourney
  ## Updates the configuration and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_602977 = newJObject()
  var body_602978 = newJObject()
  add(path_602977, "application-id", newJString(applicationId))
  if body != nil:
    body_602978 = body
  add(path_602977, "journey-id", newJString(journeyId))
  result = call_602976.call(path_602977, nil, nil, nil, body_602978)

var updateJourney* = Call_UpdateJourney_602962(name: "updateJourney",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_UpdateJourney_602963, base: "/", url: url_UpdateJourney_602964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourney_602947 = ref object of OpenApiRestCall_601373
proc url_GetJourney_602949(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJourney_602948(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602950 = path.getOrDefault("application-id")
  valid_602950 = validateParameter(valid_602950, JString, required = true,
                                 default = nil)
  if valid_602950 != nil:
    section.add "application-id", valid_602950
  var valid_602951 = path.getOrDefault("journey-id")
  valid_602951 = validateParameter(valid_602951, JString, required = true,
                                 default = nil)
  if valid_602951 != nil:
    section.add "journey-id", valid_602951
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602952 = header.getOrDefault("X-Amz-Signature")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Signature", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Content-Sha256", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Date")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Date", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Credential")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Credential", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Security-Token")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Security-Token", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Algorithm")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Algorithm", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-SignedHeaders", valid_602958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602959: Call_GetJourney_602947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ## 
  let valid = call_602959.validator(path, query, header, formData, body)
  let scheme = call_602959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602959.url(scheme.get, call_602959.host, call_602959.base,
                         call_602959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602959, url, valid)

proc call*(call_602960: Call_GetJourney_602947; applicationId: string;
          journeyId: string): Recallable =
  ## getJourney
  ## Retrieves information about the status, configuration, and other settings for a journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_602961 = newJObject()
  add(path_602961, "application-id", newJString(applicationId))
  add(path_602961, "journey-id", newJString(journeyId))
  result = call_602960.call(path_602961, nil, nil, nil, nil)

var getJourney* = Call_GetJourney_602947(name: "getJourney",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}",
                                      validator: validate_GetJourney_602948,
                                      base: "/", url: url_GetJourney_602949,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJourney_602979 = ref object of OpenApiRestCall_601373
proc url_DeleteJourney_602981(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJourney_602980(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602982 = path.getOrDefault("application-id")
  valid_602982 = validateParameter(valid_602982, JString, required = true,
                                 default = nil)
  if valid_602982 != nil:
    section.add "application-id", valid_602982
  var valid_602983 = path.getOrDefault("journey-id")
  valid_602983 = validateParameter(valid_602983, JString, required = true,
                                 default = nil)
  if valid_602983 != nil:
    section.add "journey-id", valid_602983
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602984 = header.getOrDefault("X-Amz-Signature")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Signature", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Content-Sha256", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Date")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Date", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Credential")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Credential", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-Security-Token")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Security-Token", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-Algorithm")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-Algorithm", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-SignedHeaders", valid_602990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602991: Call_DeleteJourney_602979; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a journey from an application.
  ## 
  let valid = call_602991.validator(path, query, header, formData, body)
  let scheme = call_602991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602991.url(scheme.get, call_602991.host, call_602991.base,
                         call_602991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602991, url, valid)

proc call*(call_602992: Call_DeleteJourney_602979; applicationId: string;
          journeyId: string): Recallable =
  ## deleteJourney
  ## Deletes a journey from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_602993 = newJObject()
  add(path_602993, "application-id", newJString(applicationId))
  add(path_602993, "journey-id", newJString(journeyId))
  result = call_602992.call(path_602993, nil, nil, nil, nil)

var deleteJourney* = Call_DeleteJourney_602979(name: "deleteJourney",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}",
    validator: validate_DeleteJourney_602980, base: "/", url: url_DeleteJourney_602981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_603009 = ref object of OpenApiRestCall_601373
proc url_UpdateSegment_603011(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_603010(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603012 = path.getOrDefault("application-id")
  valid_603012 = validateParameter(valid_603012, JString, required = true,
                                 default = nil)
  if valid_603012 != nil:
    section.add "application-id", valid_603012
  var valid_603013 = path.getOrDefault("segment-id")
  valid_603013 = validateParameter(valid_603013, JString, required = true,
                                 default = nil)
  if valid_603013 != nil:
    section.add "segment-id", valid_603013
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603014 = header.getOrDefault("X-Amz-Signature")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Signature", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Content-Sha256", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-Date")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-Date", valid_603016
  var valid_603017 = header.getOrDefault("X-Amz-Credential")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Credential", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Security-Token")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Security-Token", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Algorithm")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Algorithm", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-SignedHeaders", valid_603020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603022: Call_UpdateSegment_603009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_603022.validator(path, query, header, formData, body)
  let scheme = call_603022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603022.url(scheme.get, call_603022.host, call_603022.base,
                         call_603022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603022, url, valid)

proc call*(call_603023: Call_UpdateSegment_603009; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_603024 = newJObject()
  var body_603025 = newJObject()
  add(path_603024, "application-id", newJString(applicationId))
  add(path_603024, "segment-id", newJString(segmentId))
  if body != nil:
    body_603025 = body
  result = call_603023.call(path_603024, nil, nil, nil, body_603025)

var updateSegment* = Call_UpdateSegment_603009(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_603010, base: "/", url: url_UpdateSegment_603011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_602994 = ref object of OpenApiRestCall_601373
proc url_GetSegment_602996(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_602995(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602997 = path.getOrDefault("application-id")
  valid_602997 = validateParameter(valid_602997, JString, required = true,
                                 default = nil)
  if valid_602997 != nil:
    section.add "application-id", valid_602997
  var valid_602998 = path.getOrDefault("segment-id")
  valid_602998 = validateParameter(valid_602998, JString, required = true,
                                 default = nil)
  if valid_602998 != nil:
    section.add "segment-id", valid_602998
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602999 = header.getOrDefault("X-Amz-Signature")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Signature", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Content-Sha256", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Date")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Date", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Credential")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Credential", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-Security-Token")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-Security-Token", valid_603003
  var valid_603004 = header.getOrDefault("X-Amz-Algorithm")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Algorithm", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-SignedHeaders", valid_603005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603006: Call_GetSegment_602994; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_603006.validator(path, query, header, formData, body)
  let scheme = call_603006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603006.url(scheme.get, call_603006.host, call_603006.base,
                         call_603006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603006, url, valid)

proc call*(call_603007: Call_GetSegment_602994; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_603008 = newJObject()
  add(path_603008, "application-id", newJString(applicationId))
  add(path_603008, "segment-id", newJString(segmentId))
  result = call_603007.call(path_603008, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_602994(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_602995,
                                      base: "/", url: url_GetSegment_602996,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_603026 = ref object of OpenApiRestCall_601373
proc url_DeleteSegment_603028(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_603027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603029 = path.getOrDefault("application-id")
  valid_603029 = validateParameter(valid_603029, JString, required = true,
                                 default = nil)
  if valid_603029 != nil:
    section.add "application-id", valid_603029
  var valid_603030 = path.getOrDefault("segment-id")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = nil)
  if valid_603030 != nil:
    section.add "segment-id", valid_603030
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603031 = header.getOrDefault("X-Amz-Signature")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Signature", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Content-Sha256", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Date")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Date", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Credential")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Credential", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Security-Token")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Security-Token", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Algorithm")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Algorithm", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-SignedHeaders", valid_603037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603038: Call_DeleteSegment_603026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_603038.validator(path, query, header, formData, body)
  let scheme = call_603038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603038.url(scheme.get, call_603038.host, call_603038.base,
                         call_603038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603038, url, valid)

proc call*(call_603039: Call_DeleteSegment_603026; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_603040 = newJObject()
  add(path_603040, "application-id", newJString(applicationId))
  add(path_603040, "segment-id", newJString(segmentId))
  result = call_603039.call(path_603040, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_603026(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_603027, base: "/", url: url_DeleteSegment_603028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_603055 = ref object of OpenApiRestCall_601373
proc url_UpdateSmsChannel_603057(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_603056(path: JsonNode; query: JsonNode;
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
  var valid_603058 = path.getOrDefault("application-id")
  valid_603058 = validateParameter(valid_603058, JString, required = true,
                                 default = nil)
  if valid_603058 != nil:
    section.add "application-id", valid_603058
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603059 = header.getOrDefault("X-Amz-Signature")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Signature", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Date")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Date", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Credential")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Credential", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Security-Token")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Security-Token", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Algorithm")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Algorithm", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-SignedHeaders", valid_603065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603067: Call_UpdateSmsChannel_603055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_603067.validator(path, query, header, formData, body)
  let scheme = call_603067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603067.url(scheme.get, call_603067.host, call_603067.base,
                         call_603067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603067, url, valid)

proc call*(call_603068: Call_UpdateSmsChannel_603055; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603069 = newJObject()
  var body_603070 = newJObject()
  add(path_603069, "application-id", newJString(applicationId))
  if body != nil:
    body_603070 = body
  result = call_603068.call(path_603069, nil, nil, nil, body_603070)

var updateSmsChannel* = Call_UpdateSmsChannel_603055(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_603056, base: "/",
    url: url_UpdateSmsChannel_603057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_603041 = ref object of OpenApiRestCall_601373
proc url_GetSmsChannel_603043(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_603042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603044 = path.getOrDefault("application-id")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = nil)
  if valid_603044 != nil:
    section.add "application-id", valid_603044
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603045 = header.getOrDefault("X-Amz-Signature")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Signature", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Content-Sha256", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Date")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Date", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Credential")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Credential", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Security-Token")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Security-Token", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Algorithm")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Algorithm", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-SignedHeaders", valid_603051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603052: Call_GetSmsChannel_603041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_603052.validator(path, query, header, formData, body)
  let scheme = call_603052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603052.url(scheme.get, call_603052.host, call_603052.base,
                         call_603052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603052, url, valid)

proc call*(call_603053: Call_GetSmsChannel_603041; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603054 = newJObject()
  add(path_603054, "application-id", newJString(applicationId))
  result = call_603053.call(path_603054, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_603041(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_603042, base: "/", url: url_GetSmsChannel_603043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_603071 = ref object of OpenApiRestCall_601373
proc url_DeleteSmsChannel_603073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_603072(path: JsonNode; query: JsonNode;
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
  var valid_603074 = path.getOrDefault("application-id")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "application-id", valid_603074
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Signature")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Signature", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Content-Sha256", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Date")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Date", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Credential")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Credential", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603082: Call_DeleteSmsChannel_603071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603082.validator(path, query, header, formData, body)
  let scheme = call_603082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603082.url(scheme.get, call_603082.host, call_603082.base,
                         call_603082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603082, url, valid)

proc call*(call_603083: Call_DeleteSmsChannel_603071; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603084 = newJObject()
  add(path_603084, "application-id", newJString(applicationId))
  result = call_603083.call(path_603084, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_603071(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_603072, base: "/",
    url: url_DeleteSmsChannel_603073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_603085 = ref object of OpenApiRestCall_601373
proc url_GetUserEndpoints_603087(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_603086(path: JsonNode; query: JsonNode;
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
  var valid_603088 = path.getOrDefault("application-id")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = nil)
  if valid_603088 != nil:
    section.add "application-id", valid_603088
  var valid_603089 = path.getOrDefault("user-id")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = nil)
  if valid_603089 != nil:
    section.add "user-id", valid_603089
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Signature")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Signature", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Content-Sha256", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Date")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Date", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Credential")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Credential", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Security-Token")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Security-Token", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Algorithm")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Algorithm", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_GetUserEndpoints_603085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603097, url, valid)

proc call*(call_603098: Call_GetUserEndpoints_603085; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_603099 = newJObject()
  add(path_603099, "application-id", newJString(applicationId))
  add(path_603099, "user-id", newJString(userId))
  result = call_603098.call(path_603099, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_603085(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_603086, base: "/",
    url: url_GetUserEndpoints_603087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_603100 = ref object of OpenApiRestCall_601373
proc url_DeleteUserEndpoints_603102(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_603101(path: JsonNode; query: JsonNode;
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
  var valid_603103 = path.getOrDefault("application-id")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = nil)
  if valid_603103 != nil:
    section.add "application-id", valid_603103
  var valid_603104 = path.getOrDefault("user-id")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = nil)
  if valid_603104 != nil:
    section.add "user-id", valid_603104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Signature")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Signature", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Content-Sha256", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Date")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Date", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Security-Token")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Security-Token", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Algorithm")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Algorithm", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603112: Call_DeleteUserEndpoints_603100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_603112.validator(path, query, header, formData, body)
  let scheme = call_603112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603112.url(scheme.get, call_603112.host, call_603112.base,
                         call_603112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603112, url, valid)

proc call*(call_603113: Call_DeleteUserEndpoints_603100; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_603114 = newJObject()
  add(path_603114, "application-id", newJString(applicationId))
  add(path_603114, "user-id", newJString(userId))
  result = call_603113.call(path_603114, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_603100(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_603101, base: "/",
    url: url_DeleteUserEndpoints_603102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_603129 = ref object of OpenApiRestCall_601373
proc url_UpdateVoiceChannel_603131(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = path.getOrDefault("application-id")
  valid_603132 = validateParameter(valid_603132, JString, required = true,
                                 default = nil)
  if valid_603132 != nil:
    section.add "application-id", valid_603132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603133 = header.getOrDefault("X-Amz-Signature")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Signature", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Security-Token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Security-Token", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_UpdateVoiceChannel_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603141, url, valid)

proc call*(call_603142: Call_UpdateVoiceChannel_603129; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603143 = newJObject()
  var body_603144 = newJObject()
  add(path_603143, "application-id", newJString(applicationId))
  if body != nil:
    body_603144 = body
  result = call_603142.call(path_603143, nil, nil, nil, body_603144)

var updateVoiceChannel* = Call_UpdateVoiceChannel_603129(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_603130, base: "/",
    url: url_UpdateVoiceChannel_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_603115 = ref object of OpenApiRestCall_601373
proc url_GetVoiceChannel_603117(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_603116(path: JsonNode; query: JsonNode;
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
  var valid_603118 = path.getOrDefault("application-id")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = nil)
  if valid_603118 != nil:
    section.add "application-id", valid_603118
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603119 = header.getOrDefault("X-Amz-Signature")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Signature", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Credential")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Credential", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Security-Token")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Security-Token", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_GetVoiceChannel_603115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603126, url, valid)

proc call*(call_603127: Call_GetVoiceChannel_603115; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603128 = newJObject()
  add(path_603128, "application-id", newJString(applicationId))
  result = call_603127.call(path_603128, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_603115(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_603116, base: "/", url: url_GetVoiceChannel_603117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_603145 = ref object of OpenApiRestCall_601373
proc url_DeleteVoiceChannel_603147(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_603146(path: JsonNode; query: JsonNode;
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
  var valid_603148 = path.getOrDefault("application-id")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "application-id", valid_603148
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603149 = header.getOrDefault("X-Amz-Signature")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Signature", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Credential")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Credential", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Security-Token")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Security-Token", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-SignedHeaders", valid_603155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_DeleteVoiceChannel_603145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603156, url, valid)

proc call*(call_603157: Call_DeleteVoiceChannel_603145; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603158 = newJObject()
  add(path_603158, "application-id", newJString(applicationId))
  result = call_603157.call(path_603158, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_603145(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_603146, base: "/",
    url: url_DeleteVoiceChannel_603147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_603159 = ref object of OpenApiRestCall_601373
proc url_GetApplicationDateRangeKpi_603161(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = path.getOrDefault("kpi-name")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "kpi-name", valid_603162
  var valid_603163 = path.getOrDefault("application-id")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "application-id", valid_603163
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
  var valid_603164 = query.getOrDefault("end-time")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "end-time", valid_603164
  var valid_603165 = query.getOrDefault("page-size")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "page-size", valid_603165
  var valid_603166 = query.getOrDefault("start-time")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "start-time", valid_603166
  var valid_603167 = query.getOrDefault("next-token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "next-token", valid_603167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603175: Call_GetApplicationDateRangeKpi_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_603175.validator(path, query, header, formData, body)
  let scheme = call_603175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603175.url(scheme.get, call_603175.host, call_603175.base,
                         call_603175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603175, url, valid)

proc call*(call_603176: Call_GetApplicationDateRangeKpi_603159; kpiName: string;
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
  var path_603177 = newJObject()
  var query_603178 = newJObject()
  add(path_603177, "kpi-name", newJString(kpiName))
  add(path_603177, "application-id", newJString(applicationId))
  add(query_603178, "end-time", newJString(endTime))
  add(query_603178, "page-size", newJString(pageSize))
  add(query_603178, "start-time", newJString(startTime))
  add(query_603178, "next-token", newJString(nextToken))
  result = call_603176.call(path_603177, query_603178, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_603159(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_603160, base: "/",
    url: url_GetApplicationDateRangeKpi_603161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_603193 = ref object of OpenApiRestCall_601373
proc url_UpdateApplicationSettings_603195(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_603194(path: JsonNode; query: JsonNode;
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
  var valid_603196 = path.getOrDefault("application-id")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = nil)
  if valid_603196 != nil:
    section.add "application-id", valid_603196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Credential")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Credential", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Security-Token")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Security-Token", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Algorithm")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Algorithm", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-SignedHeaders", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603205: Call_UpdateApplicationSettings_603193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_603205.validator(path, query, header, formData, body)
  let scheme = call_603205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603205.url(scheme.get, call_603205.host, call_603205.base,
                         call_603205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603205, url, valid)

proc call*(call_603206: Call_UpdateApplicationSettings_603193;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603207 = newJObject()
  var body_603208 = newJObject()
  add(path_603207, "application-id", newJString(applicationId))
  if body != nil:
    body_603208 = body
  result = call_603206.call(path_603207, nil, nil, nil, body_603208)

var updateApplicationSettings* = Call_UpdateApplicationSettings_603193(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_603194, base: "/",
    url: url_UpdateApplicationSettings_603195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_603179 = ref object of OpenApiRestCall_601373
proc url_GetApplicationSettings_603181(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_603180(path: JsonNode; query: JsonNode;
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
  var valid_603182 = path.getOrDefault("application-id")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = nil)
  if valid_603182 != nil:
    section.add "application-id", valid_603182
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603190: Call_GetApplicationSettings_603179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_603190.validator(path, query, header, formData, body)
  let scheme = call_603190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603190.url(scheme.get, call_603190.host, call_603190.base,
                         call_603190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603190, url, valid)

proc call*(call_603191: Call_GetApplicationSettings_603179; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603192 = newJObject()
  add(path_603192, "application-id", newJString(applicationId))
  result = call_603191.call(path_603192, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_603179(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_603180, base: "/",
    url: url_GetApplicationSettings_603181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_603209 = ref object of OpenApiRestCall_601373
proc url_GetCampaignActivities_603211(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_603210(path: JsonNode; query: JsonNode;
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
  var valid_603212 = path.getOrDefault("application-id")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "application-id", valid_603212
  var valid_603213 = path.getOrDefault("campaign-id")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "campaign-id", valid_603213
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_603214 = query.getOrDefault("page-size")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "page-size", valid_603214
  var valid_603215 = query.getOrDefault("token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "token", valid_603215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603216 = header.getOrDefault("X-Amz-Signature")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Signature", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Date")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Date", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Credential")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Credential", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Algorithm")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Algorithm", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_GetCampaignActivities_603209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the activities for a campaign.
  ## 
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603223, url, valid)

proc call*(call_603224: Call_GetCampaignActivities_603209; applicationId: string;
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
  var path_603225 = newJObject()
  var query_603226 = newJObject()
  add(path_603225, "application-id", newJString(applicationId))
  add(query_603226, "page-size", newJString(pageSize))
  add(path_603225, "campaign-id", newJString(campaignId))
  add(query_603226, "token", newJString(token))
  result = call_603224.call(path_603225, query_603226, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_603209(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_603210, base: "/",
    url: url_GetCampaignActivities_603211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_603227 = ref object of OpenApiRestCall_601373
proc url_GetCampaignDateRangeKpi_603229(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_603228(path: JsonNode; query: JsonNode;
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
  var valid_603230 = path.getOrDefault("kpi-name")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = nil)
  if valid_603230 != nil:
    section.add "kpi-name", valid_603230
  var valid_603231 = path.getOrDefault("application-id")
  valid_603231 = validateParameter(valid_603231, JString, required = true,
                                 default = nil)
  if valid_603231 != nil:
    section.add "application-id", valid_603231
  var valid_603232 = path.getOrDefault("campaign-id")
  valid_603232 = validateParameter(valid_603232, JString, required = true,
                                 default = nil)
  if valid_603232 != nil:
    section.add "campaign-id", valid_603232
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
  var valid_603233 = query.getOrDefault("end-time")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "end-time", valid_603233
  var valid_603234 = query.getOrDefault("page-size")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "page-size", valid_603234
  var valid_603235 = query.getOrDefault("start-time")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "start-time", valid_603235
  var valid_603236 = query.getOrDefault("next-token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "next-token", valid_603236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603237 = header.getOrDefault("X-Amz-Signature")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Signature", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Content-Sha256", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_GetCampaignDateRangeKpi_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603244, url, valid)

proc call*(call_603245: Call_GetCampaignDateRangeKpi_603227; kpiName: string;
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
  var path_603246 = newJObject()
  var query_603247 = newJObject()
  add(path_603246, "kpi-name", newJString(kpiName))
  add(path_603246, "application-id", newJString(applicationId))
  add(query_603247, "end-time", newJString(endTime))
  add(query_603247, "page-size", newJString(pageSize))
  add(path_603246, "campaign-id", newJString(campaignId))
  add(query_603247, "start-time", newJString(startTime))
  add(query_603247, "next-token", newJString(nextToken))
  result = call_603245.call(path_603246, query_603247, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_603227(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_603228, base: "/",
    url: url_GetCampaignDateRangeKpi_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_603248 = ref object of OpenApiRestCall_601373
proc url_GetCampaignVersion_603250(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_603249(path: JsonNode; query: JsonNode;
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
  var valid_603251 = path.getOrDefault("version")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "version", valid_603251
  var valid_603252 = path.getOrDefault("application-id")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "application-id", valid_603252
  var valid_603253 = path.getOrDefault("campaign-id")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "campaign-id", valid_603253
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603254 = header.getOrDefault("X-Amz-Signature")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Signature", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Date")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Date", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Security-Token")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Security-Token", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_GetCampaignVersion_603248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603261, url, valid)

proc call*(call_603262: Call_GetCampaignVersion_603248; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_603263 = newJObject()
  add(path_603263, "version", newJString(version))
  add(path_603263, "application-id", newJString(applicationId))
  add(path_603263, "campaign-id", newJString(campaignId))
  result = call_603262.call(path_603263, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_603248(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_603249, base: "/",
    url: url_GetCampaignVersion_603250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_603264 = ref object of OpenApiRestCall_601373
proc url_GetCampaignVersions_603266(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_603265(path: JsonNode; query: JsonNode;
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
  var valid_603267 = path.getOrDefault("application-id")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "application-id", valid_603267
  var valid_603268 = path.getOrDefault("campaign-id")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = nil)
  if valid_603268 != nil:
    section.add "campaign-id", valid_603268
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_603269 = query.getOrDefault("page-size")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "page-size", valid_603269
  var valid_603270 = query.getOrDefault("token")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "token", valid_603270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603271 = header.getOrDefault("X-Amz-Signature")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Signature", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Content-Sha256", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Date")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Date", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Security-Token")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Security-Token", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Algorithm")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Algorithm", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603278: Call_GetCampaignVersions_603264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a campaign.
  ## 
  let valid = call_603278.validator(path, query, header, formData, body)
  let scheme = call_603278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603278.url(scheme.get, call_603278.host, call_603278.base,
                         call_603278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603278, url, valid)

proc call*(call_603279: Call_GetCampaignVersions_603264; applicationId: string;
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
  var path_603280 = newJObject()
  var query_603281 = newJObject()
  add(path_603280, "application-id", newJString(applicationId))
  add(query_603281, "page-size", newJString(pageSize))
  add(path_603280, "campaign-id", newJString(campaignId))
  add(query_603281, "token", newJString(token))
  result = call_603279.call(path_603280, query_603281, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_603264(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_603265, base: "/",
    url: url_GetCampaignVersions_603266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_603282 = ref object of OpenApiRestCall_601373
proc url_GetChannels_603284(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_603283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603285 = path.getOrDefault("application-id")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = nil)
  if valid_603285 != nil:
    section.add "application-id", valid_603285
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603286 = header.getOrDefault("X-Amz-Signature")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Signature", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Content-Sha256", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Date")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Date", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Security-Token")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Security-Token", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Algorithm")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Algorithm", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_GetChannels_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603293, url, valid)

proc call*(call_603294: Call_GetChannels_603282; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603295 = newJObject()
  add(path_603295, "application-id", newJString(applicationId))
  result = call_603294.call(path_603295, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_603282(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_603283,
                                        base: "/", url: url_GetChannels_603284,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_603296 = ref object of OpenApiRestCall_601373
proc url_GetExportJob_603298(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_603297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603299 = path.getOrDefault("job-id")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "job-id", valid_603299
  var valid_603300 = path.getOrDefault("application-id")
  valid_603300 = validateParameter(valid_603300, JString, required = true,
                                 default = nil)
  if valid_603300 != nil:
    section.add "application-id", valid_603300
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603301 = header.getOrDefault("X-Amz-Signature")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Signature", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Content-Sha256", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Date")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Date", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Algorithm")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Algorithm", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603308: Call_GetExportJob_603296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_603308.validator(path, query, header, formData, body)
  let scheme = call_603308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603308.url(scheme.get, call_603308.host, call_603308.base,
                         call_603308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603308, url, valid)

proc call*(call_603309: Call_GetExportJob_603296; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603310 = newJObject()
  add(path_603310, "job-id", newJString(jobId))
  add(path_603310, "application-id", newJString(applicationId))
  result = call_603309.call(path_603310, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_603296(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_603297, base: "/", url: url_GetExportJob_603298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_603311 = ref object of OpenApiRestCall_601373
proc url_GetImportJob_603313(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_603312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603314 = path.getOrDefault("job-id")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = nil)
  if valid_603314 != nil:
    section.add "job-id", valid_603314
  var valid_603315 = path.getOrDefault("application-id")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "application-id", valid_603315
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Signature")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Signature", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Date")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Date", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Credential")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Credential", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Security-Token")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Security-Token", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Algorithm")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Algorithm", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_GetImportJob_603311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603323, url, valid)

proc call*(call_603324: Call_GetImportJob_603311; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_603325 = newJObject()
  add(path_603325, "job-id", newJString(jobId))
  add(path_603325, "application-id", newJString(applicationId))
  result = call_603324.call(path_603325, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_603311(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_603312, base: "/", url: url_GetImportJob_603313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyDateRangeKpi_603326 = ref object of OpenApiRestCall_601373
proc url_GetJourneyDateRangeKpi_603328(protocol: Scheme; host: string; base: string;
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

proc validate_GetJourneyDateRangeKpi_603327(path: JsonNode; query: JsonNode;
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
  var valid_603329 = path.getOrDefault("kpi-name")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = nil)
  if valid_603329 != nil:
    section.add "kpi-name", valid_603329
  var valid_603330 = path.getOrDefault("application-id")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = nil)
  if valid_603330 != nil:
    section.add "application-id", valid_603330
  var valid_603331 = path.getOrDefault("journey-id")
  valid_603331 = validateParameter(valid_603331, JString, required = true,
                                 default = nil)
  if valid_603331 != nil:
    section.add "journey-id", valid_603331
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
  var valid_603332 = query.getOrDefault("end-time")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "end-time", valid_603332
  var valid_603333 = query.getOrDefault("page-size")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "page-size", valid_603333
  var valid_603334 = query.getOrDefault("start-time")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "start-time", valid_603334
  var valid_603335 = query.getOrDefault("next-token")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "next-token", valid_603335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603336 = header.getOrDefault("X-Amz-Signature")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Signature", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Date")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Date", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Credential")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Credential", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Security-Token")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Security-Token", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Algorithm")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Algorithm", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-SignedHeaders", valid_603342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_GetJourneyDateRangeKpi_603326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603343, url, valid)

proc call*(call_603344: Call_GetJourneyDateRangeKpi_603326; kpiName: string;
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
  var path_603345 = newJObject()
  var query_603346 = newJObject()
  add(path_603345, "kpi-name", newJString(kpiName))
  add(path_603345, "application-id", newJString(applicationId))
  add(query_603346, "end-time", newJString(endTime))
  add(query_603346, "page-size", newJString(pageSize))
  add(path_603345, "journey-id", newJString(journeyId))
  add(query_603346, "start-time", newJString(startTime))
  add(query_603346, "next-token", newJString(nextToken))
  result = call_603344.call(path_603345, query_603346, nil, nil, nil)

var getJourneyDateRangeKpi* = Call_GetJourneyDateRangeKpi_603326(
    name: "getJourneyDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetJourneyDateRangeKpi_603327, base: "/",
    url: url_GetJourneyDateRangeKpi_603328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionActivityMetrics_603347 = ref object of OpenApiRestCall_601373
proc url_GetJourneyExecutionActivityMetrics_603349(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionActivityMetrics_603348(path: JsonNode;
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
  var valid_603350 = path.getOrDefault("application-id")
  valid_603350 = validateParameter(valid_603350, JString, required = true,
                                 default = nil)
  if valid_603350 != nil:
    section.add "application-id", valid_603350
  var valid_603351 = path.getOrDefault("journey-activity-id")
  valid_603351 = validateParameter(valid_603351, JString, required = true,
                                 default = nil)
  if valid_603351 != nil:
    section.add "journey-activity-id", valid_603351
  var valid_603352 = path.getOrDefault("journey-id")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "journey-id", valid_603352
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_603353 = query.getOrDefault("page-size")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "page-size", valid_603353
  var valid_603354 = query.getOrDefault("next-token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "next-token", valid_603354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603355 = header.getOrDefault("X-Amz-Signature")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Signature", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Content-Sha256", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Credential")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Credential", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Algorithm")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Algorithm", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-SignedHeaders", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603362: Call_GetJourneyExecutionActivityMetrics_603347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
  ## 
  let valid = call_603362.validator(path, query, header, formData, body)
  let scheme = call_603362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603362.url(scheme.get, call_603362.host, call_603362.base,
                         call_603362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603362, url, valid)

proc call*(call_603363: Call_GetJourneyExecutionActivityMetrics_603347;
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
  var path_603364 = newJObject()
  var query_603365 = newJObject()
  add(path_603364, "application-id", newJString(applicationId))
  add(query_603365, "page-size", newJString(pageSize))
  add(path_603364, "journey-activity-id", newJString(journeyActivityId))
  add(path_603364, "journey-id", newJString(journeyId))
  add(query_603365, "next-token", newJString(nextToken))
  result = call_603363.call(path_603364, query_603365, nil, nil, nil)

var getJourneyExecutionActivityMetrics* = Call_GetJourneyExecutionActivityMetrics_603347(
    name: "getJourneyExecutionActivityMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics",
    validator: validate_GetJourneyExecutionActivityMetrics_603348, base: "/",
    url: url_GetJourneyExecutionActivityMetrics_603349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJourneyExecutionMetrics_603366 = ref object of OpenApiRestCall_601373
proc url_GetJourneyExecutionMetrics_603368(protocol: Scheme; host: string;
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

proc validate_GetJourneyExecutionMetrics_603367(path: JsonNode; query: JsonNode;
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
  var valid_603369 = path.getOrDefault("application-id")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = nil)
  if valid_603369 != nil:
    section.add "application-id", valid_603369
  var valid_603370 = path.getOrDefault("journey-id")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = nil)
  if valid_603370 != nil:
    section.add "journey-id", valid_603370
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_603371 = query.getOrDefault("page-size")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "page-size", valid_603371
  var valid_603372 = query.getOrDefault("next-token")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "next-token", valid_603372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603373 = header.getOrDefault("X-Amz-Signature")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Signature", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Content-Sha256", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Algorithm")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Algorithm", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-SignedHeaders", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603380: Call_GetJourneyExecutionMetrics_603366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
  ## 
  let valid = call_603380.validator(path, query, header, formData, body)
  let scheme = call_603380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603380.url(scheme.get, call_603380.host, call_603380.base,
                         call_603380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603380, url, valid)

proc call*(call_603381: Call_GetJourneyExecutionMetrics_603366;
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
  var path_603382 = newJObject()
  var query_603383 = newJObject()
  add(path_603382, "application-id", newJString(applicationId))
  add(query_603383, "page-size", newJString(pageSize))
  add(path_603382, "journey-id", newJString(journeyId))
  add(query_603383, "next-token", newJString(nextToken))
  result = call_603381.call(path_603382, query_603383, nil, nil, nil)

var getJourneyExecutionMetrics* = Call_GetJourneyExecutionMetrics_603366(
    name: "getJourneyExecutionMetrics", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics",
    validator: validate_GetJourneyExecutionMetrics_603367, base: "/",
    url: url_GetJourneyExecutionMetrics_603368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_603384 = ref object of OpenApiRestCall_601373
proc url_GetSegmentExportJobs_603386(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_603385(path: JsonNode; query: JsonNode;
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
  var valid_603387 = path.getOrDefault("application-id")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "application-id", valid_603387
  var valid_603388 = path.getOrDefault("segment-id")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = nil)
  if valid_603388 != nil:
    section.add "segment-id", valid_603388
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_603389 = query.getOrDefault("page-size")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "page-size", valid_603389
  var valid_603390 = query.getOrDefault("token")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "token", valid_603390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603391 = header.getOrDefault("X-Amz-Signature")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Signature", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Date")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Date", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Credential")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Credential", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Security-Token")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Security-Token", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Algorithm")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Algorithm", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-SignedHeaders", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603398: Call_GetSegmentExportJobs_603384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_603398.validator(path, query, header, formData, body)
  let scheme = call_603398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603398.url(scheme.get, call_603398.host, call_603398.base,
                         call_603398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603398, url, valid)

proc call*(call_603399: Call_GetSegmentExportJobs_603384; applicationId: string;
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
  var path_603400 = newJObject()
  var query_603401 = newJObject()
  add(path_603400, "application-id", newJString(applicationId))
  add(path_603400, "segment-id", newJString(segmentId))
  add(query_603401, "page-size", newJString(pageSize))
  add(query_603401, "token", newJString(token))
  result = call_603399.call(path_603400, query_603401, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_603384(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_603385, base: "/",
    url: url_GetSegmentExportJobs_603386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_603402 = ref object of OpenApiRestCall_601373
proc url_GetSegmentImportJobs_603404(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_603403(path: JsonNode; query: JsonNode;
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
  var valid_603405 = path.getOrDefault("application-id")
  valid_603405 = validateParameter(valid_603405, JString, required = true,
                                 default = nil)
  if valid_603405 != nil:
    section.add "application-id", valid_603405
  var valid_603406 = path.getOrDefault("segment-id")
  valid_603406 = validateParameter(valid_603406, JString, required = true,
                                 default = nil)
  if valid_603406 != nil:
    section.add "segment-id", valid_603406
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_603407 = query.getOrDefault("page-size")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "page-size", valid_603407
  var valid_603408 = query.getOrDefault("token")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "token", valid_603408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603409 = header.getOrDefault("X-Amz-Signature")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Signature", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Date")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Date", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Security-Token")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Security-Token", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Algorithm")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Algorithm", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-SignedHeaders", valid_603415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603416: Call_GetSegmentImportJobs_603402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_603416.validator(path, query, header, formData, body)
  let scheme = call_603416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603416.url(scheme.get, call_603416.host, call_603416.base,
                         call_603416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603416, url, valid)

proc call*(call_603417: Call_GetSegmentImportJobs_603402; applicationId: string;
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
  var path_603418 = newJObject()
  var query_603419 = newJObject()
  add(path_603418, "application-id", newJString(applicationId))
  add(path_603418, "segment-id", newJString(segmentId))
  add(query_603419, "page-size", newJString(pageSize))
  add(query_603419, "token", newJString(token))
  result = call_603417.call(path_603418, query_603419, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_603402(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_603403, base: "/",
    url: url_GetSegmentImportJobs_603404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_603420 = ref object of OpenApiRestCall_601373
proc url_GetSegmentVersion_603422(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_603421(path: JsonNode; query: JsonNode;
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
  var valid_603423 = path.getOrDefault("version")
  valid_603423 = validateParameter(valid_603423, JString, required = true,
                                 default = nil)
  if valid_603423 != nil:
    section.add "version", valid_603423
  var valid_603424 = path.getOrDefault("application-id")
  valid_603424 = validateParameter(valid_603424, JString, required = true,
                                 default = nil)
  if valid_603424 != nil:
    section.add "application-id", valid_603424
  var valid_603425 = path.getOrDefault("segment-id")
  valid_603425 = validateParameter(valid_603425, JString, required = true,
                                 default = nil)
  if valid_603425 != nil:
    section.add "segment-id", valid_603425
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Content-Sha256", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Date")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Date", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Security-Token")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Security-Token", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Algorithm")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Algorithm", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-SignedHeaders", valid_603432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_GetSegmentVersion_603420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603433, url, valid)

proc call*(call_603434: Call_GetSegmentVersion_603420; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_603435 = newJObject()
  add(path_603435, "version", newJString(version))
  add(path_603435, "application-id", newJString(applicationId))
  add(path_603435, "segment-id", newJString(segmentId))
  result = call_603434.call(path_603435, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_603420(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_603421, base: "/",
    url: url_GetSegmentVersion_603422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_603436 = ref object of OpenApiRestCall_601373
proc url_GetSegmentVersions_603438(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_603437(path: JsonNode; query: JsonNode;
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
  var valid_603439 = path.getOrDefault("application-id")
  valid_603439 = validateParameter(valid_603439, JString, required = true,
                                 default = nil)
  if valid_603439 != nil:
    section.add "application-id", valid_603439
  var valid_603440 = path.getOrDefault("segment-id")
  valid_603440 = validateParameter(valid_603440, JString, required = true,
                                 default = nil)
  if valid_603440 != nil:
    section.add "segment-id", valid_603440
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_603441 = query.getOrDefault("page-size")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "page-size", valid_603441
  var valid_603442 = query.getOrDefault("token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "token", valid_603442
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603443 = header.getOrDefault("X-Amz-Signature")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Signature", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Content-Sha256", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Date")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Date", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Credential")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Credential", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Security-Token")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Security-Token", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Algorithm")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Algorithm", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-SignedHeaders", valid_603449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603450: Call_GetSegmentVersions_603436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
  ## 
  let valid = call_603450.validator(path, query, header, formData, body)
  let scheme = call_603450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603450.url(scheme.get, call_603450.host, call_603450.base,
                         call_603450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603450, url, valid)

proc call*(call_603451: Call_GetSegmentVersions_603436; applicationId: string;
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
  var path_603452 = newJObject()
  var query_603453 = newJObject()
  add(path_603452, "application-id", newJString(applicationId))
  add(path_603452, "segment-id", newJString(segmentId))
  add(query_603453, "page-size", newJString(pageSize))
  add(query_603453, "token", newJString(token))
  result = call_603451.call(path_603452, query_603453, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_603436(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_603437, base: "/",
    url: url_GetSegmentVersions_603438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603468 = ref object of OpenApiRestCall_601373
proc url_TagResource_603470(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603469(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603471 = path.getOrDefault("resource-arn")
  valid_603471 = validateParameter(valid_603471, JString, required = true,
                                 default = nil)
  if valid_603471 != nil:
    section.add "resource-arn", valid_603471
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603472 = header.getOrDefault("X-Amz-Signature")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Signature", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Content-Sha256", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Date")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Date", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Credential")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Credential", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Security-Token")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Security-Token", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Algorithm")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Algorithm", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-SignedHeaders", valid_603478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603480: Call_TagResource_603468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_603480.validator(path, query, header, formData, body)
  let scheme = call_603480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603480.url(scheme.get, call_603480.host, call_603480.base,
                         call_603480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603480, url, valid)

proc call*(call_603481: Call_TagResource_603468; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_603482 = newJObject()
  var body_603483 = newJObject()
  add(path_603482, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_603483 = body
  result = call_603481.call(path_603482, nil, nil, nil, body_603483)

var tagResource* = Call_TagResource_603468(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_603469,
                                        base: "/", url: url_TagResource_603470,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603454 = ref object of OpenApiRestCall_601373
proc url_ListTagsForResource_603456(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_603455(path: JsonNode; query: JsonNode;
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
  var valid_603457 = path.getOrDefault("resource-arn")
  valid_603457 = validateParameter(valid_603457, JString, required = true,
                                 default = nil)
  if valid_603457 != nil:
    section.add "resource-arn", valid_603457
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603458 = header.getOrDefault("X-Amz-Signature")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Signature", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Date")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Date", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Security-Token")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Security-Token", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Algorithm")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Algorithm", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-SignedHeaders", valid_603464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603465: Call_ListTagsForResource_603454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_603465.validator(path, query, header, formData, body)
  let scheme = call_603465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603465.url(scheme.get, call_603465.host, call_603465.base,
                         call_603465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603465, url, valid)

proc call*(call_603466: Call_ListTagsForResource_603454; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_603467 = newJObject()
  add(path_603467, "resource-arn", newJString(resourceArn))
  result = call_603466.call(path_603467, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603454(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_603455, base: "/",
    url: url_ListTagsForResource_603456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_603484 = ref object of OpenApiRestCall_601373
proc url_ListTemplateVersions_603486(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_603485(path: JsonNode; query: JsonNode;
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
  var valid_603487 = path.getOrDefault("template-type")
  valid_603487 = validateParameter(valid_603487, JString, required = true,
                                 default = nil)
  if valid_603487 != nil:
    section.add "template-type", valid_603487
  var valid_603488 = path.getOrDefault("template-name")
  valid_603488 = validateParameter(valid_603488, JString, required = true,
                                 default = nil)
  if valid_603488 != nil:
    section.add "template-name", valid_603488
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  ##   next-token: JString
  ##             : The  string that specifies which page of results to return in a paginated response. This parameter is currently not supported for application, campaign, and journey metrics.
  section = newJObject()
  var valid_603489 = query.getOrDefault("page-size")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "page-size", valid_603489
  var valid_603490 = query.getOrDefault("next-token")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "next-token", valid_603490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603491 = header.getOrDefault("X-Amz-Signature")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Signature", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Content-Sha256", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Date")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Date", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Credential")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Credential", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Security-Token")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Security-Token", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-SignedHeaders", valid_603497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603498: Call_ListTemplateVersions_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the versions of a specific message template.
  ## 
  let valid = call_603498.validator(path, query, header, formData, body)
  let scheme = call_603498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603498.url(scheme.get, call_603498.host, call_603498.base,
                         call_603498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603498, url, valid)

proc call*(call_603499: Call_ListTemplateVersions_603484; templateType: string;
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
  var path_603500 = newJObject()
  var query_603501 = newJObject()
  add(path_603500, "template-type", newJString(templateType))
  add(path_603500, "template-name", newJString(templateName))
  add(query_603501, "page-size", newJString(pageSize))
  add(query_603501, "next-token", newJString(nextToken))
  result = call_603499.call(path_603500, query_603501, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_603484(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/versions",
    validator: validate_ListTemplateVersions_603485, base: "/",
    url: url_ListTemplateVersions_603486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_603502 = ref object of OpenApiRestCall_601373
proc url_ListTemplates_603504(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_603503(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603505 = query.getOrDefault("prefix")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "prefix", valid_603505
  var valid_603506 = query.getOrDefault("page-size")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "page-size", valid_603506
  var valid_603507 = query.getOrDefault("template-type")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "template-type", valid_603507
  var valid_603508 = query.getOrDefault("next-token")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "next-token", valid_603508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Date")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Date", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Credential")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Credential", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Security-Token")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Security-Token", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-SignedHeaders", valid_603515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603516: Call_ListTemplates_603502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_603516.validator(path, query, header, formData, body)
  let scheme = call_603516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603516.url(scheme.get, call_603516.host, call_603516.base,
                         call_603516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603516, url, valid)

proc call*(call_603517: Call_ListTemplates_603502; prefix: string = "";
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
  var query_603518 = newJObject()
  add(query_603518, "prefix", newJString(prefix))
  add(query_603518, "page-size", newJString(pageSize))
  add(query_603518, "template-type", newJString(templateType))
  add(query_603518, "next-token", newJString(nextToken))
  result = call_603517.call(nil, query_603518, nil, nil, nil)

var listTemplates* = Call_ListTemplates_603502(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_603503, base: "/",
    url: url_ListTemplates_603504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_603519 = ref object of OpenApiRestCall_601373
proc url_PhoneNumberValidate_603521(protocol: Scheme; host: string; base: string;
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

proc validate_PhoneNumberValidate_603520(path: JsonNode; query: JsonNode;
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
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Content-Sha256", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Date")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Date", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Credential")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Credential", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-SignedHeaders", valid_603528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603530: Call_PhoneNumberValidate_603519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_603530.validator(path, query, header, formData, body)
  let scheme = call_603530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603530.url(scheme.get, call_603530.host, call_603530.base,
                         call_603530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603530, url, valid)

proc call*(call_603531: Call_PhoneNumberValidate_603519; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_603532 = newJObject()
  if body != nil:
    body_603532 = body
  result = call_603531.call(nil, nil, nil, nil, body_603532)

var phoneNumberValidate* = Call_PhoneNumberValidate_603519(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_603520, base: "/",
    url: url_PhoneNumberValidate_603521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_603533 = ref object of OpenApiRestCall_601373
proc url_PutEvents_603535(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_603534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603536 = path.getOrDefault("application-id")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "application-id", valid_603536
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603537 = header.getOrDefault("X-Amz-Signature")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Signature", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Content-Sha256", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Date")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Date", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Credential")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Credential", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Algorithm")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Algorithm", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-SignedHeaders", valid_603543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603545: Call_PutEvents_603533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_603545.validator(path, query, header, formData, body)
  let scheme = call_603545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603545.url(scheme.get, call_603545.host, call_603545.base,
                         call_603545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603545, url, valid)

proc call*(call_603546: Call_PutEvents_603533; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603547 = newJObject()
  var body_603548 = newJObject()
  add(path_603547, "application-id", newJString(applicationId))
  if body != nil:
    body_603548 = body
  result = call_603546.call(path_603547, nil, nil, nil, body_603548)

var putEvents* = Call_PutEvents_603533(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_603534,
                                    base: "/", url: url_PutEvents_603535,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_603549 = ref object of OpenApiRestCall_601373
proc url_RemoveAttributes_603551(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_603550(path: JsonNode; query: JsonNode;
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
  var valid_603552 = path.getOrDefault("attribute-type")
  valid_603552 = validateParameter(valid_603552, JString, required = true,
                                 default = nil)
  if valid_603552 != nil:
    section.add "attribute-type", valid_603552
  var valid_603553 = path.getOrDefault("application-id")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = nil)
  if valid_603553 != nil:
    section.add "application-id", valid_603553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603554 = header.getOrDefault("X-Amz-Signature")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Signature", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Content-Sha256", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Date")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Date", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Credential")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Credential", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Security-Token")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Security-Token", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-SignedHeaders", valid_603560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_RemoveAttributes_603549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603562, url, valid)

proc call*(call_603563: Call_RemoveAttributes_603549; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-metric-attributes - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603564 = newJObject()
  var body_603565 = newJObject()
  add(path_603564, "attribute-type", newJString(attributeType))
  add(path_603564, "application-id", newJString(applicationId))
  if body != nil:
    body_603565 = body
  result = call_603563.call(path_603564, nil, nil, nil, body_603565)

var removeAttributes* = Call_RemoveAttributes_603549(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_603550, base: "/",
    url: url_RemoveAttributes_603551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_603566 = ref object of OpenApiRestCall_601373
proc url_SendMessages_603568(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_603567(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603569 = path.getOrDefault("application-id")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "application-id", valid_603569
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603570 = header.getOrDefault("X-Amz-Signature")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Signature", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Security-Token")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Security-Token", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603578: Call_SendMessages_603566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_603578.validator(path, query, header, formData, body)
  let scheme = call_603578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603578.url(scheme.get, call_603578.host, call_603578.base,
                         call_603578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603578, url, valid)

proc call*(call_603579: Call_SendMessages_603566; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603580 = newJObject()
  var body_603581 = newJObject()
  add(path_603580, "application-id", newJString(applicationId))
  if body != nil:
    body_603581 = body
  result = call_603579.call(path_603580, nil, nil, nil, body_603581)

var sendMessages* = Call_SendMessages_603566(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_603567,
    base: "/", url: url_SendMessages_603568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_603582 = ref object of OpenApiRestCall_601373
proc url_SendUsersMessages_603584(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_603583(path: JsonNode; query: JsonNode;
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
  var valid_603585 = path.getOrDefault("application-id")
  valid_603585 = validateParameter(valid_603585, JString, required = true,
                                 default = nil)
  if valid_603585 != nil:
    section.add "application-id", valid_603585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Content-Sha256", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Date")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Date", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Algorithm")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Algorithm", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_SendUsersMessages_603582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603594, url, valid)

proc call*(call_603595: Call_SendUsersMessages_603582; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603596 = newJObject()
  var body_603597 = newJObject()
  add(path_603596, "application-id", newJString(applicationId))
  if body != nil:
    body_603597 = body
  result = call_603595.call(path_603596, nil, nil, nil, body_603597)

var sendUsersMessages* = Call_SendUsersMessages_603582(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_603583, base: "/",
    url: url_SendUsersMessages_603584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603598 = ref object of OpenApiRestCall_601373
proc url_UntagResource_603600(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603599(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603601 = path.getOrDefault("resource-arn")
  valid_603601 = validateParameter(valid_603601, JString, required = true,
                                 default = nil)
  if valid_603601 != nil:
    section.add "resource-arn", valid_603601
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603602 = query.getOrDefault("tagKeys")
  valid_603602 = validateParameter(valid_603602, JArray, required = true, default = nil)
  if valid_603602 != nil:
    section.add "tagKeys", valid_603602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Content-Sha256", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Credential")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Credential", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Security-Token")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Security-Token", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-SignedHeaders", valid_603609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603610: Call_UntagResource_603598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ## 
  let valid = call_603610.validator(path, query, header, formData, body)
  let scheme = call_603610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603610.url(scheme.get, call_603610.host, call_603610.base,
                         call_603610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603610, url, valid)

proc call*(call_603611: Call_UntagResource_603598; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, journey, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_603612 = newJObject()
  var query_603613 = newJObject()
  add(path_603612, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_603613.add "tagKeys", tagKeys
  result = call_603611.call(path_603612, query_603613, nil, nil, nil)

var untagResource* = Call_UntagResource_603598(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_603599,
    base: "/", url: url_UntagResource_603600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_603614 = ref object of OpenApiRestCall_601373
proc url_UpdateEndpointsBatch_603616(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_603615(path: JsonNode; query: JsonNode;
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
  var valid_603617 = path.getOrDefault("application-id")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "application-id", valid_603617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603618 = header.getOrDefault("X-Amz-Signature")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Signature", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Content-Sha256", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Date")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Date", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Security-Token")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Security-Token", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-SignedHeaders", valid_603624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603626: Call_UpdateEndpointsBatch_603614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_603626.validator(path, query, header, formData, body)
  let scheme = call_603626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603626.url(scheme.get, call_603626.host, call_603626.base,
                         call_603626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603626, url, valid)

proc call*(call_603627: Call_UpdateEndpointsBatch_603614; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_603628 = newJObject()
  var body_603629 = newJObject()
  add(path_603628, "application-id", newJString(applicationId))
  if body != nil:
    body_603629 = body
  result = call_603627.call(path_603628, nil, nil, nil, body_603629)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_603614(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_603615, base: "/",
    url: url_UpdateEndpointsBatch_603616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJourneyState_603630 = ref object of OpenApiRestCall_601373
proc url_UpdateJourneyState_603632(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJourneyState_603631(path: JsonNode; query: JsonNode;
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
  var valid_603633 = path.getOrDefault("application-id")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = nil)
  if valid_603633 != nil:
    section.add "application-id", valid_603633
  var valid_603634 = path.getOrDefault("journey-id")
  valid_603634 = validateParameter(valid_603634, JString, required = true,
                                 default = nil)
  if valid_603634 != nil:
    section.add "journey-id", valid_603634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Content-Sha256", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Date")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Date", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Credential")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Credential", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Security-Token")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Security-Token", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Algorithm")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Algorithm", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-SignedHeaders", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_UpdateJourneyState_603630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) an active journey.
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603643, url, valid)

proc call*(call_603644: Call_UpdateJourneyState_603630; applicationId: string;
          body: JsonNode; journeyId: string): Recallable =
  ## updateJourneyState
  ## Cancels (stops) an active journey.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   journeyId: string (required)
  ##            : The unique identifier for the journey.
  var path_603645 = newJObject()
  var body_603646 = newJObject()
  add(path_603645, "application-id", newJString(applicationId))
  if body != nil:
    body_603646 = body
  add(path_603645, "journey-id", newJString(journeyId))
  result = call_603644.call(path_603645, nil, nil, nil, body_603646)

var updateJourneyState* = Call_UpdateJourneyState_603630(
    name: "updateJourneyState", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/journeys/{journey-id}/state",
    validator: validate_UpdateJourneyState_603631, base: "/",
    url: url_UpdateJourneyState_603632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateActiveVersion_603647 = ref object of OpenApiRestCall_601373
proc url_UpdateTemplateActiveVersion_603649(protocol: Scheme; host: string;
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

proc validate_UpdateTemplateActiveVersion_603648(path: JsonNode; query: JsonNode;
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
  var valid_603650 = path.getOrDefault("template-type")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = nil)
  if valid_603650 != nil:
    section.add "template-type", valid_603650
  var valid_603651 = path.getOrDefault("template-name")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "template-name", valid_603651
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603652 = header.getOrDefault("X-Amz-Signature")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Signature", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Content-Sha256", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Credential")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Credential", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Security-Token")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Security-Token", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Algorithm")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Algorithm", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-SignedHeaders", valid_603658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603660: Call_UpdateTemplateActiveVersion_603647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ## 
  let valid = call_603660.validator(path, query, header, formData, body)
  let scheme = call_603660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603660.url(scheme.get, call_603660.host, call_603660.base,
                         call_603660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603660, url, valid)

proc call*(call_603661: Call_UpdateTemplateActiveVersion_603647;
          templateType: string; templateName: string; body: JsonNode): Recallable =
  ## updateTemplateActiveVersion
  ## Changes the status of a specific version of a message template to <i>active</i>.
  ##   templateType: string (required)
  ##               : The type of channel that the message template is designed for. Valid values are: EMAIL, PUSH, SMS, and VOICE.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_603662 = newJObject()
  var body_603663 = newJObject()
  add(path_603662, "template-type", newJString(templateType))
  add(path_603662, "template-name", newJString(templateName))
  if body != nil:
    body_603663 = body
  result = call_603661.call(path_603662, nil, nil, nil, body_603663)

var updateTemplateActiveVersion* = Call_UpdateTemplateActiveVersion_603647(
    name: "updateTemplateActiveVersion", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/{template-type}/active-version",
    validator: validate_UpdateTemplateActiveVersion_603648, base: "/",
    url: url_UpdateTemplateActiveVersion_603649,
    schemes: {Scheme.Https, Scheme.Http})
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
