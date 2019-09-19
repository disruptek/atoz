
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_601009 = ref object of OpenApiRestCall_600410
proc url_CreateApp_601011(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApp_601010(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601012 = header.getOrDefault("X-Amz-Date")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Date", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Security-Token")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Security-Token", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Content-Sha256", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Algorithm")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Algorithm", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Signature")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Signature", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-SignedHeaders", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Credential")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Credential", valid_601018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601020: Call_CreateApp_601009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_601020.validator(path, query, header, formData, body)
  let scheme = call_601020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601020.url(scheme.get, call_601020.host, call_601020.base,
                         call_601020.route, valid.getOrDefault("path"))
  result = hook(call_601020, url, valid)

proc call*(call_601021: Call_CreateApp_601009; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_601022 = newJObject()
  if body != nil:
    body_601022 = body
  result = call_601021.call(nil, nil, nil, nil, body_601022)

var createApp* = Call_CreateApp_601009(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_601010,
                                    base: "/", url: url_CreateApp_601011,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_600752 = ref object of OpenApiRestCall_600410
proc url_GetApps_600754(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApps_600753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600866 = query.getOrDefault("token")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "token", valid_600866
  var valid_600867 = query.getOrDefault("page-size")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "page-size", valid_600867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600868 = header.getOrDefault("X-Amz-Date")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-Date", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Security-Token")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Security-Token", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Content-Sha256", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Algorithm")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Algorithm", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Signature")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Signature", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-SignedHeaders", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Credential")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Credential", valid_600874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600897: Call_GetApps_600752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_600897.validator(path, query, header, formData, body)
  let scheme = call_600897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600897.url(scheme.get, call_600897.host, call_600897.base,
                         call_600897.route, valid.getOrDefault("path"))
  result = hook(call_600897, url, valid)

proc call*(call_600968: Call_GetApps_600752; token: string = ""; pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var query_600969 = newJObject()
  add(query_600969, "token", newJString(token))
  add(query_600969, "page-size", newJString(pageSize))
  result = call_600968.call(nil, query_600969, nil, nil, nil)

var getApps* = Call_GetApps_600752(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_600753, base: "/",
                                url: url_GetApps_600754,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_601054 = ref object of OpenApiRestCall_600410
proc url_CreateCampaign_601056(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateCampaign_601055(path: JsonNode; query: JsonNode;
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
  var valid_601057 = path.getOrDefault("application-id")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "application-id", valid_601057
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_CreateCampaign_601054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_CreateCampaign_601054; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601068 = newJObject()
  var body_601069 = newJObject()
  add(path_601068, "application-id", newJString(applicationId))
  if body != nil:
    body_601069 = body
  result = call_601067.call(path_601068, nil, nil, nil, body_601069)

var createCampaign* = Call_CreateCampaign_601054(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_601055, base: "/", url: url_CreateCampaign_601056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_601023 = ref object of OpenApiRestCall_600410
proc url_GetCampaigns_601025(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/campaigns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaigns_601024(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601040 = path.getOrDefault("application-id")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "application-id", valid_601040
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601041 = query.getOrDefault("token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "token", valid_601041
  var valid_601042 = query.getOrDefault("page-size")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "page-size", valid_601042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601043 = header.getOrDefault("X-Amz-Date")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Date", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Security-Token")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Security-Token", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Content-Sha256", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Algorithm")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Algorithm", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Signature")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Signature", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-SignedHeaders", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Credential")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Credential", valid_601049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601050: Call_GetCampaigns_601023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_601050.validator(path, query, header, formData, body)
  let scheme = call_601050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601050.url(scheme.get, call_601050.host, call_601050.base,
                         call_601050.route, valid.getOrDefault("path"))
  result = hook(call_601050, url, valid)

proc call*(call_601051: Call_GetCampaigns_601023; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_601052 = newJObject()
  var query_601053 = newJObject()
  add(query_601053, "token", newJString(token))
  add(path_601052, "application-id", newJString(applicationId))
  add(query_601053, "page-size", newJString(pageSize))
  result = call_601051.call(path_601052, query_601053, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_601023(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_601024, base: "/", url: url_GetCampaigns_601025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_601087 = ref object of OpenApiRestCall_600410
proc url_CreateExportJob_601089(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/export")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateExportJob_601088(path: JsonNode; query: JsonNode;
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
  var valid_601090 = path.getOrDefault("application-id")
  valid_601090 = validateParameter(valid_601090, JString, required = true,
                                 default = nil)
  if valid_601090 != nil:
    section.add "application-id", valid_601090
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Content-Sha256", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Algorithm")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Algorithm", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Signature")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Signature", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-SignedHeaders", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Credential")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Credential", valid_601097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601099: Call_CreateExportJob_601087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new export job for an application.
  ## 
  let valid = call_601099.validator(path, query, header, formData, body)
  let scheme = call_601099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601099.url(scheme.get, call_601099.host, call_601099.base,
                         call_601099.route, valid.getOrDefault("path"))
  result = hook(call_601099, url, valid)

proc call*(call_601100: Call_CreateExportJob_601087; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates a new export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601101 = newJObject()
  var body_601102 = newJObject()
  add(path_601101, "application-id", newJString(applicationId))
  if body != nil:
    body_601102 = body
  result = call_601100.call(path_601101, nil, nil, nil, body_601102)

var createExportJob* = Call_CreateExportJob_601087(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_601088, base: "/", url: url_CreateExportJob_601089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_601070 = ref object of OpenApiRestCall_600410
proc url_GetExportJobs_601072(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/export")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetExportJobs_601071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601073 = path.getOrDefault("application-id")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "application-id", valid_601073
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601074 = query.getOrDefault("token")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "token", valid_601074
  var valid_601075 = query.getOrDefault("page-size")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "page-size", valid_601075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Content-Sha256", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Algorithm")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Algorithm", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Signature")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Signature", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-SignedHeaders", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Credential")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Credential", valid_601082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601083: Call_GetExportJobs_601070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_601083.validator(path, query, header, formData, body)
  let scheme = call_601083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601083.url(scheme.get, call_601083.host, call_601083.base,
                         call_601083.route, valid.getOrDefault("path"))
  result = hook(call_601083, url, valid)

proc call*(call_601084: Call_GetExportJobs_601070; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_601085 = newJObject()
  var query_601086 = newJObject()
  add(query_601086, "token", newJString(token))
  add(path_601085, "application-id", newJString(applicationId))
  add(query_601086, "page-size", newJString(pageSize))
  result = call_601084.call(path_601085, query_601086, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_601070(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_601071, base: "/", url: url_GetExportJobs_601072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_601120 = ref object of OpenApiRestCall_600410
proc url_CreateImportJob_601122(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/import")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateImportJob_601121(path: JsonNode; query: JsonNode;
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
  var valid_601123 = path.getOrDefault("application-id")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "application-id", valid_601123
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601124 = header.getOrDefault("X-Amz-Date")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Date", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Security-Token")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Security-Token", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Content-Sha256", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Algorithm")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Algorithm", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Signature")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Signature", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-SignedHeaders", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Credential")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Credential", valid_601130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_CreateImportJob_601120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new import job for an application.
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_CreateImportJob_601120; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates a new import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601134 = newJObject()
  var body_601135 = newJObject()
  add(path_601134, "application-id", newJString(applicationId))
  if body != nil:
    body_601135 = body
  result = call_601133.call(path_601134, nil, nil, nil, body_601135)

var createImportJob* = Call_CreateImportJob_601120(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_601121, base: "/", url: url_CreateImportJob_601122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_601103 = ref object of OpenApiRestCall_600410
proc url_GetImportJobs_601105(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/jobs/import")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetImportJobs_601104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601106 = path.getOrDefault("application-id")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = nil)
  if valid_601106 != nil:
    section.add "application-id", valid_601106
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601107 = query.getOrDefault("token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "token", valid_601107
  var valid_601108 = query.getOrDefault("page-size")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "page-size", valid_601108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601109 = header.getOrDefault("X-Amz-Date")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Date", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Security-Token")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Security-Token", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Content-Sha256", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Algorithm")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Algorithm", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Signature")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Signature", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-SignedHeaders", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Credential")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Credential", valid_601115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601116: Call_GetImportJobs_601103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_601116.validator(path, query, header, formData, body)
  let scheme = call_601116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601116.url(scheme.get, call_601116.host, call_601116.base,
                         call_601116.route, valid.getOrDefault("path"))
  result = hook(call_601116, url, valid)

proc call*(call_601117: Call_GetImportJobs_601103; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_601118 = newJObject()
  var query_601119 = newJObject()
  add(query_601119, "token", newJString(token))
  add(path_601118, "application-id", newJString(applicationId))
  add(query_601119, "page-size", newJString(pageSize))
  result = call_601117.call(path_601118, query_601119, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_601103(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_601104, base: "/", url: url_GetImportJobs_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_601153 = ref object of OpenApiRestCall_600410
proc url_CreateSegment_601155(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateSegment_601154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601156 = path.getOrDefault("application-id")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "application-id", valid_601156
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601157 = header.getOrDefault("X-Amz-Date")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Date", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Security-Token")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Security-Token", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Content-Sha256", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Algorithm")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Algorithm", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Signature")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Signature", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-SignedHeaders", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Credential")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Credential", valid_601163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601165: Call_CreateSegment_601153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_601165.validator(path, query, header, formData, body)
  let scheme = call_601165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601165.url(scheme.get, call_601165.host, call_601165.base,
                         call_601165.route, valid.getOrDefault("path"))
  result = hook(call_601165, url, valid)

proc call*(call_601166: Call_CreateSegment_601153; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601167 = newJObject()
  var body_601168 = newJObject()
  add(path_601167, "application-id", newJString(applicationId))
  if body != nil:
    body_601168 = body
  result = call_601166.call(path_601167, nil, nil, nil, body_601168)

var createSegment* = Call_CreateSegment_601153(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_601154, base: "/", url: url_CreateSegment_601155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_601136 = ref object of OpenApiRestCall_600410
proc url_GetSegments_601138(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/segments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegments_601137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601139 = path.getOrDefault("application-id")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = nil)
  if valid_601139 != nil:
    section.add "application-id", valid_601139
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601140 = query.getOrDefault("token")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "token", valid_601140
  var valid_601141 = query.getOrDefault("page-size")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "page-size", valid_601141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601142 = header.getOrDefault("X-Amz-Date")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Date", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Security-Token")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Security-Token", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Content-Sha256", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Algorithm")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Algorithm", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Signature")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Signature", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-SignedHeaders", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Credential")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Credential", valid_601148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601149: Call_GetSegments_601136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_601149.validator(path, query, header, formData, body)
  let scheme = call_601149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601149.url(scheme.get, call_601149.host, call_601149.base,
                         call_601149.route, valid.getOrDefault("path"))
  result = hook(call_601149, url, valid)

proc call*(call_601150: Call_GetSegments_601136; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_601151 = newJObject()
  var query_601152 = newJObject()
  add(query_601152, "token", newJString(token))
  add(path_601151, "application-id", newJString(applicationId))
  add(query_601152, "page-size", newJString(pageSize))
  result = call_601150.call(path_601151, query_601152, nil, nil, nil)

var getSegments* = Call_GetSegments_601136(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_601137,
                                        base: "/", url: url_GetSegments_601138,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_601183 = ref object of OpenApiRestCall_600410
proc url_UpdateAdmChannel_601185(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateAdmChannel_601184(path: JsonNode; query: JsonNode;
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
  var valid_601186 = path.getOrDefault("application-id")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "application-id", valid_601186
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601195: Call_UpdateAdmChannel_601183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ADM channel settings for an application.
  ## 
  let valid = call_601195.validator(path, query, header, formData, body)
  let scheme = call_601195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601195.url(scheme.get, call_601195.host, call_601195.base,
                         call_601195.route, valid.getOrDefault("path"))
  result = hook(call_601195, url, valid)

proc call*(call_601196: Call_UpdateAdmChannel_601183; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Updates the ADM channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601197 = newJObject()
  var body_601198 = newJObject()
  add(path_601197, "application-id", newJString(applicationId))
  if body != nil:
    body_601198 = body
  result = call_601196.call(path_601197, nil, nil, nil, body_601198)

var updateAdmChannel* = Call_UpdateAdmChannel_601183(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_601184, base: "/",
    url: url_UpdateAdmChannel_601185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_601169 = ref object of OpenApiRestCall_600410
proc url_GetAdmChannel_601171(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAdmChannel_601170(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601172 = path.getOrDefault("application-id")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = nil)
  if valid_601172 != nil:
    section.add "application-id", valid_601172
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601173 = header.getOrDefault("X-Amz-Date")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Date", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Security-Token")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Security-Token", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Content-Sha256", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Algorithm")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Algorithm", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Signature")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Signature", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-SignedHeaders", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Credential")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Credential", valid_601179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601180: Call_GetAdmChannel_601169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_601180.validator(path, query, header, formData, body)
  let scheme = call_601180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601180.url(scheme.get, call_601180.host, call_601180.base,
                         call_601180.route, valid.getOrDefault("path"))
  result = hook(call_601180, url, valid)

proc call*(call_601181: Call_GetAdmChannel_601169; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601182 = newJObject()
  add(path_601182, "application-id", newJString(applicationId))
  result = call_601181.call(path_601182, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_601169(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_601170, base: "/", url: url_GetAdmChannel_601171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_601199 = ref object of OpenApiRestCall_600410
proc url_DeleteAdmChannel_601201(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/adm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteAdmChannel_601200(path: JsonNode; query: JsonNode;
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
  var valid_601202 = path.getOrDefault("application-id")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = nil)
  if valid_601202 != nil:
    section.add "application-id", valid_601202
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601203 = header.getOrDefault("X-Amz-Date")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Date", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Security-Token")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Security-Token", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601210: Call_DeleteAdmChannel_601199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"))
  result = hook(call_601210, url, valid)

proc call*(call_601211: Call_DeleteAdmChannel_601199; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601212 = newJObject()
  add(path_601212, "application-id", newJString(applicationId))
  result = call_601211.call(path_601212, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_601199(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_601200, base: "/",
    url: url_DeleteAdmChannel_601201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_601227 = ref object of OpenApiRestCall_600410
proc url_UpdateApnsChannel_601229(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApnsChannel_601228(path: JsonNode; query: JsonNode;
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
  var valid_601230 = path.getOrDefault("application-id")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "application-id", valid_601230
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601239: Call_UpdateApnsChannel_601227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs channel settings for an application.
  ## 
  let valid = call_601239.validator(path, query, header, formData, body)
  let scheme = call_601239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601239.url(scheme.get, call_601239.host, call_601239.base,
                         call_601239.route, valid.getOrDefault("path"))
  result = hook(call_601239, url, valid)

proc call*(call_601240: Call_UpdateApnsChannel_601227; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Updates the APNs channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601241 = newJObject()
  var body_601242 = newJObject()
  add(path_601241, "application-id", newJString(applicationId))
  if body != nil:
    body_601242 = body
  result = call_601240.call(path_601241, nil, nil, nil, body_601242)

var updateApnsChannel* = Call_UpdateApnsChannel_601227(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_601228, base: "/",
    url: url_UpdateApnsChannel_601229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_601213 = ref object of OpenApiRestCall_600410
proc url_GetApnsChannel_601215(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApnsChannel_601214(path: JsonNode; query: JsonNode;
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
  var valid_601216 = path.getOrDefault("application-id")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "application-id", valid_601216
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601217 = header.getOrDefault("X-Amz-Date")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Date", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Security-Token")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Security-Token", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Content-Sha256", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Algorithm")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Algorithm", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Signature")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Signature", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-SignedHeaders", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Credential")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Credential", valid_601223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_GetApnsChannel_601213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_GetApnsChannel_601213; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601226 = newJObject()
  add(path_601226, "application-id", newJString(applicationId))
  result = call_601225.call(path_601226, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_601213(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_601214, base: "/", url: url_GetApnsChannel_601215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_601243 = ref object of OpenApiRestCall_600410
proc url_DeleteApnsChannel_601245(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApnsChannel_601244(path: JsonNode; query: JsonNode;
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
  var valid_601246 = path.getOrDefault("application-id")
  valid_601246 = validateParameter(valid_601246, JString, required = true,
                                 default = nil)
  if valid_601246 != nil:
    section.add "application-id", valid_601246
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601247 = header.getOrDefault("X-Amz-Date")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Date", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Security-Token")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Security-Token", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Content-Sha256", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Algorithm")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Algorithm", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Signature")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Signature", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-SignedHeaders", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Credential")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Credential", valid_601253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601254: Call_DeleteApnsChannel_601243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601254.validator(path, query, header, formData, body)
  let scheme = call_601254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601254.url(scheme.get, call_601254.host, call_601254.base,
                         call_601254.route, valid.getOrDefault("path"))
  result = hook(call_601254, url, valid)

proc call*(call_601255: Call_DeleteApnsChannel_601243; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601256 = newJObject()
  add(path_601256, "application-id", newJString(applicationId))
  result = call_601255.call(path_601256, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_601243(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_601244, base: "/",
    url: url_DeleteApnsChannel_601245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_601271 = ref object of OpenApiRestCall_600410
proc url_UpdateApnsSandboxChannel_601273(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApnsSandboxChannel_601272(path: JsonNode; query: JsonNode;
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
  var valid_601274 = path.getOrDefault("application-id")
  valid_601274 = validateParameter(valid_601274, JString, required = true,
                                 default = nil)
  if valid_601274 != nil:
    section.add "application-id", valid_601274
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601275 = header.getOrDefault("X-Amz-Date")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Date", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Security-Token")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Security-Token", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Content-Sha256", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Algorithm")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Algorithm", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Signature")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Signature", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-SignedHeaders", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Credential")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Credential", valid_601281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_UpdateApnsSandboxChannel_601271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs sandbox channel settings for an application.
  ## 
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_UpdateApnsSandboxChannel_601271;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Updates the APNs sandbox channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601285 = newJObject()
  var body_601286 = newJObject()
  add(path_601285, "application-id", newJString(applicationId))
  if body != nil:
    body_601286 = body
  result = call_601284.call(path_601285, nil, nil, nil, body_601286)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_601271(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_601272, base: "/",
    url: url_UpdateApnsSandboxChannel_601273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_601257 = ref object of OpenApiRestCall_600410
proc url_GetApnsSandboxChannel_601259(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApnsSandboxChannel_601258(path: JsonNode; query: JsonNode;
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
  var valid_601260 = path.getOrDefault("application-id")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = nil)
  if valid_601260 != nil:
    section.add "application-id", valid_601260
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601261 = header.getOrDefault("X-Amz-Date")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Date", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Security-Token")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Security-Token", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Content-Sha256", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Algorithm")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Algorithm", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Signature")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Signature", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-SignedHeaders", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Credential")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Credential", valid_601267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601268: Call_GetApnsSandboxChannel_601257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_601268.validator(path, query, header, formData, body)
  let scheme = call_601268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601268.url(scheme.get, call_601268.host, call_601268.base,
                         call_601268.route, valid.getOrDefault("path"))
  result = hook(call_601268, url, valid)

proc call*(call_601269: Call_GetApnsSandboxChannel_601257; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601270 = newJObject()
  add(path_601270, "application-id", newJString(applicationId))
  result = call_601269.call(path_601270, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_601257(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_601258, base: "/",
    url: url_GetApnsSandboxChannel_601259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_601287 = ref object of OpenApiRestCall_600410
proc url_DeleteApnsSandboxChannel_601289(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApnsSandboxChannel_601288(path: JsonNode; query: JsonNode;
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
  var valid_601290 = path.getOrDefault("application-id")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "application-id", valid_601290
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601291 = header.getOrDefault("X-Amz-Date")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Date", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Security-Token")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Security-Token", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Content-Sha256", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Algorithm")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Algorithm", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Signature")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Signature", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-SignedHeaders", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Credential")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Credential", valid_601297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601298: Call_DeleteApnsSandboxChannel_601287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601298.validator(path, query, header, formData, body)
  let scheme = call_601298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601298.url(scheme.get, call_601298.host, call_601298.base,
                         call_601298.route, valid.getOrDefault("path"))
  result = hook(call_601298, url, valid)

proc call*(call_601299: Call_DeleteApnsSandboxChannel_601287; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601300 = newJObject()
  add(path_601300, "application-id", newJString(applicationId))
  result = call_601299.call(path_601300, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_601287(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_601288, base: "/",
    url: url_DeleteApnsSandboxChannel_601289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_601315 = ref object of OpenApiRestCall_600410
proc url_UpdateApnsVoipChannel_601317(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApnsVoipChannel_601316(path: JsonNode; query: JsonNode;
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
  var valid_601318 = path.getOrDefault("application-id")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = nil)
  if valid_601318 != nil:
    section.add "application-id", valid_601318
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601319 = header.getOrDefault("X-Amz-Date")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Date", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Security-Token")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Security-Token", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Content-Sha256", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Algorithm")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Algorithm", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Signature")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Signature", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-SignedHeaders", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Credential")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Credential", valid_601325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601327: Call_UpdateApnsVoipChannel_601315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs VoIP channel settings for an application.
  ## 
  let valid = call_601327.validator(path, query, header, formData, body)
  let scheme = call_601327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601327.url(scheme.get, call_601327.host, call_601327.base,
                         call_601327.route, valid.getOrDefault("path"))
  result = hook(call_601327, url, valid)

proc call*(call_601328: Call_UpdateApnsVoipChannel_601315; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Updates the APNs VoIP channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601329 = newJObject()
  var body_601330 = newJObject()
  add(path_601329, "application-id", newJString(applicationId))
  if body != nil:
    body_601330 = body
  result = call_601328.call(path_601329, nil, nil, nil, body_601330)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_601315(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_601316, base: "/",
    url: url_UpdateApnsVoipChannel_601317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_601301 = ref object of OpenApiRestCall_600410
proc url_GetApnsVoipChannel_601303(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApnsVoipChannel_601302(path: JsonNode; query: JsonNode;
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
  var valid_601304 = path.getOrDefault("application-id")
  valid_601304 = validateParameter(valid_601304, JString, required = true,
                                 default = nil)
  if valid_601304 != nil:
    section.add "application-id", valid_601304
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_601312: Call_GetApnsVoipChannel_601301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_601312.validator(path, query, header, formData, body)
  let scheme = call_601312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601312.url(scheme.get, call_601312.host, call_601312.base,
                         call_601312.route, valid.getOrDefault("path"))
  result = hook(call_601312, url, valid)

proc call*(call_601313: Call_GetApnsVoipChannel_601301; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601314 = newJObject()
  add(path_601314, "application-id", newJString(applicationId))
  result = call_601313.call(path_601314, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_601301(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_601302, base: "/",
    url: url_GetApnsVoipChannel_601303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_601331 = ref object of OpenApiRestCall_600410
proc url_DeleteApnsVoipChannel_601333(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApnsVoipChannel_601332(path: JsonNode; query: JsonNode;
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
  var valid_601334 = path.getOrDefault("application-id")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "application-id", valid_601334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601335 = header.getOrDefault("X-Amz-Date")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Date", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Security-Token")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Security-Token", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Content-Sha256", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Algorithm")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Algorithm", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Signature")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Signature", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-SignedHeaders", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Credential")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Credential", valid_601341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601342: Call_DeleteApnsVoipChannel_601331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601342.validator(path, query, header, formData, body)
  let scheme = call_601342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601342.url(scheme.get, call_601342.host, call_601342.base,
                         call_601342.route, valid.getOrDefault("path"))
  result = hook(call_601342, url, valid)

proc call*(call_601343: Call_DeleteApnsVoipChannel_601331; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601344 = newJObject()
  add(path_601344, "application-id", newJString(applicationId))
  result = call_601343.call(path_601344, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_601331(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_601332, base: "/",
    url: url_DeleteApnsVoipChannel_601333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_601359 = ref object of OpenApiRestCall_600410
proc url_UpdateApnsVoipSandboxChannel_601361(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApnsVoipSandboxChannel_601360(path: JsonNode; query: JsonNode;
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
  var valid_601362 = path.getOrDefault("application-id")
  valid_601362 = validateParameter(valid_601362, JString, required = true,
                                 default = nil)
  if valid_601362 != nil:
    section.add "application-id", valid_601362
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601363 = header.getOrDefault("X-Amz-Date")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Date", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Security-Token")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Security-Token", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Content-Sha256", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Algorithm")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Algorithm", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Signature")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Signature", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-SignedHeaders", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Credential")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Credential", valid_601369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_UpdateApnsVoipSandboxChannel_601359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"))
  result = hook(call_601371, url, valid)

proc call*(call_601372: Call_UpdateApnsVoipSandboxChannel_601359;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601373 = newJObject()
  var body_601374 = newJObject()
  add(path_601373, "application-id", newJString(applicationId))
  if body != nil:
    body_601374 = body
  result = call_601372.call(path_601373, nil, nil, nil, body_601374)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_601359(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_601360, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_601361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_601345 = ref object of OpenApiRestCall_600410
proc url_GetApnsVoipSandboxChannel_601347(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApnsVoipSandboxChannel_601346(path: JsonNode; query: JsonNode;
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
  var valid_601348 = path.getOrDefault("application-id")
  valid_601348 = validateParameter(valid_601348, JString, required = true,
                                 default = nil)
  if valid_601348 != nil:
    section.add "application-id", valid_601348
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601349 = header.getOrDefault("X-Amz-Date")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Date", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Security-Token")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Security-Token", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Content-Sha256", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Algorithm")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Algorithm", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Signature")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Signature", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-SignedHeaders", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Credential")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Credential", valid_601355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601356: Call_GetApnsVoipSandboxChannel_601345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_601356.validator(path, query, header, formData, body)
  let scheme = call_601356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601356.url(scheme.get, call_601356.host, call_601356.base,
                         call_601356.route, valid.getOrDefault("path"))
  result = hook(call_601356, url, valid)

proc call*(call_601357: Call_GetApnsVoipSandboxChannel_601345;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601358 = newJObject()
  add(path_601358, "application-id", newJString(applicationId))
  result = call_601357.call(path_601358, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_601345(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_601346, base: "/",
    url: url_GetApnsVoipSandboxChannel_601347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_601375 = ref object of OpenApiRestCall_600410
proc url_DeleteApnsVoipSandboxChannel_601377(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/apns_voip_sandbox")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApnsVoipSandboxChannel_601376(path: JsonNode; query: JsonNode;
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
  var valid_601378 = path.getOrDefault("application-id")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = nil)
  if valid_601378 != nil:
    section.add "application-id", valid_601378
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601379 = header.getOrDefault("X-Amz-Date")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Date", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Security-Token")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Security-Token", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Content-Sha256", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Algorithm")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Algorithm", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Signature")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Signature", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-SignedHeaders", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Credential")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Credential", valid_601385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601386: Call_DeleteApnsVoipSandboxChannel_601375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601386.validator(path, query, header, formData, body)
  let scheme = call_601386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601386.url(scheme.get, call_601386.host, call_601386.base,
                         call_601386.route, valid.getOrDefault("path"))
  result = hook(call_601386, url, valid)

proc call*(call_601387: Call_DeleteApnsVoipSandboxChannel_601375;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601388 = newJObject()
  add(path_601388, "application-id", newJString(applicationId))
  result = call_601387.call(path_601388, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_601375(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_601376, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_601377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_601389 = ref object of OpenApiRestCall_600410
proc url_GetApp_601391(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApp_601390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601392 = path.getOrDefault("application-id")
  valid_601392 = validateParameter(valid_601392, JString, required = true,
                                 default = nil)
  if valid_601392 != nil:
    section.add "application-id", valid_601392
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_601400: Call_GetApp_601389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"))
  result = hook(call_601400, url, valid)

proc call*(call_601401: Call_GetApp_601389; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601402 = newJObject()
  add(path_601402, "application-id", newJString(applicationId))
  result = call_601401.call(path_601402, nil, nil, nil, nil)

var getApp* = Call_GetApp_601389(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_601390, base: "/",
                              url: url_GetApp_601391,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_601403 = ref object of OpenApiRestCall_600410
proc url_DeleteApp_601405(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApp_601404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601406 = path.getOrDefault("application-id")
  valid_601406 = validateParameter(valid_601406, JString, required = true,
                                 default = nil)
  if valid_601406 != nil:
    section.add "application-id", valid_601406
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601407 = header.getOrDefault("X-Amz-Date")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Date", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Security-Token")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Security-Token", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Content-Sha256", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Algorithm")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Algorithm", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Signature")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Signature", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-SignedHeaders", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Credential")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Credential", valid_601413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601414: Call_DeleteApp_601403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_601414.validator(path, query, header, formData, body)
  let scheme = call_601414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601414.url(scheme.get, call_601414.host, call_601414.base,
                         call_601414.route, valid.getOrDefault("path"))
  result = hook(call_601414, url, valid)

proc call*(call_601415: Call_DeleteApp_601403; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601416 = newJObject()
  add(path_601416, "application-id", newJString(applicationId))
  result = call_601415.call(path_601416, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_601403(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_601404,
                                    base: "/", url: url_DeleteApp_601405,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_601431 = ref object of OpenApiRestCall_600410
proc url_UpdateBaiduChannel_601433(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateBaiduChannel_601432(path: JsonNode; query: JsonNode;
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
  var valid_601434 = path.getOrDefault("application-id")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = nil)
  if valid_601434 != nil:
    section.add "application-id", valid_601434
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601435 = header.getOrDefault("X-Amz-Date")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Date", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Security-Token")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Security-Token", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_UpdateBaiduChannel_601431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of the Baidu channel for an application.
  ## 
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_UpdateBaiduChannel_601431; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Updates the settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601445 = newJObject()
  var body_601446 = newJObject()
  add(path_601445, "application-id", newJString(applicationId))
  if body != nil:
    body_601446 = body
  result = call_601444.call(path_601445, nil, nil, nil, body_601446)

var updateBaiduChannel* = Call_UpdateBaiduChannel_601431(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_601432, base: "/",
    url: url_UpdateBaiduChannel_601433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_601417 = ref object of OpenApiRestCall_600410
proc url_GetBaiduChannel_601419(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBaiduChannel_601418(path: JsonNode; query: JsonNode;
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
  var valid_601420 = path.getOrDefault("application-id")
  valid_601420 = validateParameter(valid_601420, JString, required = true,
                                 default = nil)
  if valid_601420 != nil:
    section.add "application-id", valid_601420
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601421 = header.getOrDefault("X-Amz-Date")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Date", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Security-Token")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Security-Token", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Content-Sha256", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Algorithm")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Algorithm", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Signature")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Signature", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-SignedHeaders", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Credential")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Credential", valid_601427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601428: Call_GetBaiduChannel_601417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ## 
  let valid = call_601428.validator(path, query, header, formData, body)
  let scheme = call_601428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601428.url(scheme.get, call_601428.host, call_601428.base,
                         call_601428.route, valid.getOrDefault("path"))
  result = hook(call_601428, url, valid)

proc call*(call_601429: Call_GetBaiduChannel_601417; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601430 = newJObject()
  add(path_601430, "application-id", newJString(applicationId))
  result = call_601429.call(path_601430, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_601417(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_601418, base: "/", url: url_GetBaiduChannel_601419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_601447 = ref object of OpenApiRestCall_600410
proc url_DeleteBaiduChannel_601449(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/baidu")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBaiduChannel_601448(path: JsonNode; query: JsonNode;
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
  var valid_601450 = path.getOrDefault("application-id")
  valid_601450 = validateParameter(valid_601450, JString, required = true,
                                 default = nil)
  if valid_601450 != nil:
    section.add "application-id", valid_601450
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601451 = header.getOrDefault("X-Amz-Date")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Date", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Security-Token")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Security-Token", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Content-Sha256", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Algorithm")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Algorithm", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Signature")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Signature", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-SignedHeaders", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Credential")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Credential", valid_601457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_DeleteBaiduChannel_601447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_DeleteBaiduChannel_601447; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601460 = newJObject()
  add(path_601460, "application-id", newJString(applicationId))
  result = call_601459.call(path_601460, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_601447(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_601448, base: "/",
    url: url_DeleteBaiduChannel_601449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_601476 = ref object of OpenApiRestCall_600410
proc url_UpdateCampaign_601478(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateCampaign_601477(path: JsonNode; query: JsonNode;
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
  var valid_601479 = path.getOrDefault("application-id")
  valid_601479 = validateParameter(valid_601479, JString, required = true,
                                 default = nil)
  if valid_601479 != nil:
    section.add "application-id", valid_601479
  var valid_601480 = path.getOrDefault("campaign-id")
  valid_601480 = validateParameter(valid_601480, JString, required = true,
                                 default = nil)
  if valid_601480 != nil:
    section.add "campaign-id", valid_601480
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601481 = header.getOrDefault("X-Amz-Date")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Date", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Security-Token")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Security-Token", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Content-Sha256", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Algorithm")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Algorithm", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Signature")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Signature", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-SignedHeaders", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Credential")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Credential", valid_601487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601489: Call_UpdateCampaign_601476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for a campaign.
  ## 
  let valid = call_601489.validator(path, query, header, formData, body)
  let scheme = call_601489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601489.url(scheme.get, call_601489.host, call_601489.base,
                         call_601489.route, valid.getOrDefault("path"))
  result = hook(call_601489, url, valid)

proc call*(call_601490: Call_UpdateCampaign_601476; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_601491 = newJObject()
  var body_601492 = newJObject()
  add(path_601491, "application-id", newJString(applicationId))
  if body != nil:
    body_601492 = body
  add(path_601491, "campaign-id", newJString(campaignId))
  result = call_601490.call(path_601491, nil, nil, nil, body_601492)

var updateCampaign* = Call_UpdateCampaign_601476(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_601477, base: "/", url: url_UpdateCampaign_601478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_601461 = ref object of OpenApiRestCall_600410
proc url_GetCampaign_601463(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaign_601462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601464 = path.getOrDefault("application-id")
  valid_601464 = validateParameter(valid_601464, JString, required = true,
                                 default = nil)
  if valid_601464 != nil:
    section.add "application-id", valid_601464
  var valid_601465 = path.getOrDefault("campaign-id")
  valid_601465 = validateParameter(valid_601465, JString, required = true,
                                 default = nil)
  if valid_601465 != nil:
    section.add "campaign-id", valid_601465
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601466 = header.getOrDefault("X-Amz-Date")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Date", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Security-Token")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Security-Token", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Content-Sha256", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Algorithm")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Algorithm", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Signature")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Signature", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-SignedHeaders", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Credential")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Credential", valid_601472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601473: Call_GetCampaign_601461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_601473.validator(path, query, header, formData, body)
  let scheme = call_601473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601473.url(scheme.get, call_601473.host, call_601473.base,
                         call_601473.route, valid.getOrDefault("path"))
  result = hook(call_601473, url, valid)

proc call*(call_601474: Call_GetCampaign_601461; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_601475 = newJObject()
  add(path_601475, "application-id", newJString(applicationId))
  add(path_601475, "campaign-id", newJString(campaignId))
  result = call_601474.call(path_601475, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_601461(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_601462,
                                        base: "/", url: url_GetCampaign_601463,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_601493 = ref object of OpenApiRestCall_600410
proc url_DeleteCampaign_601495(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteCampaign_601494(path: JsonNode; query: JsonNode;
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
  var valid_601496 = path.getOrDefault("application-id")
  valid_601496 = validateParameter(valid_601496, JString, required = true,
                                 default = nil)
  if valid_601496 != nil:
    section.add "application-id", valid_601496
  var valid_601497 = path.getOrDefault("campaign-id")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = nil)
  if valid_601497 != nil:
    section.add "campaign-id", valid_601497
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601498 = header.getOrDefault("X-Amz-Date")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Date", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Security-Token")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Security-Token", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601505: Call_DeleteCampaign_601493; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_601505.validator(path, query, header, formData, body)
  let scheme = call_601505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601505.url(scheme.get, call_601505.host, call_601505.base,
                         call_601505.route, valid.getOrDefault("path"))
  result = hook(call_601505, url, valid)

proc call*(call_601506: Call_DeleteCampaign_601493; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_601507 = newJObject()
  add(path_601507, "application-id", newJString(applicationId))
  add(path_601507, "campaign-id", newJString(campaignId))
  result = call_601506.call(path_601507, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_601493(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_601494, base: "/", url: url_DeleteCampaign_601495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_601522 = ref object of OpenApiRestCall_600410
proc url_UpdateEmailChannel_601524(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateEmailChannel_601523(path: JsonNode; query: JsonNode;
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
  var valid_601525 = path.getOrDefault("application-id")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = nil)
  if valid_601525 != nil:
    section.add "application-id", valid_601525
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601526 = header.getOrDefault("X-Amz-Date")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Date", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Security-Token")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Security-Token", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Content-Sha256", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Algorithm")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Algorithm", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Signature")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Signature", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-SignedHeaders", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Credential")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Credential", valid_601532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601534: Call_UpdateEmailChannel_601522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the email channel for an application.
  ## 
  let valid = call_601534.validator(path, query, header, formData, body)
  let scheme = call_601534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601534.url(scheme.get, call_601534.host, call_601534.base,
                         call_601534.route, valid.getOrDefault("path"))
  result = hook(call_601534, url, valid)

proc call*(call_601535: Call_UpdateEmailChannel_601522; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601536 = newJObject()
  var body_601537 = newJObject()
  add(path_601536, "application-id", newJString(applicationId))
  if body != nil:
    body_601537 = body
  result = call_601535.call(path_601536, nil, nil, nil, body_601537)

var updateEmailChannel* = Call_UpdateEmailChannel_601522(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_601523, base: "/",
    url: url_UpdateEmailChannel_601524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_601508 = ref object of OpenApiRestCall_600410
proc url_GetEmailChannel_601510(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetEmailChannel_601509(path: JsonNode; query: JsonNode;
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
  var valid_601511 = path.getOrDefault("application-id")
  valid_601511 = validateParameter(valid_601511, JString, required = true,
                                 default = nil)
  if valid_601511 != nil:
    section.add "application-id", valid_601511
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Content-Sha256", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Algorithm")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Algorithm", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Signature")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Signature", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-SignedHeaders", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Credential")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Credential", valid_601518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601519: Call_GetEmailChannel_601508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_601519.validator(path, query, header, formData, body)
  let scheme = call_601519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601519.url(scheme.get, call_601519.host, call_601519.base,
                         call_601519.route, valid.getOrDefault("path"))
  result = hook(call_601519, url, valid)

proc call*(call_601520: Call_GetEmailChannel_601508; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601521 = newJObject()
  add(path_601521, "application-id", newJString(applicationId))
  result = call_601520.call(path_601521, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_601508(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_601509, base: "/", url: url_GetEmailChannel_601510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_601538 = ref object of OpenApiRestCall_600410
proc url_DeleteEmailChannel_601540(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/email")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteEmailChannel_601539(path: JsonNode; query: JsonNode;
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
  var valid_601541 = path.getOrDefault("application-id")
  valid_601541 = validateParameter(valid_601541, JString, required = true,
                                 default = nil)
  if valid_601541 != nil:
    section.add "application-id", valid_601541
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Content-Sha256", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Algorithm")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Algorithm", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Signature")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Signature", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-SignedHeaders", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Credential")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Credential", valid_601548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601549: Call_DeleteEmailChannel_601538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601549.validator(path, query, header, formData, body)
  let scheme = call_601549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601549.url(scheme.get, call_601549.host, call_601549.base,
                         call_601549.route, valid.getOrDefault("path"))
  result = hook(call_601549, url, valid)

proc call*(call_601550: Call_DeleteEmailChannel_601538; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601551 = newJObject()
  add(path_601551, "application-id", newJString(applicationId))
  result = call_601550.call(path_601551, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_601538(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_601539, base: "/",
    url: url_DeleteEmailChannel_601540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_601567 = ref object of OpenApiRestCall_600410
proc url_UpdateEndpoint_601569(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateEndpoint_601568(path: JsonNode; query: JsonNode;
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
  var valid_601570 = path.getOrDefault("application-id")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = nil)
  if valid_601570 != nil:
    section.add "application-id", valid_601570
  var valid_601571 = path.getOrDefault("endpoint-id")
  valid_601571 = validateParameter(valid_601571, JString, required = true,
                                 default = nil)
  if valid_601571 != nil:
    section.add "endpoint-id", valid_601571
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Content-Sha256", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Algorithm")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Algorithm", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Signature")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Signature", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-SignedHeaders", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Credential")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Credential", valid_601578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601580: Call_UpdateEndpoint_601567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_601580.validator(path, query, header, formData, body)
  let scheme = call_601580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601580.url(scheme.get, call_601580.host, call_601580.base,
                         call_601580.route, valid.getOrDefault("path"))
  result = hook(call_601580, url, valid)

proc call*(call_601581: Call_UpdateEndpoint_601567; applicationId: string;
          endpointId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   body: JObject (required)
  var path_601582 = newJObject()
  var body_601583 = newJObject()
  add(path_601582, "application-id", newJString(applicationId))
  add(path_601582, "endpoint-id", newJString(endpointId))
  if body != nil:
    body_601583 = body
  result = call_601581.call(path_601582, nil, nil, nil, body_601583)

var updateEndpoint* = Call_UpdateEndpoint_601567(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_601568, base: "/", url: url_UpdateEndpoint_601569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_601552 = ref object of OpenApiRestCall_600410
proc url_GetEndpoint_601554(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetEndpoint_601553(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601555 = path.getOrDefault("application-id")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = nil)
  if valid_601555 != nil:
    section.add "application-id", valid_601555
  var valid_601556 = path.getOrDefault("endpoint-id")
  valid_601556 = validateParameter(valid_601556, JString, required = true,
                                 default = nil)
  if valid_601556 != nil:
    section.add "endpoint-id", valid_601556
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Content-Sha256", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Algorithm")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Algorithm", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Signature")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Signature", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-SignedHeaders", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Credential")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Credential", valid_601563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601564: Call_GetEndpoint_601552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_601564.validator(path, query, header, formData, body)
  let scheme = call_601564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601564.url(scheme.get, call_601564.host, call_601564.base,
                         call_601564.route, valid.getOrDefault("path"))
  result = hook(call_601564, url, valid)

proc call*(call_601565: Call_GetEndpoint_601552; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_601566 = newJObject()
  add(path_601566, "application-id", newJString(applicationId))
  add(path_601566, "endpoint-id", newJString(endpointId))
  result = call_601565.call(path_601566, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_601552(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_601553,
                                        base: "/", url: url_GetEndpoint_601554,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_601584 = ref object of OpenApiRestCall_600410
proc url_DeleteEndpoint_601586(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteEndpoint_601585(path: JsonNode; query: JsonNode;
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
  var valid_601587 = path.getOrDefault("application-id")
  valid_601587 = validateParameter(valid_601587, JString, required = true,
                                 default = nil)
  if valid_601587 != nil:
    section.add "application-id", valid_601587
  var valid_601588 = path.getOrDefault("endpoint-id")
  valid_601588 = validateParameter(valid_601588, JString, required = true,
                                 default = nil)
  if valid_601588 != nil:
    section.add "endpoint-id", valid_601588
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601589 = header.getOrDefault("X-Amz-Date")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Date", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Security-Token")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Security-Token", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Content-Sha256", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Algorithm")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Algorithm", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Signature")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Signature", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-SignedHeaders", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Credential")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Credential", valid_601595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_DeleteEndpoint_601584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_DeleteEndpoint_601584; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_601598 = newJObject()
  add(path_601598, "application-id", newJString(applicationId))
  add(path_601598, "endpoint-id", newJString(endpointId))
  result = call_601597.call(path_601598, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_601584(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_601585, base: "/", url: url_DeleteEndpoint_601586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_601613 = ref object of OpenApiRestCall_600410
proc url_PutEventStream_601615(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEventStream_601614(path: JsonNode; query: JsonNode;
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
  var valid_601616 = path.getOrDefault("application-id")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = nil)
  if valid_601616 != nil:
    section.add "application-id", valid_601616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Content-Sha256", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Algorithm")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Algorithm", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Signature")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Signature", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-SignedHeaders", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Credential")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Credential", valid_601623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601625: Call_PutEventStream_601613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_601625.validator(path, query, header, formData, body)
  let scheme = call_601625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601625.url(scheme.get, call_601625.host, call_601625.base,
                         call_601625.route, valid.getOrDefault("path"))
  result = hook(call_601625, url, valid)

proc call*(call_601626: Call_PutEventStream_601613; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601627 = newJObject()
  var body_601628 = newJObject()
  add(path_601627, "application-id", newJString(applicationId))
  if body != nil:
    body_601628 = body
  result = call_601626.call(path_601627, nil, nil, nil, body_601628)

var putEventStream* = Call_PutEventStream_601613(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_601614, base: "/", url: url_PutEventStream_601615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_601599 = ref object of OpenApiRestCall_600410
proc url_GetEventStream_601601(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetEventStream_601600(path: JsonNode; query: JsonNode;
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
  var valid_601602 = path.getOrDefault("application-id")
  valid_601602 = validateParameter(valid_601602, JString, required = true,
                                 default = nil)
  if valid_601602 != nil:
    section.add "application-id", valid_601602
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601603 = header.getOrDefault("X-Amz-Date")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Date", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Security-Token")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Security-Token", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601610: Call_GetEventStream_601599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_601610.validator(path, query, header, formData, body)
  let scheme = call_601610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601610.url(scheme.get, call_601610.host, call_601610.base,
                         call_601610.route, valid.getOrDefault("path"))
  result = hook(call_601610, url, valid)

proc call*(call_601611: Call_GetEventStream_601599; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601612 = newJObject()
  add(path_601612, "application-id", newJString(applicationId))
  result = call_601611.call(path_601612, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_601599(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_601600, base: "/", url: url_GetEventStream_601601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_601629 = ref object of OpenApiRestCall_600410
proc url_DeleteEventStream_601631(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/eventstream")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteEventStream_601630(path: JsonNode; query: JsonNode;
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
  var valid_601632 = path.getOrDefault("application-id")
  valid_601632 = validateParameter(valid_601632, JString, required = true,
                                 default = nil)
  if valid_601632 != nil:
    section.add "application-id", valid_601632
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601633 = header.getOrDefault("X-Amz-Date")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Date", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Security-Token")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Security-Token", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Content-Sha256", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Algorithm")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Algorithm", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Signature")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Signature", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-SignedHeaders", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Credential")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Credential", valid_601639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601640: Call_DeleteEventStream_601629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_601640.validator(path, query, header, formData, body)
  let scheme = call_601640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601640.url(scheme.get, call_601640.host, call_601640.base,
                         call_601640.route, valid.getOrDefault("path"))
  result = hook(call_601640, url, valid)

proc call*(call_601641: Call_DeleteEventStream_601629; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601642 = newJObject()
  add(path_601642, "application-id", newJString(applicationId))
  result = call_601641.call(path_601642, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_601629(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_601630, base: "/",
    url: url_DeleteEventStream_601631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_601657 = ref object of OpenApiRestCall_600410
proc url_UpdateGcmChannel_601659(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGcmChannel_601658(path: JsonNode; query: JsonNode;
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
  var valid_601660 = path.getOrDefault("application-id")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = nil)
  if valid_601660 != nil:
    section.add "application-id", valid_601660
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601661 = header.getOrDefault("X-Amz-Date")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Date", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Security-Token")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Security-Token", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Content-Sha256", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Algorithm")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Algorithm", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Signature")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Signature", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-SignedHeaders", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Credential")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Credential", valid_601667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_UpdateGcmChannel_601657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_UpdateGcmChannel_601657; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601671 = newJObject()
  var body_601672 = newJObject()
  add(path_601671, "application-id", newJString(applicationId))
  if body != nil:
    body_601672 = body
  result = call_601670.call(path_601671, nil, nil, nil, body_601672)

var updateGcmChannel* = Call_UpdateGcmChannel_601657(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_601658, base: "/",
    url: url_UpdateGcmChannel_601659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_601643 = ref object of OpenApiRestCall_600410
proc url_GetGcmChannel_601645(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGcmChannel_601644(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601646 = path.getOrDefault("application-id")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = nil)
  if valid_601646 != nil:
    section.add "application-id", valid_601646
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601654: Call_GetGcmChannel_601643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_601654.validator(path, query, header, formData, body)
  let scheme = call_601654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601654.url(scheme.get, call_601654.host, call_601654.base,
                         call_601654.route, valid.getOrDefault("path"))
  result = hook(call_601654, url, valid)

proc call*(call_601655: Call_GetGcmChannel_601643; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601656 = newJObject()
  add(path_601656, "application-id", newJString(applicationId))
  result = call_601655.call(path_601656, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_601643(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_601644, base: "/", url: url_GetGcmChannel_601645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_601673 = ref object of OpenApiRestCall_600410
proc url_DeleteGcmChannel_601675(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/gcm")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteGcmChannel_601674(path: JsonNode; query: JsonNode;
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
  var valid_601676 = path.getOrDefault("application-id")
  valid_601676 = validateParameter(valid_601676, JString, required = true,
                                 default = nil)
  if valid_601676 != nil:
    section.add "application-id", valid_601676
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601677 = header.getOrDefault("X-Amz-Date")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Date", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Security-Token")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Security-Token", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Content-Sha256", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Algorithm")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Algorithm", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Signature")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Signature", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-SignedHeaders", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Credential")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Credential", valid_601683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601684: Call_DeleteGcmChannel_601673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601684.validator(path, query, header, formData, body)
  let scheme = call_601684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601684.url(scheme.get, call_601684.host, call_601684.base,
                         call_601684.route, valid.getOrDefault("path"))
  result = hook(call_601684, url, valid)

proc call*(call_601685: Call_DeleteGcmChannel_601673; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601686 = newJObject()
  add(path_601686, "application-id", newJString(applicationId))
  result = call_601685.call(path_601686, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_601673(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_601674, base: "/",
    url: url_DeleteGcmChannel_601675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_601702 = ref object of OpenApiRestCall_600410
proc url_UpdateSegment_601704(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateSegment_601703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601705 = path.getOrDefault("segment-id")
  valid_601705 = validateParameter(valid_601705, JString, required = true,
                                 default = nil)
  if valid_601705 != nil:
    section.add "segment-id", valid_601705
  var valid_601706 = path.getOrDefault("application-id")
  valid_601706 = validateParameter(valid_601706, JString, required = true,
                                 default = nil)
  if valid_601706 != nil:
    section.add "application-id", valid_601706
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601707 = header.getOrDefault("X-Amz-Date")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Date", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Security-Token")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Security-Token", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Content-Sha256", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Algorithm")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Algorithm", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Signature")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Signature", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-SignedHeaders", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Credential")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Credential", valid_601713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601715: Call_UpdateSegment_601702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_601715.validator(path, query, header, formData, body)
  let scheme = call_601715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601715.url(scheme.get, call_601715.host, call_601715.base,
                         call_601715.route, valid.getOrDefault("path"))
  result = hook(call_601715, url, valid)

proc call*(call_601716: Call_UpdateSegment_601702; segmentId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601717 = newJObject()
  var body_601718 = newJObject()
  add(path_601717, "segment-id", newJString(segmentId))
  add(path_601717, "application-id", newJString(applicationId))
  if body != nil:
    body_601718 = body
  result = call_601716.call(path_601717, nil, nil, nil, body_601718)

var updateSegment* = Call_UpdateSegment_601702(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_601703, base: "/", url: url_UpdateSegment_601704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_601687 = ref object of OpenApiRestCall_600410
proc url_GetSegment_601689(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegment_601688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601690 = path.getOrDefault("segment-id")
  valid_601690 = validateParameter(valid_601690, JString, required = true,
                                 default = nil)
  if valid_601690 != nil:
    section.add "segment-id", valid_601690
  var valid_601691 = path.getOrDefault("application-id")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = nil)
  if valid_601691 != nil:
    section.add "application-id", valid_601691
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601692 = header.getOrDefault("X-Amz-Date")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Date", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Security-Token")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Security-Token", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Content-Sha256", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Algorithm")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Algorithm", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Signature")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Signature", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-SignedHeaders", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Credential")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Credential", valid_601698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601699: Call_GetSegment_601687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_601699.validator(path, query, header, formData, body)
  let scheme = call_601699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601699.url(scheme.get, call_601699.host, call_601699.base,
                         call_601699.route, valid.getOrDefault("path"))
  result = hook(call_601699, url, valid)

proc call*(call_601700: Call_GetSegment_601687; segmentId: string;
          applicationId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601701 = newJObject()
  add(path_601701, "segment-id", newJString(segmentId))
  add(path_601701, "application-id", newJString(applicationId))
  result = call_601700.call(path_601701, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_601687(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_601688,
                                      base: "/", url: url_GetSegment_601689,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_601719 = ref object of OpenApiRestCall_600410
proc url_DeleteSegment_601721(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteSegment_601720(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601722 = path.getOrDefault("segment-id")
  valid_601722 = validateParameter(valid_601722, JString, required = true,
                                 default = nil)
  if valid_601722 != nil:
    section.add "segment-id", valid_601722
  var valid_601723 = path.getOrDefault("application-id")
  valid_601723 = validateParameter(valid_601723, JString, required = true,
                                 default = nil)
  if valid_601723 != nil:
    section.add "application-id", valid_601723
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601724 = header.getOrDefault("X-Amz-Date")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Date", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Security-Token")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Security-Token", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Content-Sha256", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Algorithm")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Algorithm", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Signature")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Signature", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-SignedHeaders", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Credential")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Credential", valid_601730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_DeleteSegment_601719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"))
  result = hook(call_601731, url, valid)

proc call*(call_601732: Call_DeleteSegment_601719; segmentId: string;
          applicationId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601733 = newJObject()
  add(path_601733, "segment-id", newJString(segmentId))
  add(path_601733, "application-id", newJString(applicationId))
  result = call_601732.call(path_601733, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_601719(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_601720, base: "/", url: url_DeleteSegment_601721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_601748 = ref object of OpenApiRestCall_600410
proc url_UpdateSmsChannel_601750(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateSmsChannel_601749(path: JsonNode; query: JsonNode;
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
  var valid_601751 = path.getOrDefault("application-id")
  valid_601751 = validateParameter(valid_601751, JString, required = true,
                                 default = nil)
  if valid_601751 != nil:
    section.add "application-id", valid_601751
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601752 = header.getOrDefault("X-Amz-Date")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Date", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Security-Token")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Security-Token", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Content-Sha256", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-Algorithm")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Algorithm", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Signature")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Signature", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-SignedHeaders", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Credential")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Credential", valid_601758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601760: Call_UpdateSmsChannel_601748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_601760.validator(path, query, header, formData, body)
  let scheme = call_601760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601760.url(scheme.get, call_601760.host, call_601760.base,
                         call_601760.route, valid.getOrDefault("path"))
  result = hook(call_601760, url, valid)

proc call*(call_601761: Call_UpdateSmsChannel_601748; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601762 = newJObject()
  var body_601763 = newJObject()
  add(path_601762, "application-id", newJString(applicationId))
  if body != nil:
    body_601763 = body
  result = call_601761.call(path_601762, nil, nil, nil, body_601763)

var updateSmsChannel* = Call_UpdateSmsChannel_601748(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_601749, base: "/",
    url: url_UpdateSmsChannel_601750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_601734 = ref object of OpenApiRestCall_600410
proc url_GetSmsChannel_601736(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSmsChannel_601735(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601737 = path.getOrDefault("application-id")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "application-id", valid_601737
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601738 = header.getOrDefault("X-Amz-Date")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Date", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Security-Token")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Security-Token", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Content-Sha256", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Algorithm")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Algorithm", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Signature")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Signature", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-SignedHeaders", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Credential")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Credential", valid_601744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601745: Call_GetSmsChannel_601734; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_601745.validator(path, query, header, formData, body)
  let scheme = call_601745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601745.url(scheme.get, call_601745.host, call_601745.base,
                         call_601745.route, valid.getOrDefault("path"))
  result = hook(call_601745, url, valid)

proc call*(call_601746: Call_GetSmsChannel_601734; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601747 = newJObject()
  add(path_601747, "application-id", newJString(applicationId))
  result = call_601746.call(path_601747, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_601734(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_601735, base: "/", url: url_GetSmsChannel_601736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_601764 = ref object of OpenApiRestCall_600410
proc url_DeleteSmsChannel_601766(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/sms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteSmsChannel_601765(path: JsonNode; query: JsonNode;
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
  var valid_601767 = path.getOrDefault("application-id")
  valid_601767 = validateParameter(valid_601767, JString, required = true,
                                 default = nil)
  if valid_601767 != nil:
    section.add "application-id", valid_601767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601768 = header.getOrDefault("X-Amz-Date")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Date", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Security-Token")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Security-Token", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-Content-Sha256", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Algorithm")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Algorithm", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-Signature")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Signature", valid_601772
  var valid_601773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-SignedHeaders", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-Credential")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Credential", valid_601774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601775: Call_DeleteSmsChannel_601764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601775.validator(path, query, header, formData, body)
  let scheme = call_601775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601775.url(scheme.get, call_601775.host, call_601775.base,
                         call_601775.route, valid.getOrDefault("path"))
  result = hook(call_601775, url, valid)

proc call*(call_601776: Call_DeleteSmsChannel_601764; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601777 = newJObject()
  add(path_601777, "application-id", newJString(applicationId))
  result = call_601776.call(path_601777, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_601764(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_601765, base: "/",
    url: url_DeleteSmsChannel_601766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_601778 = ref object of OpenApiRestCall_600410
proc url_GetUserEndpoints_601780(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUserEndpoints_601779(path: JsonNode; query: JsonNode;
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
  var valid_601781 = path.getOrDefault("user-id")
  valid_601781 = validateParameter(valid_601781, JString, required = true,
                                 default = nil)
  if valid_601781 != nil:
    section.add "user-id", valid_601781
  var valid_601782 = path.getOrDefault("application-id")
  valid_601782 = validateParameter(valid_601782, JString, required = true,
                                 default = nil)
  if valid_601782 != nil:
    section.add "application-id", valid_601782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601783 = header.getOrDefault("X-Amz-Date")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Date", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Security-Token")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Security-Token", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Content-Sha256", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Algorithm")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Algorithm", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Signature")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Signature", valid_601787
  var valid_601788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-SignedHeaders", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Credential")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Credential", valid_601789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601790: Call_GetUserEndpoints_601778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_601790.validator(path, query, header, formData, body)
  let scheme = call_601790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601790.url(scheme.get, call_601790.host, call_601790.base,
                         call_601790.route, valid.getOrDefault("path"))
  result = hook(call_601790, url, valid)

proc call*(call_601791: Call_GetUserEndpoints_601778; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601792 = newJObject()
  add(path_601792, "user-id", newJString(userId))
  add(path_601792, "application-id", newJString(applicationId))
  result = call_601791.call(path_601792, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_601778(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_601779, base: "/",
    url: url_GetUserEndpoints_601780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_601793 = ref object of OpenApiRestCall_600410
proc url_DeleteUserEndpoints_601795(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUserEndpoints_601794(path: JsonNode; query: JsonNode;
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
  var valid_601796 = path.getOrDefault("user-id")
  valid_601796 = validateParameter(valid_601796, JString, required = true,
                                 default = nil)
  if valid_601796 != nil:
    section.add "user-id", valid_601796
  var valid_601797 = path.getOrDefault("application-id")
  valid_601797 = validateParameter(valid_601797, JString, required = true,
                                 default = nil)
  if valid_601797 != nil:
    section.add "application-id", valid_601797
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601798 = header.getOrDefault("X-Amz-Date")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Date", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Security-Token")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Security-Token", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Content-Sha256", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Algorithm")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Algorithm", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Signature")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Signature", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-SignedHeaders", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Credential")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Credential", valid_601804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601805: Call_DeleteUserEndpoints_601793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_601805.validator(path, query, header, formData, body)
  let scheme = call_601805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601805.url(scheme.get, call_601805.host, call_601805.base,
                         call_601805.route, valid.getOrDefault("path"))
  result = hook(call_601805, url, valid)

proc call*(call_601806: Call_DeleteUserEndpoints_601793; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601807 = newJObject()
  add(path_601807, "user-id", newJString(userId))
  add(path_601807, "application-id", newJString(applicationId))
  result = call_601806.call(path_601807, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_601793(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_601794, base: "/",
    url: url_DeleteUserEndpoints_601795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_601822 = ref object of OpenApiRestCall_600410
proc url_UpdateVoiceChannel_601824(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVoiceChannel_601823(path: JsonNode; query: JsonNode;
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
  var valid_601825 = path.getOrDefault("application-id")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = nil)
  if valid_601825 != nil:
    section.add "application-id", valid_601825
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601826 = header.getOrDefault("X-Amz-Date")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Date", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Security-Token")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Security-Token", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Content-Sha256", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Algorithm")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Algorithm", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Signature")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Signature", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-SignedHeaders", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Credential")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Credential", valid_601832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601834: Call_UpdateVoiceChannel_601822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_601834.validator(path, query, header, formData, body)
  let scheme = call_601834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601834.url(scheme.get, call_601834.host, call_601834.base,
                         call_601834.route, valid.getOrDefault("path"))
  result = hook(call_601834, url, valid)

proc call*(call_601835: Call_UpdateVoiceChannel_601822; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601836 = newJObject()
  var body_601837 = newJObject()
  add(path_601836, "application-id", newJString(applicationId))
  if body != nil:
    body_601837 = body
  result = call_601835.call(path_601836, nil, nil, nil, body_601837)

var updateVoiceChannel* = Call_UpdateVoiceChannel_601822(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_601823, base: "/",
    url: url_UpdateVoiceChannel_601824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_601808 = ref object of OpenApiRestCall_600410
proc url_GetVoiceChannel_601810(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVoiceChannel_601809(path: JsonNode; query: JsonNode;
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
  var valid_601811 = path.getOrDefault("application-id")
  valid_601811 = validateParameter(valid_601811, JString, required = true,
                                 default = nil)
  if valid_601811 != nil:
    section.add "application-id", valid_601811
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601812 = header.getOrDefault("X-Amz-Date")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Date", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Security-Token")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Security-Token", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Content-Sha256", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Algorithm")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Algorithm", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Signature")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Signature", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-SignedHeaders", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Credential")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Credential", valid_601818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601819: Call_GetVoiceChannel_601808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_601819.validator(path, query, header, formData, body)
  let scheme = call_601819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601819.url(scheme.get, call_601819.host, call_601819.base,
                         call_601819.route, valid.getOrDefault("path"))
  result = hook(call_601819, url, valid)

proc call*(call_601820: Call_GetVoiceChannel_601808; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601821 = newJObject()
  add(path_601821, "application-id", newJString(applicationId))
  result = call_601820.call(path_601821, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_601808(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_601809, base: "/", url: url_GetVoiceChannel_601810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_601838 = ref object of OpenApiRestCall_600410
proc url_DeleteVoiceChannel_601840(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels/voice")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVoiceChannel_601839(path: JsonNode; query: JsonNode;
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
  var valid_601841 = path.getOrDefault("application-id")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = nil)
  if valid_601841 != nil:
    section.add "application-id", valid_601841
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601842 = header.getOrDefault("X-Amz-Date")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Date", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Security-Token")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Security-Token", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Algorithm")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Algorithm", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601849: Call_DeleteVoiceChannel_601838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_601849.validator(path, query, header, formData, body)
  let scheme = call_601849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601849.url(scheme.get, call_601849.host, call_601849.base,
                         call_601849.route, valid.getOrDefault("path"))
  result = hook(call_601849, url, valid)

proc call*(call_601850: Call_DeleteVoiceChannel_601838; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601851 = newJObject()
  add(path_601851, "application-id", newJString(applicationId))
  result = call_601850.call(path_601851, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_601838(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_601839, base: "/",
    url: url_DeleteVoiceChannel_601840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_601852 = ref object of OpenApiRestCall_600410
proc url_GetApplicationDateRangeKpi_601854(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApplicationDateRangeKpi_601853(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("application-id")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "application-id", valid_601855
  var valid_601856 = path.getOrDefault("kpi-name")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "kpi-name", valid_601856
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
  var valid_601857 = query.getOrDefault("end-time")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "end-time", valid_601857
  var valid_601858 = query.getOrDefault("start-time")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "start-time", valid_601858
  var valid_601859 = query.getOrDefault("next-token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "next-token", valid_601859
  var valid_601860 = query.getOrDefault("page-size")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "page-size", valid_601860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601861 = header.getOrDefault("X-Amz-Date")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Date", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Content-Sha256", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Algorithm")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Algorithm", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Signature")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Signature", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-SignedHeaders", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Credential")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Credential", valid_601867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601868: Call_GetApplicationDateRangeKpi_601852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.</p>
  ## 
  let valid = call_601868.validator(path, query, header, formData, body)
  let scheme = call_601868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601868.url(scheme.get, call_601868.host, call_601868.base,
                         call_601868.route, valid.getOrDefault("path"))
  result = hook(call_601868, url, valid)

proc call*(call_601869: Call_GetApplicationDateRangeKpi_601852;
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
  var path_601870 = newJObject()
  var query_601871 = newJObject()
  add(query_601871, "end-time", newJString(endTime))
  add(path_601870, "application-id", newJString(applicationId))
  add(path_601870, "kpi-name", newJString(kpiName))
  add(query_601871, "start-time", newJString(startTime))
  add(query_601871, "next-token", newJString(nextToken))
  add(query_601871, "page-size", newJString(pageSize))
  result = call_601869.call(path_601870, query_601871, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_601852(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_601853, base: "/",
    url: url_GetApplicationDateRangeKpi_601854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_601886 = ref object of OpenApiRestCall_600410
proc url_UpdateApplicationSettings_601888(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApplicationSettings_601887(path: JsonNode; query: JsonNode;
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
  var valid_601889 = path.getOrDefault("application-id")
  valid_601889 = validateParameter(valid_601889, JString, required = true,
                                 default = nil)
  if valid_601889 != nil:
    section.add "application-id", valid_601889
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601890 = header.getOrDefault("X-Amz-Date")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Date", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Security-Token")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Security-Token", valid_601891
  var valid_601892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Content-Sha256", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-Algorithm")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-Algorithm", valid_601893
  var valid_601894 = header.getOrDefault("X-Amz-Signature")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "X-Amz-Signature", valid_601894
  var valid_601895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "X-Amz-SignedHeaders", valid_601895
  var valid_601896 = header.getOrDefault("X-Amz-Credential")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Credential", valid_601896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601898: Call_UpdateApplicationSettings_601886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_601898.validator(path, query, header, formData, body)
  let scheme = call_601898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601898.url(scheme.get, call_601898.host, call_601898.base,
                         call_601898.route, valid.getOrDefault("path"))
  result = hook(call_601898, url, valid)

proc call*(call_601899: Call_UpdateApplicationSettings_601886;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_601900 = newJObject()
  var body_601901 = newJObject()
  add(path_601900, "application-id", newJString(applicationId))
  if body != nil:
    body_601901 = body
  result = call_601899.call(path_601900, nil, nil, nil, body_601901)

var updateApplicationSettings* = Call_UpdateApplicationSettings_601886(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_601887, base: "/",
    url: url_UpdateApplicationSettings_601888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_601872 = ref object of OpenApiRestCall_600410
proc url_GetApplicationSettings_601874(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApplicationSettings_601873(path: JsonNode; query: JsonNode;
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
  var valid_601875 = path.getOrDefault("application-id")
  valid_601875 = validateParameter(valid_601875, JString, required = true,
                                 default = nil)
  if valid_601875 != nil:
    section.add "application-id", valid_601875
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601876 = header.getOrDefault("X-Amz-Date")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Date", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Security-Token")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Security-Token", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Content-Sha256", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Algorithm")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Algorithm", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-Signature")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-Signature", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-SignedHeaders", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Credential")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Credential", valid_601882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601883: Call_GetApplicationSettings_601872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_601883.validator(path, query, header, formData, body)
  let scheme = call_601883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601883.url(scheme.get, call_601883.host, call_601883.base,
                         call_601883.route, valid.getOrDefault("path"))
  result = hook(call_601883, url, valid)

proc call*(call_601884: Call_GetApplicationSettings_601872; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601885 = newJObject()
  add(path_601885, "application-id", newJString(applicationId))
  result = call_601884.call(path_601885, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_601872(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_601873, base: "/",
    url: url_GetApplicationSettings_601874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_601902 = ref object of OpenApiRestCall_600410
proc url_GetCampaignActivities_601904(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaignActivities_601903(path: JsonNode; query: JsonNode;
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
  var valid_601905 = path.getOrDefault("application-id")
  valid_601905 = validateParameter(valid_601905, JString, required = true,
                                 default = nil)
  if valid_601905 != nil:
    section.add "application-id", valid_601905
  var valid_601906 = path.getOrDefault("campaign-id")
  valid_601906 = validateParameter(valid_601906, JString, required = true,
                                 default = nil)
  if valid_601906 != nil:
    section.add "campaign-id", valid_601906
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601907 = query.getOrDefault("token")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "token", valid_601907
  var valid_601908 = query.getOrDefault("page-size")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "page-size", valid_601908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601909 = header.getOrDefault("X-Amz-Date")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Date", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Security-Token")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Security-Token", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Content-Sha256", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Algorithm")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Algorithm", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Signature")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Signature", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-SignedHeaders", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Credential")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Credential", valid_601915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601916: Call_GetCampaignActivities_601902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the activity performed by a campaign.
  ## 
  let valid = call_601916.validator(path, query, header, formData, body)
  let scheme = call_601916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601916.url(scheme.get, call_601916.host, call_601916.base,
                         call_601916.route, valid.getOrDefault("path"))
  result = hook(call_601916, url, valid)

proc call*(call_601917: Call_GetCampaignActivities_601902; applicationId: string;
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
  var path_601918 = newJObject()
  var query_601919 = newJObject()
  add(query_601919, "token", newJString(token))
  add(path_601918, "application-id", newJString(applicationId))
  add(path_601918, "campaign-id", newJString(campaignId))
  add(query_601919, "page-size", newJString(pageSize))
  result = call_601917.call(path_601918, query_601919, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_601902(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_601903, base: "/",
    url: url_GetCampaignActivities_601904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_601920 = ref object of OpenApiRestCall_600410
proc url_GetCampaignDateRangeKpi_601922(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaignDateRangeKpi_601921(path: JsonNode; query: JsonNode;
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
  var valid_601923 = path.getOrDefault("application-id")
  valid_601923 = validateParameter(valid_601923, JString, required = true,
                                 default = nil)
  if valid_601923 != nil:
    section.add "application-id", valid_601923
  var valid_601924 = path.getOrDefault("kpi-name")
  valid_601924 = validateParameter(valid_601924, JString, required = true,
                                 default = nil)
  if valid_601924 != nil:
    section.add "kpi-name", valid_601924
  var valid_601925 = path.getOrDefault("campaign-id")
  valid_601925 = validateParameter(valid_601925, JString, required = true,
                                 default = nil)
  if valid_601925 != nil:
    section.add "campaign-id", valid_601925
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
  var valid_601926 = query.getOrDefault("end-time")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "end-time", valid_601926
  var valid_601927 = query.getOrDefault("start-time")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "start-time", valid_601927
  var valid_601928 = query.getOrDefault("next-token")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "next-token", valid_601928
  var valid_601929 = query.getOrDefault("page-size")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "page-size", valid_601929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601930 = header.getOrDefault("X-Amz-Date")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Date", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Security-Token")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Security-Token", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Content-Sha256", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-Algorithm")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Algorithm", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Signature")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Signature", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-SignedHeaders", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Credential")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Credential", valid_601936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601937: Call_GetCampaignDateRangeKpi_601920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.</p>
  ## 
  let valid = call_601937.validator(path, query, header, formData, body)
  let scheme = call_601937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601937.url(scheme.get, call_601937.host, call_601937.base,
                         call_601937.route, valid.getOrDefault("path"))
  result = hook(call_601937, url, valid)

proc call*(call_601938: Call_GetCampaignDateRangeKpi_601920; applicationId: string;
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
  var path_601939 = newJObject()
  var query_601940 = newJObject()
  add(query_601940, "end-time", newJString(endTime))
  add(path_601939, "application-id", newJString(applicationId))
  add(path_601939, "kpi-name", newJString(kpiName))
  add(query_601940, "start-time", newJString(startTime))
  add(query_601940, "next-token", newJString(nextToken))
  add(path_601939, "campaign-id", newJString(campaignId))
  add(query_601940, "page-size", newJString(pageSize))
  result = call_601938.call(path_601939, query_601940, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_601920(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_601921, base: "/",
    url: url_GetCampaignDateRangeKpi_601922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_601941 = ref object of OpenApiRestCall_600410
proc url_GetCampaignVersion_601943(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaignVersion_601942(path: JsonNode; query: JsonNode;
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
  var valid_601944 = path.getOrDefault("version")
  valid_601944 = validateParameter(valid_601944, JString, required = true,
                                 default = nil)
  if valid_601944 != nil:
    section.add "version", valid_601944
  var valid_601945 = path.getOrDefault("application-id")
  valid_601945 = validateParameter(valid_601945, JString, required = true,
                                 default = nil)
  if valid_601945 != nil:
    section.add "application-id", valid_601945
  var valid_601946 = path.getOrDefault("campaign-id")
  valid_601946 = validateParameter(valid_601946, JString, required = true,
                                 default = nil)
  if valid_601946 != nil:
    section.add "campaign-id", valid_601946
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601947 = header.getOrDefault("X-Amz-Date")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Date", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Security-Token")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Security-Token", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Content-Sha256", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Algorithm")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Algorithm", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Signature")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Signature", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-SignedHeaders", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Credential")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Credential", valid_601953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601954: Call_GetCampaignVersion_601941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_601954.validator(path, query, header, formData, body)
  let scheme = call_601954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601954.url(scheme.get, call_601954.host, call_601954.base,
                         call_601954.route, valid.getOrDefault("path"))
  result = hook(call_601954, url, valid)

proc call*(call_601955: Call_GetCampaignVersion_601941; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_601956 = newJObject()
  add(path_601956, "version", newJString(version))
  add(path_601956, "application-id", newJString(applicationId))
  add(path_601956, "campaign-id", newJString(campaignId))
  result = call_601955.call(path_601956, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_601941(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_601942, base: "/",
    url: url_GetCampaignVersion_601943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_601957 = ref object of OpenApiRestCall_600410
proc url_GetCampaignVersions_601959(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCampaignVersions_601958(path: JsonNode; query: JsonNode;
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
  var valid_601960 = path.getOrDefault("application-id")
  valid_601960 = validateParameter(valid_601960, JString, required = true,
                                 default = nil)
  if valid_601960 != nil:
    section.add "application-id", valid_601960
  var valid_601961 = path.getOrDefault("campaign-id")
  valid_601961 = validateParameter(valid_601961, JString, required = true,
                                 default = nil)
  if valid_601961 != nil:
    section.add "campaign-id", valid_601961
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_601962 = query.getOrDefault("token")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "token", valid_601962
  var valid_601963 = query.getOrDefault("page-size")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "page-size", valid_601963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601964 = header.getOrDefault("X-Amz-Date")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Date", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Security-Token")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Security-Token", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Content-Sha256", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Algorithm")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Algorithm", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Signature")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Signature", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-SignedHeaders", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Credential")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Credential", valid_601970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601971: Call_GetCampaignVersions_601957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ## 
  let valid = call_601971.validator(path, query, header, formData, body)
  let scheme = call_601971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601971.url(scheme.get, call_601971.host, call_601971.base,
                         call_601971.route, valid.getOrDefault("path"))
  result = hook(call_601971, url, valid)

proc call*(call_601972: Call_GetCampaignVersions_601957; applicationId: string;
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
  var path_601973 = newJObject()
  var query_601974 = newJObject()
  add(query_601974, "token", newJString(token))
  add(path_601973, "application-id", newJString(applicationId))
  add(path_601973, "campaign-id", newJString(campaignId))
  add(query_601974, "page-size", newJString(pageSize))
  result = call_601972.call(path_601973, query_601974, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_601957(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_601958, base: "/",
    url: url_GetCampaignVersions_601959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_601975 = ref object of OpenApiRestCall_600410
proc url_GetChannels_601977(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/channels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetChannels_601976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601978 = path.getOrDefault("application-id")
  valid_601978 = validateParameter(valid_601978, JString, required = true,
                                 default = nil)
  if valid_601978 != nil:
    section.add "application-id", valid_601978
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601979 = header.getOrDefault("X-Amz-Date")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Date", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Security-Token")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Security-Token", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Content-Sha256", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Algorithm")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Algorithm", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Signature")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Signature", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-SignedHeaders", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Credential")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Credential", valid_601985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_GetChannels_601975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"))
  result = hook(call_601986, url, valid)

proc call*(call_601987: Call_GetChannels_601975; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_601988 = newJObject()
  add(path_601988, "application-id", newJString(applicationId))
  result = call_601987.call(path_601988, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_601975(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_601976,
                                        base: "/", url: url_GetChannels_601977,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_601989 = ref object of OpenApiRestCall_600410
proc url_GetExportJob_601991(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetExportJob_601990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601992 = path.getOrDefault("application-id")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = nil)
  if valid_601992 != nil:
    section.add "application-id", valid_601992
  var valid_601993 = path.getOrDefault("job-id")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = nil)
  if valid_601993 != nil:
    section.add "job-id", valid_601993
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601994 = header.getOrDefault("X-Amz-Date")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Date", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Content-Sha256", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Algorithm")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Algorithm", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Signature")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Signature", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-SignedHeaders", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602001: Call_GetExportJob_601989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_602001.validator(path, query, header, formData, body)
  let scheme = call_602001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602001.url(scheme.get, call_602001.host, call_602001.base,
                         call_602001.route, valid.getOrDefault("path"))
  result = hook(call_602001, url, valid)

proc call*(call_602002: Call_GetExportJob_601989; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_602003 = newJObject()
  add(path_602003, "application-id", newJString(applicationId))
  add(path_602003, "job-id", newJString(jobId))
  result = call_602002.call(path_602003, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_601989(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_601990, base: "/", url: url_GetExportJob_601991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_602004 = ref object of OpenApiRestCall_600410
proc url_GetImportJob_602006(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetImportJob_602005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602007 = path.getOrDefault("application-id")
  valid_602007 = validateParameter(valid_602007, JString, required = true,
                                 default = nil)
  if valid_602007 != nil:
    section.add "application-id", valid_602007
  var valid_602008 = path.getOrDefault("job-id")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = nil)
  if valid_602008 != nil:
    section.add "job-id", valid_602008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Content-Sha256", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Credential")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Credential", valid_602015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_GetImportJob_602004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"))
  result = hook(call_602016, url, valid)

proc call*(call_602017: Call_GetImportJob_602004; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_602018 = newJObject()
  add(path_602018, "application-id", newJString(applicationId))
  add(path_602018, "job-id", newJString(jobId))
  result = call_602017.call(path_602018, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_602004(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_602005, base: "/", url: url_GetImportJob_602006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_602019 = ref object of OpenApiRestCall_600410
proc url_GetSegmentExportJobs_602021(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegmentExportJobs_602020(path: JsonNode; query: JsonNode;
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
  var valid_602022 = path.getOrDefault("segment-id")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "segment-id", valid_602022
  var valid_602023 = path.getOrDefault("application-id")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = nil)
  if valid_602023 != nil:
    section.add "application-id", valid_602023
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_602024 = query.getOrDefault("token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "token", valid_602024
  var valid_602025 = query.getOrDefault("page-size")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "page-size", valid_602025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-SignedHeaders", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Credential")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Credential", valid_602032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602033: Call_GetSegmentExportJobs_602019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_602033.validator(path, query, header, formData, body)
  let scheme = call_602033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602033.url(scheme.get, call_602033.host, call_602033.base,
                         call_602033.route, valid.getOrDefault("path"))
  result = hook(call_602033, url, valid)

proc call*(call_602034: Call_GetSegmentExportJobs_602019; segmentId: string;
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
  var path_602035 = newJObject()
  var query_602036 = newJObject()
  add(query_602036, "token", newJString(token))
  add(path_602035, "segment-id", newJString(segmentId))
  add(path_602035, "application-id", newJString(applicationId))
  add(query_602036, "page-size", newJString(pageSize))
  result = call_602034.call(path_602035, query_602036, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_602019(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_602020, base: "/",
    url: url_GetSegmentExportJobs_602021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_602037 = ref object of OpenApiRestCall_600410
proc url_GetSegmentImportJobs_602039(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegmentImportJobs_602038(path: JsonNode; query: JsonNode;
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
  var valid_602040 = path.getOrDefault("segment-id")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = nil)
  if valid_602040 != nil:
    section.add "segment-id", valid_602040
  var valid_602041 = path.getOrDefault("application-id")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = nil)
  if valid_602041 != nil:
    section.add "application-id", valid_602041
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_602042 = query.getOrDefault("token")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "token", valid_602042
  var valid_602043 = query.getOrDefault("page-size")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "page-size", valid_602043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602044 = header.getOrDefault("X-Amz-Date")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Date", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Algorithm")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Algorithm", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-SignedHeaders", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602051: Call_GetSegmentImportJobs_602037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_602051.validator(path, query, header, formData, body)
  let scheme = call_602051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602051.url(scheme.get, call_602051.host, call_602051.base,
                         call_602051.route, valid.getOrDefault("path"))
  result = hook(call_602051, url, valid)

proc call*(call_602052: Call_GetSegmentImportJobs_602037; segmentId: string;
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
  var path_602053 = newJObject()
  var query_602054 = newJObject()
  add(query_602054, "token", newJString(token))
  add(path_602053, "segment-id", newJString(segmentId))
  add(path_602053, "application-id", newJString(applicationId))
  add(query_602054, "page-size", newJString(pageSize))
  result = call_602052.call(path_602053, query_602054, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_602037(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_602038, base: "/",
    url: url_GetSegmentImportJobs_602039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_602055 = ref object of OpenApiRestCall_600410
proc url_GetSegmentVersion_602057(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegmentVersion_602056(path: JsonNode; query: JsonNode;
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
  var valid_602058 = path.getOrDefault("segment-id")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = nil)
  if valid_602058 != nil:
    section.add "segment-id", valid_602058
  var valid_602059 = path.getOrDefault("version")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = nil)
  if valid_602059 != nil:
    section.add "version", valid_602059
  var valid_602060 = path.getOrDefault("application-id")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = nil)
  if valid_602060 != nil:
    section.add "application-id", valid_602060
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602061 = header.getOrDefault("X-Amz-Date")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Date", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Security-Token")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Security-Token", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Content-Sha256", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Algorithm")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Algorithm", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Signature")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Signature", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Credential")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Credential", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_GetSegmentVersion_602055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"))
  result = hook(call_602068, url, valid)

proc call*(call_602069: Call_GetSegmentVersion_602055; segmentId: string;
          version: string; applicationId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_602070 = newJObject()
  add(path_602070, "segment-id", newJString(segmentId))
  add(path_602070, "version", newJString(version))
  add(path_602070, "application-id", newJString(applicationId))
  result = call_602069.call(path_602070, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_602055(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_602056, base: "/",
    url: url_GetSegmentVersion_602057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_602071 = ref object of OpenApiRestCall_600410
proc url_GetSegmentVersions_602073(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSegmentVersions_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = path.getOrDefault("segment-id")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = nil)
  if valid_602074 != nil:
    section.add "segment-id", valid_602074
  var valid_602075 = path.getOrDefault("application-id")
  valid_602075 = validateParameter(valid_602075, JString, required = true,
                                 default = nil)
  if valid_602075 != nil:
    section.add "application-id", valid_602075
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_602076 = query.getOrDefault("token")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "token", valid_602076
  var valid_602077 = query.getOrDefault("page-size")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "page-size", valid_602077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Content-Sha256", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Signature")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Signature", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-SignedHeaders", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Credential")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Credential", valid_602084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602085: Call_GetSegmentVersions_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_602085.validator(path, query, header, formData, body)
  let scheme = call_602085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602085.url(scheme.get, call_602085.host, call_602085.base,
                         call_602085.route, valid.getOrDefault("path"))
  result = hook(call_602085, url, valid)

proc call*(call_602086: Call_GetSegmentVersions_602071; segmentId: string;
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
  var path_602087 = newJObject()
  var query_602088 = newJObject()
  add(query_602088, "token", newJString(token))
  add(path_602087, "segment-id", newJString(segmentId))
  add(path_602087, "application-id", newJString(applicationId))
  add(query_602088, "page-size", newJString(pageSize))
  result = call_602086.call(path_602087, query_602088, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_602071(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_602072, base: "/",
    url: url_GetSegmentVersions_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602103 = ref object of OpenApiRestCall_600410
proc url_TagResource_602105(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_602104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602106 = path.getOrDefault("resource-arn")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = nil)
  if valid_602106 != nil:
    section.add "resource-arn", valid_602106
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Security-Token")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Security-Token", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Signature")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Signature", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Credential")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Credential", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_TagResource_602103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"))
  result = hook(call_602115, url, valid)

proc call*(call_602116: Call_TagResource_602103; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  ##   body: JObject (required)
  var path_602117 = newJObject()
  var body_602118 = newJObject()
  add(path_602117, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602118 = body
  result = call_602116.call(path_602117, nil, nil, nil, body_602118)

var tagResource* = Call_TagResource_602103(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_602104,
                                        base: "/", url: url_TagResource_602105,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602089 = ref object of OpenApiRestCall_600410
proc url_ListTagsForResource_602091(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_602090(path: JsonNode; query: JsonNode;
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
  var valid_602092 = path.getOrDefault("resource-arn")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = nil)
  if valid_602092 != nil:
    section.add "resource-arn", valid_602092
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Content-Sha256", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Signature")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Signature", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-SignedHeaders", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Credential")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Credential", valid_602099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_ListTagsForResource_602089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ## 
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"))
  result = hook(call_602100, url, valid)

proc call*(call_602101: Call_ListTagsForResource_602089; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_602102 = newJObject()
  add(path_602102, "resource-arn", newJString(resourceArn))
  result = call_602101.call(path_602102, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602089(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_602090, base: "/",
    url: url_ListTagsForResource_602091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_602119 = ref object of OpenApiRestCall_600410
proc url_PhoneNumberValidate_602121(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PhoneNumberValidate_602120(path: JsonNode; query: JsonNode;
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
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Signature")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Signature", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Credential")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Credential", valid_602128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602130: Call_PhoneNumberValidate_602119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_602130.validator(path, query, header, formData, body)
  let scheme = call_602130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602130.url(scheme.get, call_602130.host, call_602130.base,
                         call_602130.route, valid.getOrDefault("path"))
  result = hook(call_602130, url, valid)

proc call*(call_602131: Call_PhoneNumberValidate_602119; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_602132 = newJObject()
  if body != nil:
    body_602132 = body
  result = call_602131.call(nil, nil, nil, nil, body_602132)

var phoneNumberValidate* = Call_PhoneNumberValidate_602119(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_602120, base: "/",
    url: url_PhoneNumberValidate_602121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_602133 = ref object of OpenApiRestCall_600410
proc url_PutEvents_602135(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEvents_602134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602136 = path.getOrDefault("application-id")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = nil)
  if valid_602136 != nil:
    section.add "application-id", valid_602136
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Security-Token")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Security-Token", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Content-Sha256", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-SignedHeaders", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Credential")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Credential", valid_602143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602145: Call_PutEvents_602133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_602145.validator(path, query, header, formData, body)
  let scheme = call_602145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602145.url(scheme.get, call_602145.host, call_602145.base,
                         call_602145.route, valid.getOrDefault("path"))
  result = hook(call_602145, url, valid)

proc call*(call_602146: Call_PutEvents_602133; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602147 = newJObject()
  var body_602148 = newJObject()
  add(path_602147, "application-id", newJString(applicationId))
  if body != nil:
    body_602148 = body
  result = call_602146.call(path_602147, nil, nil, nil, body_602148)

var putEvents* = Call_PutEvents_602133(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_602134,
                                    base: "/", url: url_PutEvents_602135,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_602149 = ref object of OpenApiRestCall_600410
proc url_RemoveAttributes_602151(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RemoveAttributes_602150(path: JsonNode; query: JsonNode;
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
  var valid_602152 = path.getOrDefault("attribute-type")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = nil)
  if valid_602152 != nil:
    section.add "attribute-type", valid_602152
  var valid_602153 = path.getOrDefault("application-id")
  valid_602153 = validateParameter(valid_602153, JString, required = true,
                                 default = nil)
  if valid_602153 != nil:
    section.add "application-id", valid_602153
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602154 = header.getOrDefault("X-Amz-Date")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Date", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Security-Token")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Security-Token", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Content-Sha256", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Algorithm")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Algorithm", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-SignedHeaders", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Credential")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Credential", valid_602160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_RemoveAttributes_602149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"))
  result = hook(call_602162, url, valid)

proc call*(call_602163: Call_RemoveAttributes_602149; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-custom-metrics - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602164 = newJObject()
  var body_602165 = newJObject()
  add(path_602164, "attribute-type", newJString(attributeType))
  add(path_602164, "application-id", newJString(applicationId))
  if body != nil:
    body_602165 = body
  result = call_602163.call(path_602164, nil, nil, nil, body_602165)

var removeAttributes* = Call_RemoveAttributes_602149(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_602150, base: "/",
    url: url_RemoveAttributes_602151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_602166 = ref object of OpenApiRestCall_600410
proc url_SendMessages_602168(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/messages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SendMessages_602167(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602169 = path.getOrDefault("application-id")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "application-id", valid_602169
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602170 = header.getOrDefault("X-Amz-Date")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Date", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Security-Token")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Security-Token", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Content-Sha256", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Algorithm")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Algorithm", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Credential")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Credential", valid_602176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602178: Call_SendMessages_602166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_602178.validator(path, query, header, formData, body)
  let scheme = call_602178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602178.url(scheme.get, call_602178.host, call_602178.base,
                         call_602178.route, valid.getOrDefault("path"))
  result = hook(call_602178, url, valid)

proc call*(call_602179: Call_SendMessages_602166; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602180 = newJObject()
  var body_602181 = newJObject()
  add(path_602180, "application-id", newJString(applicationId))
  if body != nil:
    body_602181 = body
  result = call_602179.call(path_602180, nil, nil, nil, body_602181)

var sendMessages* = Call_SendMessages_602166(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_602167,
    base: "/", url: url_SendMessages_602168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_602182 = ref object of OpenApiRestCall_600410
proc url_SendUsersMessages_602184(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/users-messages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SendUsersMessages_602183(path: JsonNode; query: JsonNode;
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
  var valid_602185 = path.getOrDefault("application-id")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = nil)
  if valid_602185 != nil:
    section.add "application-id", valid_602185
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602186 = header.getOrDefault("X-Amz-Date")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Date", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Security-Token")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Security-Token", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Content-Sha256", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Algorithm")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Algorithm", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Signature")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Signature", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-SignedHeaders", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Credential")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Credential", valid_602192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_SendUsersMessages_602182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"))
  result = hook(call_602194, url, valid)

proc call*(call_602195: Call_SendUsersMessages_602182; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602196 = newJObject()
  var body_602197 = newJObject()
  add(path_602196, "application-id", newJString(applicationId))
  if body != nil:
    body_602197 = body
  result = call_602195.call(path_602196, nil, nil, nil, body_602197)

var sendUsersMessages* = Call_SendUsersMessages_602182(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_602183, base: "/",
    url: url_SendUsersMessages_602184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602198 = ref object of OpenApiRestCall_600410
proc url_UntagResource_602200(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_602199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602201 = path.getOrDefault("resource-arn")
  valid_602201 = validateParameter(valid_602201, JString, required = true,
                                 default = nil)
  if valid_602201 != nil:
    section.add "resource-arn", valid_602201
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602202 = query.getOrDefault("tagKeys")
  valid_602202 = validateParameter(valid_602202, JArray, required = true, default = nil)
  if valid_602202 != nil:
    section.add "tagKeys", valid_602202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602203 = header.getOrDefault("X-Amz-Date")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Date", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Security-Token")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Security-Token", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Content-Sha256", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Algorithm")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Algorithm", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Signature")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Signature", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-SignedHeaders", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Credential")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Credential", valid_602209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602210: Call_UntagResource_602198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ## 
  let valid = call_602210.validator(path, query, header, formData, body)
  let scheme = call_602210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602210.url(scheme.get, call_602210.host, call_602210.base,
                         call_602210.route, valid.getOrDefault("path"))
  result = hook(call_602210, url, valid)

proc call*(call_602211: Call_UntagResource_602198; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_602212 = newJObject()
  var query_602213 = newJObject()
  if tagKeys != nil:
    query_602213.add "tagKeys", tagKeys
  add(path_602212, "resource-arn", newJString(resourceArn))
  result = call_602211.call(path_602212, query_602213, nil, nil, nil)

var untagResource* = Call_UntagResource_602198(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602199,
    base: "/", url: url_UntagResource_602200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_602214 = ref object of OpenApiRestCall_600410
proc url_UpdateEndpointsBatch_602216(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "application-id" in path, "`application-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apps/"),
               (kind: VariableSegment, value: "application-id"),
               (kind: ConstantSegment, value: "/endpoints")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateEndpointsBatch_602215(path: JsonNode; query: JsonNode;
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
  var valid_602217 = path.getOrDefault("application-id")
  valid_602217 = validateParameter(valid_602217, JString, required = true,
                                 default = nil)
  if valid_602217 != nil:
    section.add "application-id", valid_602217
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602218 = header.getOrDefault("X-Amz-Date")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Date", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Security-Token")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Security-Token", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Content-Sha256", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Algorithm")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Algorithm", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Signature")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Signature", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-SignedHeaders", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Credential")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Credential", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602226: Call_UpdateEndpointsBatch_602214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_602226.validator(path, query, header, formData, body)
  let scheme = call_602226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602226.url(scheme.get, call_602226.host, call_602226.base,
                         call_602226.route, valid.getOrDefault("path"))
  result = hook(call_602226, url, valid)

proc call*(call_602227: Call_UpdateEndpointsBatch_602214; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_602228 = newJObject()
  var body_602229 = newJObject()
  add(path_602228, "application-id", newJString(applicationId))
  if body != nil:
    body_602229 = body
  result = call_602227.call(path_602228, nil, nil, nil, body_602229)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_602214(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_602215, base: "/",
    url: url_UpdateEndpointsBatch_602216, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
