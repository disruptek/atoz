
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

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
  Call_CreateApp_773174 = ref object of OpenApiRestCall_772581
proc url_CreateApp_773176(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApp_773175(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773177 = header.getOrDefault("X-Amz-Date")
  valid_773177 = validateParameter(valid_773177, JString, required = false,
                                 default = nil)
  if valid_773177 != nil:
    section.add "X-Amz-Date", valid_773177
  var valid_773178 = header.getOrDefault("X-Amz-Security-Token")
  valid_773178 = validateParameter(valid_773178, JString, required = false,
                                 default = nil)
  if valid_773178 != nil:
    section.add "X-Amz-Security-Token", valid_773178
  var valid_773179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773179 = validateParameter(valid_773179, JString, required = false,
                                 default = nil)
  if valid_773179 != nil:
    section.add "X-Amz-Content-Sha256", valid_773179
  var valid_773180 = header.getOrDefault("X-Amz-Algorithm")
  valid_773180 = validateParameter(valid_773180, JString, required = false,
                                 default = nil)
  if valid_773180 != nil:
    section.add "X-Amz-Algorithm", valid_773180
  var valid_773181 = header.getOrDefault("X-Amz-Signature")
  valid_773181 = validateParameter(valid_773181, JString, required = false,
                                 default = nil)
  if valid_773181 != nil:
    section.add "X-Amz-Signature", valid_773181
  var valid_773182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773182 = validateParameter(valid_773182, JString, required = false,
                                 default = nil)
  if valid_773182 != nil:
    section.add "X-Amz-SignedHeaders", valid_773182
  var valid_773183 = header.getOrDefault("X-Amz-Credential")
  valid_773183 = validateParameter(valid_773183, JString, required = false,
                                 default = nil)
  if valid_773183 != nil:
    section.add "X-Amz-Credential", valid_773183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773185: Call_CreateApp_773174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_773185.validator(path, query, header, formData, body)
  let scheme = call_773185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773185.url(scheme.get, call_773185.host, call_773185.base,
                         call_773185.route, valid.getOrDefault("path"))
  result = hook(call_773185, url, valid)

proc call*(call_773186: Call_CreateApp_773174; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_773187 = newJObject()
  if body != nil:
    body_773187 = body
  result = call_773186.call(nil, nil, nil, nil, body_773187)

var createApp* = Call_CreateApp_773174(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_773175,
                                    base: "/", url: url_CreateApp_773176,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_772917 = ref object of OpenApiRestCall_772581
proc url_GetApps_772919(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApps_772918(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773031 = query.getOrDefault("token")
  valid_773031 = validateParameter(valid_773031, JString, required = false,
                                 default = nil)
  if valid_773031 != nil:
    section.add "token", valid_773031
  var valid_773032 = query.getOrDefault("page-size")
  valid_773032 = validateParameter(valid_773032, JString, required = false,
                                 default = nil)
  if valid_773032 != nil:
    section.add "page-size", valid_773032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773033 = header.getOrDefault("X-Amz-Date")
  valid_773033 = validateParameter(valid_773033, JString, required = false,
                                 default = nil)
  if valid_773033 != nil:
    section.add "X-Amz-Date", valid_773033
  var valid_773034 = header.getOrDefault("X-Amz-Security-Token")
  valid_773034 = validateParameter(valid_773034, JString, required = false,
                                 default = nil)
  if valid_773034 != nil:
    section.add "X-Amz-Security-Token", valid_773034
  var valid_773035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773035 = validateParameter(valid_773035, JString, required = false,
                                 default = nil)
  if valid_773035 != nil:
    section.add "X-Amz-Content-Sha256", valid_773035
  var valid_773036 = header.getOrDefault("X-Amz-Algorithm")
  valid_773036 = validateParameter(valid_773036, JString, required = false,
                                 default = nil)
  if valid_773036 != nil:
    section.add "X-Amz-Algorithm", valid_773036
  var valid_773037 = header.getOrDefault("X-Amz-Signature")
  valid_773037 = validateParameter(valid_773037, JString, required = false,
                                 default = nil)
  if valid_773037 != nil:
    section.add "X-Amz-Signature", valid_773037
  var valid_773038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-SignedHeaders", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Credential")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Credential", valid_773039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773062: Call_GetApps_772917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_773062.validator(path, query, header, formData, body)
  let scheme = call_773062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773062.url(scheme.get, call_773062.host, call_773062.base,
                         call_773062.route, valid.getOrDefault("path"))
  result = hook(call_773062, url, valid)

proc call*(call_773133: Call_GetApps_772917; token: string = ""; pageSize: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var query_773134 = newJObject()
  add(query_773134, "token", newJString(token))
  add(query_773134, "page-size", newJString(pageSize))
  result = call_773133.call(nil, query_773134, nil, nil, nil)

var getApps* = Call_GetApps_772917(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_772918, base: "/",
                                url: url_GetApps_772919,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_773219 = ref object of OpenApiRestCall_772581
proc url_CreateCampaign_773221(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_773220(path: JsonNode; query: JsonNode;
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
  var valid_773222 = path.getOrDefault("application-id")
  valid_773222 = validateParameter(valid_773222, JString, required = true,
                                 default = nil)
  if valid_773222 != nil:
    section.add "application-id", valid_773222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773223 = header.getOrDefault("X-Amz-Date")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Date", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Security-Token")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Security-Token", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Content-Sha256", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Algorithm")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Algorithm", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Signature")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Signature", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-SignedHeaders", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Credential")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Credential", valid_773229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773231: Call_CreateCampaign_773219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_773231.validator(path, query, header, formData, body)
  let scheme = call_773231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773231.url(scheme.get, call_773231.host, call_773231.base,
                         call_773231.route, valid.getOrDefault("path"))
  result = hook(call_773231, url, valid)

proc call*(call_773232: Call_CreateCampaign_773219; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773233 = newJObject()
  var body_773234 = newJObject()
  add(path_773233, "application-id", newJString(applicationId))
  if body != nil:
    body_773234 = body
  result = call_773232.call(path_773233, nil, nil, nil, body_773234)

var createCampaign* = Call_CreateCampaign_773219(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_773220, base: "/", url: url_CreateCampaign_773221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_773188 = ref object of OpenApiRestCall_772581
proc url_GetCampaigns_773190(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_773189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773205 = path.getOrDefault("application-id")
  valid_773205 = validateParameter(valid_773205, JString, required = true,
                                 default = nil)
  if valid_773205 != nil:
    section.add "application-id", valid_773205
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_773206 = query.getOrDefault("token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "token", valid_773206
  var valid_773207 = query.getOrDefault("page-size")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "page-size", valid_773207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773208 = header.getOrDefault("X-Amz-Date")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Date", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Security-Token")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Security-Token", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Content-Sha256", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Algorithm")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Algorithm", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Signature")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Signature", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-SignedHeaders", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Credential")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Credential", valid_773214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773215: Call_GetCampaigns_773188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_773215.validator(path, query, header, formData, body)
  let scheme = call_773215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773215.url(scheme.get, call_773215.host, call_773215.base,
                         call_773215.route, valid.getOrDefault("path"))
  result = hook(call_773215, url, valid)

proc call*(call_773216: Call_GetCampaigns_773188; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_773217 = newJObject()
  var query_773218 = newJObject()
  add(query_773218, "token", newJString(token))
  add(path_773217, "application-id", newJString(applicationId))
  add(query_773218, "page-size", newJString(pageSize))
  result = call_773216.call(path_773217, query_773218, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_773188(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_773189, base: "/", url: url_GetCampaigns_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_773252 = ref object of OpenApiRestCall_772581
proc url_CreateExportJob_773254(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_773253(path: JsonNode; query: JsonNode;
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
  var valid_773255 = path.getOrDefault("application-id")
  valid_773255 = validateParameter(valid_773255, JString, required = true,
                                 default = nil)
  if valid_773255 != nil:
    section.add "application-id", valid_773255
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773256 = header.getOrDefault("X-Amz-Date")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Date", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Security-Token")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Security-Token", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Content-Sha256", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Algorithm")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Algorithm", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Signature")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Signature", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-SignedHeaders", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Credential")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Credential", valid_773262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773264: Call_CreateExportJob_773252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new export job for an application.
  ## 
  let valid = call_773264.validator(path, query, header, formData, body)
  let scheme = call_773264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773264.url(scheme.get, call_773264.host, call_773264.base,
                         call_773264.route, valid.getOrDefault("path"))
  result = hook(call_773264, url, valid)

proc call*(call_773265: Call_CreateExportJob_773252; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates a new export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773266 = newJObject()
  var body_773267 = newJObject()
  add(path_773266, "application-id", newJString(applicationId))
  if body != nil:
    body_773267 = body
  result = call_773265.call(path_773266, nil, nil, nil, body_773267)

var createExportJob* = Call_CreateExportJob_773252(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_773253, base: "/", url: url_CreateExportJob_773254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_773235 = ref object of OpenApiRestCall_772581
proc url_GetExportJobs_773237(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_773236(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773238 = path.getOrDefault("application-id")
  valid_773238 = validateParameter(valid_773238, JString, required = true,
                                 default = nil)
  if valid_773238 != nil:
    section.add "application-id", valid_773238
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_773239 = query.getOrDefault("token")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "token", valid_773239
  var valid_773240 = query.getOrDefault("page-size")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "page-size", valid_773240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773241 = header.getOrDefault("X-Amz-Date")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Date", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Security-Token")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Security-Token", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Content-Sha256", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Algorithm")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Algorithm", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Signature")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Signature", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-SignedHeaders", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Credential")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Credential", valid_773247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773248: Call_GetExportJobs_773235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_773248.validator(path, query, header, formData, body)
  let scheme = call_773248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773248.url(scheme.get, call_773248.host, call_773248.base,
                         call_773248.route, valid.getOrDefault("path"))
  result = hook(call_773248, url, valid)

proc call*(call_773249: Call_GetExportJobs_773235; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_773250 = newJObject()
  var query_773251 = newJObject()
  add(query_773251, "token", newJString(token))
  add(path_773250, "application-id", newJString(applicationId))
  add(query_773251, "page-size", newJString(pageSize))
  result = call_773249.call(path_773250, query_773251, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_773235(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_773236, base: "/", url: url_GetExportJobs_773237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_773285 = ref object of OpenApiRestCall_772581
proc url_CreateImportJob_773287(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_773286(path: JsonNode; query: JsonNode;
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
  var valid_773288 = path.getOrDefault("application-id")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "application-id", valid_773288
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773289 = header.getOrDefault("X-Amz-Date")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Date", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Security-Token")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Security-Token", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Content-Sha256", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Algorithm")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Algorithm", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Signature")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Signature", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-SignedHeaders", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Credential")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Credential", valid_773295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_CreateImportJob_773285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new import job for an application.
  ## 
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_CreateImportJob_773285; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates a new import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773299 = newJObject()
  var body_773300 = newJObject()
  add(path_773299, "application-id", newJString(applicationId))
  if body != nil:
    body_773300 = body
  result = call_773298.call(path_773299, nil, nil, nil, body_773300)

var createImportJob* = Call_CreateImportJob_773285(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_773286, base: "/", url: url_CreateImportJob_773287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_773268 = ref object of OpenApiRestCall_772581
proc url_GetImportJobs_773270(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_773269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773271 = path.getOrDefault("application-id")
  valid_773271 = validateParameter(valid_773271, JString, required = true,
                                 default = nil)
  if valid_773271 != nil:
    section.add "application-id", valid_773271
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_773272 = query.getOrDefault("token")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "token", valid_773272
  var valid_773273 = query.getOrDefault("page-size")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "page-size", valid_773273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773274 = header.getOrDefault("X-Amz-Date")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Date", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Security-Token")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Security-Token", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Content-Sha256", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Algorithm")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Algorithm", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Signature")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Signature", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-SignedHeaders", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Credential")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Credential", valid_773280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773281: Call_GetImportJobs_773268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_773281.validator(path, query, header, formData, body)
  let scheme = call_773281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773281.url(scheme.get, call_773281.host, call_773281.base,
                         call_773281.route, valid.getOrDefault("path"))
  result = hook(call_773281, url, valid)

proc call*(call_773282: Call_GetImportJobs_773268; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_773283 = newJObject()
  var query_773284 = newJObject()
  add(query_773284, "token", newJString(token))
  add(path_773283, "application-id", newJString(applicationId))
  add(query_773284, "page-size", newJString(pageSize))
  result = call_773282.call(path_773283, query_773284, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_773268(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_773269, base: "/", url: url_GetImportJobs_773270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_773318 = ref object of OpenApiRestCall_772581
proc url_CreateSegment_773320(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_773319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773321 = path.getOrDefault("application-id")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = nil)
  if valid_773321 != nil:
    section.add "application-id", valid_773321
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773322 = header.getOrDefault("X-Amz-Date")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Date", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Security-Token")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Security-Token", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Content-Sha256", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Algorithm")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Algorithm", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Signature")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Signature", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-SignedHeaders", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Credential")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Credential", valid_773328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773330: Call_CreateSegment_773318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_773330.validator(path, query, header, formData, body)
  let scheme = call_773330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773330.url(scheme.get, call_773330.host, call_773330.base,
                         call_773330.route, valid.getOrDefault("path"))
  result = hook(call_773330, url, valid)

proc call*(call_773331: Call_CreateSegment_773318; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773332 = newJObject()
  var body_773333 = newJObject()
  add(path_773332, "application-id", newJString(applicationId))
  if body != nil:
    body_773333 = body
  result = call_773331.call(path_773332, nil, nil, nil, body_773333)

var createSegment* = Call_CreateSegment_773318(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_773319, base: "/", url: url_CreateSegment_773320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_773301 = ref object of OpenApiRestCall_772581
proc url_GetSegments_773303(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_773302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773304 = path.getOrDefault("application-id")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = nil)
  if valid_773304 != nil:
    section.add "application-id", valid_773304
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_773305 = query.getOrDefault("token")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "token", valid_773305
  var valid_773306 = query.getOrDefault("page-size")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "page-size", valid_773306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773307 = header.getOrDefault("X-Amz-Date")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Date", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Security-Token")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Security-Token", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Content-Sha256", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Algorithm")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Algorithm", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Signature")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Signature", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-SignedHeaders", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Credential")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Credential", valid_773313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773314: Call_GetSegments_773301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_773314.validator(path, query, header, formData, body)
  let scheme = call_773314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773314.url(scheme.get, call_773314.host, call_773314.base,
                         call_773314.route, valid.getOrDefault("path"))
  result = hook(call_773314, url, valid)

proc call*(call_773315: Call_GetSegments_773301; applicationId: string;
          token: string = ""; pageSize: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  var path_773316 = newJObject()
  var query_773317 = newJObject()
  add(query_773317, "token", newJString(token))
  add(path_773316, "application-id", newJString(applicationId))
  add(query_773317, "page-size", newJString(pageSize))
  result = call_773315.call(path_773316, query_773317, nil, nil, nil)

var getSegments* = Call_GetSegments_773301(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_773302,
                                        base: "/", url: url_GetSegments_773303,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_773348 = ref object of OpenApiRestCall_772581
proc url_UpdateAdmChannel_773350(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_773349(path: JsonNode; query: JsonNode;
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
  var valid_773351 = path.getOrDefault("application-id")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "application-id", valid_773351
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773352 = header.getOrDefault("X-Amz-Date")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Date", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Security-Token")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Security-Token", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Content-Sha256", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Algorithm")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Algorithm", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Signature")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Signature", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-SignedHeaders", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Credential")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Credential", valid_773358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773360: Call_UpdateAdmChannel_773348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ADM channel settings for an application.
  ## 
  let valid = call_773360.validator(path, query, header, formData, body)
  let scheme = call_773360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773360.url(scheme.get, call_773360.host, call_773360.base,
                         call_773360.route, valid.getOrDefault("path"))
  result = hook(call_773360, url, valid)

proc call*(call_773361: Call_UpdateAdmChannel_773348; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Updates the ADM channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773362 = newJObject()
  var body_773363 = newJObject()
  add(path_773362, "application-id", newJString(applicationId))
  if body != nil:
    body_773363 = body
  result = call_773361.call(path_773362, nil, nil, nil, body_773363)

var updateAdmChannel* = Call_UpdateAdmChannel_773348(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_773349, base: "/",
    url: url_UpdateAdmChannel_773350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_773334 = ref object of OpenApiRestCall_772581
proc url_GetAdmChannel_773336(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_773335(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773337 = path.getOrDefault("application-id")
  valid_773337 = validateParameter(valid_773337, JString, required = true,
                                 default = nil)
  if valid_773337 != nil:
    section.add "application-id", valid_773337
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773338 = header.getOrDefault("X-Amz-Date")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Date", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Security-Token")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Security-Token", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Content-Sha256", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Algorithm")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Algorithm", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Signature")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Signature", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-SignedHeaders", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Credential")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Credential", valid_773344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773345: Call_GetAdmChannel_773334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_773345.validator(path, query, header, formData, body)
  let scheme = call_773345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773345.url(scheme.get, call_773345.host, call_773345.base,
                         call_773345.route, valid.getOrDefault("path"))
  result = hook(call_773345, url, valid)

proc call*(call_773346: Call_GetAdmChannel_773334; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773347 = newJObject()
  add(path_773347, "application-id", newJString(applicationId))
  result = call_773346.call(path_773347, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_773334(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_773335, base: "/", url: url_GetAdmChannel_773336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_773364 = ref object of OpenApiRestCall_772581
proc url_DeleteAdmChannel_773366(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_773365(path: JsonNode; query: JsonNode;
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
  var valid_773367 = path.getOrDefault("application-id")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = nil)
  if valid_773367 != nil:
    section.add "application-id", valid_773367
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Content-Sha256", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773375: Call_DeleteAdmChannel_773364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773375.validator(path, query, header, formData, body)
  let scheme = call_773375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773375.url(scheme.get, call_773375.host, call_773375.base,
                         call_773375.route, valid.getOrDefault("path"))
  result = hook(call_773375, url, valid)

proc call*(call_773376: Call_DeleteAdmChannel_773364; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773377 = newJObject()
  add(path_773377, "application-id", newJString(applicationId))
  result = call_773376.call(path_773377, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_773364(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_773365, base: "/",
    url: url_DeleteAdmChannel_773366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_773392 = ref object of OpenApiRestCall_772581
proc url_UpdateApnsChannel_773394(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_773393(path: JsonNode; query: JsonNode;
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
  var valid_773395 = path.getOrDefault("application-id")
  valid_773395 = validateParameter(valid_773395, JString, required = true,
                                 default = nil)
  if valid_773395 != nil:
    section.add "application-id", valid_773395
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773396 = header.getOrDefault("X-Amz-Date")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Date", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Security-Token")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Security-Token", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Content-Sha256", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Algorithm")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Algorithm", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Signature")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Signature", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-SignedHeaders", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Credential")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Credential", valid_773402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773404: Call_UpdateApnsChannel_773392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs channel settings for an application.
  ## 
  let valid = call_773404.validator(path, query, header, formData, body)
  let scheme = call_773404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773404.url(scheme.get, call_773404.host, call_773404.base,
                         call_773404.route, valid.getOrDefault("path"))
  result = hook(call_773404, url, valid)

proc call*(call_773405: Call_UpdateApnsChannel_773392; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Updates the APNs channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773406 = newJObject()
  var body_773407 = newJObject()
  add(path_773406, "application-id", newJString(applicationId))
  if body != nil:
    body_773407 = body
  result = call_773405.call(path_773406, nil, nil, nil, body_773407)

var updateApnsChannel* = Call_UpdateApnsChannel_773392(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_773393, base: "/",
    url: url_UpdateApnsChannel_773394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_773378 = ref object of OpenApiRestCall_772581
proc url_GetApnsChannel_773380(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_773379(path: JsonNode; query: JsonNode;
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
  var valid_773381 = path.getOrDefault("application-id")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = nil)
  if valid_773381 != nil:
    section.add "application-id", valid_773381
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773382 = header.getOrDefault("X-Amz-Date")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Date", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Security-Token")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Security-Token", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Content-Sha256", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Algorithm")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Algorithm", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Signature")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Signature", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-SignedHeaders", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Credential")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Credential", valid_773388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773389: Call_GetApnsChannel_773378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_773389.validator(path, query, header, formData, body)
  let scheme = call_773389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773389.url(scheme.get, call_773389.host, call_773389.base,
                         call_773389.route, valid.getOrDefault("path"))
  result = hook(call_773389, url, valid)

proc call*(call_773390: Call_GetApnsChannel_773378; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773391 = newJObject()
  add(path_773391, "application-id", newJString(applicationId))
  result = call_773390.call(path_773391, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_773378(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_773379, base: "/", url: url_GetApnsChannel_773380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_773408 = ref object of OpenApiRestCall_772581
proc url_DeleteApnsChannel_773410(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_773409(path: JsonNode; query: JsonNode;
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
  var valid_773411 = path.getOrDefault("application-id")
  valid_773411 = validateParameter(valid_773411, JString, required = true,
                                 default = nil)
  if valid_773411 != nil:
    section.add "application-id", valid_773411
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773412 = header.getOrDefault("X-Amz-Date")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Date", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Security-Token")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Security-Token", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Content-Sha256", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Algorithm")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Algorithm", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Signature")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Signature", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-SignedHeaders", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Credential")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Credential", valid_773418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773419: Call_DeleteApnsChannel_773408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773419.validator(path, query, header, formData, body)
  let scheme = call_773419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773419.url(scheme.get, call_773419.host, call_773419.base,
                         call_773419.route, valid.getOrDefault("path"))
  result = hook(call_773419, url, valid)

proc call*(call_773420: Call_DeleteApnsChannel_773408; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773421 = newJObject()
  add(path_773421, "application-id", newJString(applicationId))
  result = call_773420.call(path_773421, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_773408(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_773409, base: "/",
    url: url_DeleteApnsChannel_773410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_773436 = ref object of OpenApiRestCall_772581
proc url_UpdateApnsSandboxChannel_773438(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_773437(path: JsonNode; query: JsonNode;
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
  var valid_773439 = path.getOrDefault("application-id")
  valid_773439 = validateParameter(valid_773439, JString, required = true,
                                 default = nil)
  if valid_773439 != nil:
    section.add "application-id", valid_773439
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773440 = header.getOrDefault("X-Amz-Date")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Date", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Security-Token")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Security-Token", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Content-Sha256", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Algorithm")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Algorithm", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Signature")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Signature", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-SignedHeaders", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Credential")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Credential", valid_773446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773448: Call_UpdateApnsSandboxChannel_773436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs sandbox channel settings for an application.
  ## 
  let valid = call_773448.validator(path, query, header, formData, body)
  let scheme = call_773448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773448.url(scheme.get, call_773448.host, call_773448.base,
                         call_773448.route, valid.getOrDefault("path"))
  result = hook(call_773448, url, valid)

proc call*(call_773449: Call_UpdateApnsSandboxChannel_773436;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Updates the APNs sandbox channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773450 = newJObject()
  var body_773451 = newJObject()
  add(path_773450, "application-id", newJString(applicationId))
  if body != nil:
    body_773451 = body
  result = call_773449.call(path_773450, nil, nil, nil, body_773451)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_773436(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_773437, base: "/",
    url: url_UpdateApnsSandboxChannel_773438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_773422 = ref object of OpenApiRestCall_772581
proc url_GetApnsSandboxChannel_773424(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_773423(path: JsonNode; query: JsonNode;
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
  var valid_773425 = path.getOrDefault("application-id")
  valid_773425 = validateParameter(valid_773425, JString, required = true,
                                 default = nil)
  if valid_773425 != nil:
    section.add "application-id", valid_773425
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773426 = header.getOrDefault("X-Amz-Date")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Date", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Security-Token")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Security-Token", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Content-Sha256", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Algorithm")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Algorithm", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Signature")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Signature", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-SignedHeaders", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Credential")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Credential", valid_773432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773433: Call_GetApnsSandboxChannel_773422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_773433.validator(path, query, header, formData, body)
  let scheme = call_773433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773433.url(scheme.get, call_773433.host, call_773433.base,
                         call_773433.route, valid.getOrDefault("path"))
  result = hook(call_773433, url, valid)

proc call*(call_773434: Call_GetApnsSandboxChannel_773422; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773435 = newJObject()
  add(path_773435, "application-id", newJString(applicationId))
  result = call_773434.call(path_773435, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_773422(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_773423, base: "/",
    url: url_GetApnsSandboxChannel_773424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_773452 = ref object of OpenApiRestCall_772581
proc url_DeleteApnsSandboxChannel_773454(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_773453(path: JsonNode; query: JsonNode;
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
  var valid_773455 = path.getOrDefault("application-id")
  valid_773455 = validateParameter(valid_773455, JString, required = true,
                                 default = nil)
  if valid_773455 != nil:
    section.add "application-id", valid_773455
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773456 = header.getOrDefault("X-Amz-Date")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Date", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Security-Token")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Security-Token", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Content-Sha256", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Algorithm")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Algorithm", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Signature")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Signature", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-SignedHeaders", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Credential")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Credential", valid_773462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773463: Call_DeleteApnsSandboxChannel_773452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773463.validator(path, query, header, formData, body)
  let scheme = call_773463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773463.url(scheme.get, call_773463.host, call_773463.base,
                         call_773463.route, valid.getOrDefault("path"))
  result = hook(call_773463, url, valid)

proc call*(call_773464: Call_DeleteApnsSandboxChannel_773452; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773465 = newJObject()
  add(path_773465, "application-id", newJString(applicationId))
  result = call_773464.call(path_773465, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_773452(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_773453, base: "/",
    url: url_DeleteApnsSandboxChannel_773454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_773480 = ref object of OpenApiRestCall_772581
proc url_UpdateApnsVoipChannel_773482(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_773481(path: JsonNode; query: JsonNode;
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
  var valid_773483 = path.getOrDefault("application-id")
  valid_773483 = validateParameter(valid_773483, JString, required = true,
                                 default = nil)
  if valid_773483 != nil:
    section.add "application-id", valid_773483
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773484 = header.getOrDefault("X-Amz-Date")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Date", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Security-Token")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Security-Token", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Content-Sha256", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Algorithm")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Algorithm", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Signature")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Signature", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-SignedHeaders", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Credential")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Credential", valid_773490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773492: Call_UpdateApnsVoipChannel_773480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the APNs VoIP channel settings for an application.
  ## 
  let valid = call_773492.validator(path, query, header, formData, body)
  let scheme = call_773492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773492.url(scheme.get, call_773492.host, call_773492.base,
                         call_773492.route, valid.getOrDefault("path"))
  result = hook(call_773492, url, valid)

proc call*(call_773493: Call_UpdateApnsVoipChannel_773480; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Updates the APNs VoIP channel settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773494 = newJObject()
  var body_773495 = newJObject()
  add(path_773494, "application-id", newJString(applicationId))
  if body != nil:
    body_773495 = body
  result = call_773493.call(path_773494, nil, nil, nil, body_773495)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_773480(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_773481, base: "/",
    url: url_UpdateApnsVoipChannel_773482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_773466 = ref object of OpenApiRestCall_772581
proc url_GetApnsVoipChannel_773468(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_773467(path: JsonNode; query: JsonNode;
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
  var valid_773469 = path.getOrDefault("application-id")
  valid_773469 = validateParameter(valid_773469, JString, required = true,
                                 default = nil)
  if valid_773469 != nil:
    section.add "application-id", valid_773469
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773470 = header.getOrDefault("X-Amz-Date")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Date", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Security-Token")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Security-Token", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Content-Sha256", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Algorithm")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Algorithm", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Signature")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Signature", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-SignedHeaders", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Credential")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Credential", valid_773476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773477: Call_GetApnsVoipChannel_773466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_773477.validator(path, query, header, formData, body)
  let scheme = call_773477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773477.url(scheme.get, call_773477.host, call_773477.base,
                         call_773477.route, valid.getOrDefault("path"))
  result = hook(call_773477, url, valid)

proc call*(call_773478: Call_GetApnsVoipChannel_773466; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773479 = newJObject()
  add(path_773479, "application-id", newJString(applicationId))
  result = call_773478.call(path_773479, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_773466(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_773467, base: "/",
    url: url_GetApnsVoipChannel_773468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_773496 = ref object of OpenApiRestCall_772581
proc url_DeleteApnsVoipChannel_773498(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_773497(path: JsonNode; query: JsonNode;
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
  var valid_773499 = path.getOrDefault("application-id")
  valid_773499 = validateParameter(valid_773499, JString, required = true,
                                 default = nil)
  if valid_773499 != nil:
    section.add "application-id", valid_773499
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773500 = header.getOrDefault("X-Amz-Date")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Date", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Security-Token")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Security-Token", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Content-Sha256", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Algorithm")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Algorithm", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Signature")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Signature", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-SignedHeaders", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Credential")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Credential", valid_773506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773507: Call_DeleteApnsVoipChannel_773496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773507.validator(path, query, header, formData, body)
  let scheme = call_773507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773507.url(scheme.get, call_773507.host, call_773507.base,
                         call_773507.route, valid.getOrDefault("path"))
  result = hook(call_773507, url, valid)

proc call*(call_773508: Call_DeleteApnsVoipChannel_773496; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773509 = newJObject()
  add(path_773509, "application-id", newJString(applicationId))
  result = call_773508.call(path_773509, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_773496(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_773497, base: "/",
    url: url_DeleteApnsVoipChannel_773498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_773524 = ref object of OpenApiRestCall_772581
proc url_UpdateApnsVoipSandboxChannel_773526(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_773525(path: JsonNode; query: JsonNode;
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
  var valid_773527 = path.getOrDefault("application-id")
  valid_773527 = validateParameter(valid_773527, JString, required = true,
                                 default = nil)
  if valid_773527 != nil:
    section.add "application-id", valid_773527
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773528 = header.getOrDefault("X-Amz-Date")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Date", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Security-Token")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Security-Token", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Content-Sha256", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Algorithm")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Algorithm", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Signature")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Signature", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-SignedHeaders", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Credential")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Credential", valid_773534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773536: Call_UpdateApnsVoipSandboxChannel_773524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_773536.validator(path, query, header, formData, body)
  let scheme = call_773536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773536.url(scheme.get, call_773536.host, call_773536.base,
                         call_773536.route, valid.getOrDefault("path"))
  result = hook(call_773536, url, valid)

proc call*(call_773537: Call_UpdateApnsVoipSandboxChannel_773524;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Updates the settings for the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773538 = newJObject()
  var body_773539 = newJObject()
  add(path_773538, "application-id", newJString(applicationId))
  if body != nil:
    body_773539 = body
  result = call_773537.call(path_773538, nil, nil, nil, body_773539)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_773524(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_773525, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_773526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_773510 = ref object of OpenApiRestCall_772581
proc url_GetApnsVoipSandboxChannel_773512(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_773511(path: JsonNode; query: JsonNode;
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
  var valid_773513 = path.getOrDefault("application-id")
  valid_773513 = validateParameter(valid_773513, JString, required = true,
                                 default = nil)
  if valid_773513 != nil:
    section.add "application-id", valid_773513
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773514 = header.getOrDefault("X-Amz-Date")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Date", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Security-Token")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Security-Token", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Content-Sha256", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Algorithm")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Algorithm", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Signature")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Signature", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-SignedHeaders", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Credential")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Credential", valid_773520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773521: Call_GetApnsVoipSandboxChannel_773510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_773521.validator(path, query, header, formData, body)
  let scheme = call_773521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773521.url(scheme.get, call_773521.host, call_773521.base,
                         call_773521.route, valid.getOrDefault("path"))
  result = hook(call_773521, url, valid)

proc call*(call_773522: Call_GetApnsVoipSandboxChannel_773510;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773523 = newJObject()
  add(path_773523, "application-id", newJString(applicationId))
  result = call_773522.call(path_773523, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_773510(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_773511, base: "/",
    url: url_GetApnsVoipSandboxChannel_773512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_773540 = ref object of OpenApiRestCall_772581
proc url_DeleteApnsVoipSandboxChannel_773542(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_773541(path: JsonNode; query: JsonNode;
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
  var valid_773543 = path.getOrDefault("application-id")
  valid_773543 = validateParameter(valid_773543, JString, required = true,
                                 default = nil)
  if valid_773543 != nil:
    section.add "application-id", valid_773543
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773544 = header.getOrDefault("X-Amz-Date")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Date", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Security-Token")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Security-Token", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Content-Sha256", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Algorithm")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Algorithm", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Signature")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Signature", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-SignedHeaders", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Credential")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Credential", valid_773550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_DeleteApnsVoipSandboxChannel_773540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_DeleteApnsVoipSandboxChannel_773540;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773553 = newJObject()
  add(path_773553, "application-id", newJString(applicationId))
  result = call_773552.call(path_773553, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_773540(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_773541, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_773542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_773554 = ref object of OpenApiRestCall_772581
proc url_GetApp_773556(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_773555(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773557 = path.getOrDefault("application-id")
  valid_773557 = validateParameter(valid_773557, JString, required = true,
                                 default = nil)
  if valid_773557 != nil:
    section.add "application-id", valid_773557
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773558 = header.getOrDefault("X-Amz-Date")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Date", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Security-Token")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Security-Token", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Content-Sha256", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Algorithm")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Algorithm", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Signature")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Signature", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-SignedHeaders", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Credential")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Credential", valid_773564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773565: Call_GetApp_773554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_773565.validator(path, query, header, formData, body)
  let scheme = call_773565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773565.url(scheme.get, call_773565.host, call_773565.base,
                         call_773565.route, valid.getOrDefault("path"))
  result = hook(call_773565, url, valid)

proc call*(call_773566: Call_GetApp_773554; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773567 = newJObject()
  add(path_773567, "application-id", newJString(applicationId))
  result = call_773566.call(path_773567, nil, nil, nil, nil)

var getApp* = Call_GetApp_773554(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_773555, base: "/",
                              url: url_GetApp_773556,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_773568 = ref object of OpenApiRestCall_772581
proc url_DeleteApp_773570(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_773569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773571 = path.getOrDefault("application-id")
  valid_773571 = validateParameter(valid_773571, JString, required = true,
                                 default = nil)
  if valid_773571 != nil:
    section.add "application-id", valid_773571
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773572 = header.getOrDefault("X-Amz-Date")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Date", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Security-Token")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Security-Token", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Content-Sha256", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Algorithm")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Algorithm", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Signature")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Signature", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-SignedHeaders", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Credential")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Credential", valid_773578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773579: Call_DeleteApp_773568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_773579.validator(path, query, header, formData, body)
  let scheme = call_773579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773579.url(scheme.get, call_773579.host, call_773579.base,
                         call_773579.route, valid.getOrDefault("path"))
  result = hook(call_773579, url, valid)

proc call*(call_773580: Call_DeleteApp_773568; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773581 = newJObject()
  add(path_773581, "application-id", newJString(applicationId))
  result = call_773580.call(path_773581, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_773568(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_773569,
                                    base: "/", url: url_DeleteApp_773570,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_773596 = ref object of OpenApiRestCall_772581
proc url_UpdateBaiduChannel_773598(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_773597(path: JsonNode; query: JsonNode;
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
  var valid_773599 = path.getOrDefault("application-id")
  valid_773599 = validateParameter(valid_773599, JString, required = true,
                                 default = nil)
  if valid_773599 != nil:
    section.add "application-id", valid_773599
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773600 = header.getOrDefault("X-Amz-Date")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Date", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Security-Token")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Security-Token", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Content-Sha256", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Algorithm")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Algorithm", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Signature")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Signature", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-SignedHeaders", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Credential")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Credential", valid_773606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773608: Call_UpdateBaiduChannel_773596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings of the Baidu channel for an application.
  ## 
  let valid = call_773608.validator(path, query, header, formData, body)
  let scheme = call_773608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773608.url(scheme.get, call_773608.host, call_773608.base,
                         call_773608.route, valid.getOrDefault("path"))
  result = hook(call_773608, url, valid)

proc call*(call_773609: Call_UpdateBaiduChannel_773596; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Updates the settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773610 = newJObject()
  var body_773611 = newJObject()
  add(path_773610, "application-id", newJString(applicationId))
  if body != nil:
    body_773611 = body
  result = call_773609.call(path_773610, nil, nil, nil, body_773611)

var updateBaiduChannel* = Call_UpdateBaiduChannel_773596(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_773597, base: "/",
    url: url_UpdateBaiduChannel_773598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_773582 = ref object of OpenApiRestCall_772581
proc url_GetBaiduChannel_773584(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_773583(path: JsonNode; query: JsonNode;
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
  var valid_773585 = path.getOrDefault("application-id")
  valid_773585 = validateParameter(valid_773585, JString, required = true,
                                 default = nil)
  if valid_773585 != nil:
    section.add "application-id", valid_773585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773586 = header.getOrDefault("X-Amz-Date")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Date", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Security-Token")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Security-Token", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Content-Sha256", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Algorithm")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Algorithm", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Signature")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Signature", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-SignedHeaders", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Credential")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Credential", valid_773592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_GetBaiduChannel_773582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_GetBaiduChannel_773582; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu Cloud Push channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773595 = newJObject()
  add(path_773595, "application-id", newJString(applicationId))
  result = call_773594.call(path_773595, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_773582(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_773583, base: "/", url: url_GetBaiduChannel_773584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_773612 = ref object of OpenApiRestCall_772581
proc url_DeleteBaiduChannel_773614(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_773613(path: JsonNode; query: JsonNode;
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
  var valid_773615 = path.getOrDefault("application-id")
  valid_773615 = validateParameter(valid_773615, JString, required = true,
                                 default = nil)
  if valid_773615 != nil:
    section.add "application-id", valid_773615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773616 = header.getOrDefault("X-Amz-Date")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Date", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Security-Token")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Security-Token", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Content-Sha256", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Algorithm")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Algorithm", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Signature")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Signature", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-SignedHeaders", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Credential")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Credential", valid_773622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_DeleteBaiduChannel_773612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_DeleteBaiduChannel_773612; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773625 = newJObject()
  add(path_773625, "application-id", newJString(applicationId))
  result = call_773624.call(path_773625, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_773612(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_773613, base: "/",
    url: url_DeleteBaiduChannel_773614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_773641 = ref object of OpenApiRestCall_772581
proc url_UpdateCampaign_773643(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_773642(path: JsonNode; query: JsonNode;
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
  var valid_773644 = path.getOrDefault("application-id")
  valid_773644 = validateParameter(valid_773644, JString, required = true,
                                 default = nil)
  if valid_773644 != nil:
    section.add "application-id", valid_773644
  var valid_773645 = path.getOrDefault("campaign-id")
  valid_773645 = validateParameter(valid_773645, JString, required = true,
                                 default = nil)
  if valid_773645 != nil:
    section.add "campaign-id", valid_773645
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773646 = header.getOrDefault("X-Amz-Date")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Date", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Security-Token")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Security-Token", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Content-Sha256", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Algorithm")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Algorithm", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Signature")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Signature", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-SignedHeaders", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Credential")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Credential", valid_773652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773654: Call_UpdateCampaign_773641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for a campaign.
  ## 
  let valid = call_773654.validator(path, query, header, formData, body)
  let scheme = call_773654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773654.url(scheme.get, call_773654.host, call_773654.base,
                         call_773654.route, valid.getOrDefault("path"))
  result = hook(call_773654, url, valid)

proc call*(call_773655: Call_UpdateCampaign_773641; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_773656 = newJObject()
  var body_773657 = newJObject()
  add(path_773656, "application-id", newJString(applicationId))
  if body != nil:
    body_773657 = body
  add(path_773656, "campaign-id", newJString(campaignId))
  result = call_773655.call(path_773656, nil, nil, nil, body_773657)

var updateCampaign* = Call_UpdateCampaign_773641(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_773642, base: "/", url: url_UpdateCampaign_773643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_773626 = ref object of OpenApiRestCall_772581
proc url_GetCampaign_773628(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_773627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773629 = path.getOrDefault("application-id")
  valid_773629 = validateParameter(valid_773629, JString, required = true,
                                 default = nil)
  if valid_773629 != nil:
    section.add "application-id", valid_773629
  var valid_773630 = path.getOrDefault("campaign-id")
  valid_773630 = validateParameter(valid_773630, JString, required = true,
                                 default = nil)
  if valid_773630 != nil:
    section.add "campaign-id", valid_773630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773631 = header.getOrDefault("X-Amz-Date")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Date", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Security-Token")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Security-Token", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Content-Sha256", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Algorithm")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Algorithm", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Signature")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Signature", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-SignedHeaders", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-Credential")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Credential", valid_773637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773638: Call_GetCampaign_773626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_773638.validator(path, query, header, formData, body)
  let scheme = call_773638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773638.url(scheme.get, call_773638.host, call_773638.base,
                         call_773638.route, valid.getOrDefault("path"))
  result = hook(call_773638, url, valid)

proc call*(call_773639: Call_GetCampaign_773626; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_773640 = newJObject()
  add(path_773640, "application-id", newJString(applicationId))
  add(path_773640, "campaign-id", newJString(campaignId))
  result = call_773639.call(path_773640, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_773626(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_773627,
                                        base: "/", url: url_GetCampaign_773628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_773658 = ref object of OpenApiRestCall_772581
proc url_DeleteCampaign_773660(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_773659(path: JsonNode; query: JsonNode;
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
  var valid_773661 = path.getOrDefault("application-id")
  valid_773661 = validateParameter(valid_773661, JString, required = true,
                                 default = nil)
  if valid_773661 != nil:
    section.add "application-id", valid_773661
  var valid_773662 = path.getOrDefault("campaign-id")
  valid_773662 = validateParameter(valid_773662, JString, required = true,
                                 default = nil)
  if valid_773662 != nil:
    section.add "campaign-id", valid_773662
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773663 = header.getOrDefault("X-Amz-Date")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Date", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Security-Token")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Security-Token", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Content-Sha256", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Algorithm")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Algorithm", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Signature")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Signature", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-SignedHeaders", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Credential")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Credential", valid_773669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773670: Call_DeleteCampaign_773658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_773670.validator(path, query, header, formData, body)
  let scheme = call_773670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773670.url(scheme.get, call_773670.host, call_773670.base,
                         call_773670.route, valid.getOrDefault("path"))
  result = hook(call_773670, url, valid)

proc call*(call_773671: Call_DeleteCampaign_773658; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_773672 = newJObject()
  add(path_773672, "application-id", newJString(applicationId))
  add(path_773672, "campaign-id", newJString(campaignId))
  result = call_773671.call(path_773672, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_773658(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_773659, base: "/", url: url_DeleteCampaign_773660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_773687 = ref object of OpenApiRestCall_772581
proc url_UpdateEmailChannel_773689(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_773688(path: JsonNode; query: JsonNode;
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
  var valid_773690 = path.getOrDefault("application-id")
  valid_773690 = validateParameter(valid_773690, JString, required = true,
                                 default = nil)
  if valid_773690 != nil:
    section.add "application-id", valid_773690
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773691 = header.getOrDefault("X-Amz-Date")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Date", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Security-Token")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Security-Token", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Content-Sha256", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Algorithm")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Algorithm", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Signature")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Signature", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-SignedHeaders", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Credential")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Credential", valid_773697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773699: Call_UpdateEmailChannel_773687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the email channel for an application.
  ## 
  let valid = call_773699.validator(path, query, header, formData, body)
  let scheme = call_773699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773699.url(scheme.get, call_773699.host, call_773699.base,
                         call_773699.route, valid.getOrDefault("path"))
  result = hook(call_773699, url, valid)

proc call*(call_773700: Call_UpdateEmailChannel_773687; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773701 = newJObject()
  var body_773702 = newJObject()
  add(path_773701, "application-id", newJString(applicationId))
  if body != nil:
    body_773702 = body
  result = call_773700.call(path_773701, nil, nil, nil, body_773702)

var updateEmailChannel* = Call_UpdateEmailChannel_773687(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_773688, base: "/",
    url: url_UpdateEmailChannel_773689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_773673 = ref object of OpenApiRestCall_772581
proc url_GetEmailChannel_773675(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_773674(path: JsonNode; query: JsonNode;
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
  var valid_773676 = path.getOrDefault("application-id")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = nil)
  if valid_773676 != nil:
    section.add "application-id", valid_773676
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Content-Sha256", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Algorithm")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Algorithm", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Signature")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Signature", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-SignedHeaders", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Credential")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Credential", valid_773683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_GetEmailChannel_773673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_GetEmailChannel_773673; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773686 = newJObject()
  add(path_773686, "application-id", newJString(applicationId))
  result = call_773685.call(path_773686, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_773673(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_773674, base: "/", url: url_GetEmailChannel_773675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_773703 = ref object of OpenApiRestCall_772581
proc url_DeleteEmailChannel_773705(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_773704(path: JsonNode; query: JsonNode;
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
  var valid_773706 = path.getOrDefault("application-id")
  valid_773706 = validateParameter(valid_773706, JString, required = true,
                                 default = nil)
  if valid_773706 != nil:
    section.add "application-id", valid_773706
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773707 = header.getOrDefault("X-Amz-Date")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Date", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Security-Token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Security-Token", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Content-Sha256", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Algorithm")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Algorithm", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Signature")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Signature", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-SignedHeaders", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Credential")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Credential", valid_773713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773714: Call_DeleteEmailChannel_773703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773714.validator(path, query, header, formData, body)
  let scheme = call_773714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773714.url(scheme.get, call_773714.host, call_773714.base,
                         call_773714.route, valid.getOrDefault("path"))
  result = hook(call_773714, url, valid)

proc call*(call_773715: Call_DeleteEmailChannel_773703; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773716 = newJObject()
  add(path_773716, "application-id", newJString(applicationId))
  result = call_773715.call(path_773716, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_773703(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_773704, base: "/",
    url: url_DeleteEmailChannel_773705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_773732 = ref object of OpenApiRestCall_772581
proc url_UpdateEndpoint_773734(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_773733(path: JsonNode; query: JsonNode;
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
  var valid_773735 = path.getOrDefault("application-id")
  valid_773735 = validateParameter(valid_773735, JString, required = true,
                                 default = nil)
  if valid_773735 != nil:
    section.add "application-id", valid_773735
  var valid_773736 = path.getOrDefault("endpoint-id")
  valid_773736 = validateParameter(valid_773736, JString, required = true,
                                 default = nil)
  if valid_773736 != nil:
    section.add "endpoint-id", valid_773736
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773737 = header.getOrDefault("X-Amz-Date")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Date", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Security-Token")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Security-Token", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Content-Sha256", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Algorithm")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Algorithm", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Signature")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Signature", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-SignedHeaders", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-Credential")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Credential", valid_773743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773745: Call_UpdateEndpoint_773732; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_773745.validator(path, query, header, formData, body)
  let scheme = call_773745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773745.url(scheme.get, call_773745.host, call_773745.base,
                         call_773745.route, valid.getOrDefault("path"))
  result = hook(call_773745, url, valid)

proc call*(call_773746: Call_UpdateEndpoint_773732; applicationId: string;
          endpointId: string; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  ##   body: JObject (required)
  var path_773747 = newJObject()
  var body_773748 = newJObject()
  add(path_773747, "application-id", newJString(applicationId))
  add(path_773747, "endpoint-id", newJString(endpointId))
  if body != nil:
    body_773748 = body
  result = call_773746.call(path_773747, nil, nil, nil, body_773748)

var updateEndpoint* = Call_UpdateEndpoint_773732(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_773733, base: "/", url: url_UpdateEndpoint_773734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_773717 = ref object of OpenApiRestCall_772581
proc url_GetEndpoint_773719(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_773718(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773720 = path.getOrDefault("application-id")
  valid_773720 = validateParameter(valid_773720, JString, required = true,
                                 default = nil)
  if valid_773720 != nil:
    section.add "application-id", valid_773720
  var valid_773721 = path.getOrDefault("endpoint-id")
  valid_773721 = validateParameter(valid_773721, JString, required = true,
                                 default = nil)
  if valid_773721 != nil:
    section.add "endpoint-id", valid_773721
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773722 = header.getOrDefault("X-Amz-Date")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Date", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Security-Token")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Security-Token", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Content-Sha256", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Algorithm")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Algorithm", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Signature")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Signature", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-SignedHeaders", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Credential")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Credential", valid_773728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773729: Call_GetEndpoint_773717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_773729.validator(path, query, header, formData, body)
  let scheme = call_773729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773729.url(scheme.get, call_773729.host, call_773729.base,
                         call_773729.route, valid.getOrDefault("path"))
  result = hook(call_773729, url, valid)

proc call*(call_773730: Call_GetEndpoint_773717; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_773731 = newJObject()
  add(path_773731, "application-id", newJString(applicationId))
  add(path_773731, "endpoint-id", newJString(endpointId))
  result = call_773730.call(path_773731, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_773717(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_773718,
                                        base: "/", url: url_GetEndpoint_773719,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_773749 = ref object of OpenApiRestCall_772581
proc url_DeleteEndpoint_773751(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_773750(path: JsonNode; query: JsonNode;
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
  var valid_773752 = path.getOrDefault("application-id")
  valid_773752 = validateParameter(valid_773752, JString, required = true,
                                 default = nil)
  if valid_773752 != nil:
    section.add "application-id", valid_773752
  var valid_773753 = path.getOrDefault("endpoint-id")
  valid_773753 = validateParameter(valid_773753, JString, required = true,
                                 default = nil)
  if valid_773753 != nil:
    section.add "endpoint-id", valid_773753
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773754 = header.getOrDefault("X-Amz-Date")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Date", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Security-Token")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Security-Token", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Content-Sha256", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Algorithm")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Algorithm", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-Signature")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Signature", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-SignedHeaders", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Credential")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Credential", valid_773760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773761: Call_DeleteEndpoint_773749; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_773761.validator(path, query, header, formData, body)
  let scheme = call_773761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773761.url(scheme.get, call_773761.host, call_773761.base,
                         call_773761.route, valid.getOrDefault("path"))
  result = hook(call_773761, url, valid)

proc call*(call_773762: Call_DeleteEndpoint_773749; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_773763 = newJObject()
  add(path_773763, "application-id", newJString(applicationId))
  add(path_773763, "endpoint-id", newJString(endpointId))
  result = call_773762.call(path_773763, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_773749(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_773750, base: "/", url: url_DeleteEndpoint_773751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_773778 = ref object of OpenApiRestCall_772581
proc url_PutEventStream_773780(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_773779(path: JsonNode; query: JsonNode;
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
  var valid_773781 = path.getOrDefault("application-id")
  valid_773781 = validateParameter(valid_773781, JString, required = true,
                                 default = nil)
  if valid_773781 != nil:
    section.add "application-id", valid_773781
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773782 = header.getOrDefault("X-Amz-Date")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Date", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Security-Token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Security-Token", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Content-Sha256", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Algorithm")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Algorithm", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Signature")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Signature", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-SignedHeaders", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Credential")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Credential", valid_773788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773790: Call_PutEventStream_773778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_773790.validator(path, query, header, formData, body)
  let scheme = call_773790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773790.url(scheme.get, call_773790.host, call_773790.base,
                         call_773790.route, valid.getOrDefault("path"))
  result = hook(call_773790, url, valid)

proc call*(call_773791: Call_PutEventStream_773778; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773792 = newJObject()
  var body_773793 = newJObject()
  add(path_773792, "application-id", newJString(applicationId))
  if body != nil:
    body_773793 = body
  result = call_773791.call(path_773792, nil, nil, nil, body_773793)

var putEventStream* = Call_PutEventStream_773778(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_773779, base: "/", url: url_PutEventStream_773780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_773764 = ref object of OpenApiRestCall_772581
proc url_GetEventStream_773766(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_773765(path: JsonNode; query: JsonNode;
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
  var valid_773767 = path.getOrDefault("application-id")
  valid_773767 = validateParameter(valid_773767, JString, required = true,
                                 default = nil)
  if valid_773767 != nil:
    section.add "application-id", valid_773767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773768 = header.getOrDefault("X-Amz-Date")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Date", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Security-Token")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Security-Token", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Algorithm")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Algorithm", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Signature")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Signature", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-SignedHeaders", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Credential")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Credential", valid_773774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773775: Call_GetEventStream_773764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_773775.validator(path, query, header, formData, body)
  let scheme = call_773775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773775.url(scheme.get, call_773775.host, call_773775.base,
                         call_773775.route, valid.getOrDefault("path"))
  result = hook(call_773775, url, valid)

proc call*(call_773776: Call_GetEventStream_773764; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773777 = newJObject()
  add(path_773777, "application-id", newJString(applicationId))
  result = call_773776.call(path_773777, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_773764(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_773765, base: "/", url: url_GetEventStream_773766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_773794 = ref object of OpenApiRestCall_772581
proc url_DeleteEventStream_773796(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_773795(path: JsonNode; query: JsonNode;
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
  var valid_773797 = path.getOrDefault("application-id")
  valid_773797 = validateParameter(valid_773797, JString, required = true,
                                 default = nil)
  if valid_773797 != nil:
    section.add "application-id", valid_773797
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773798 = header.getOrDefault("X-Amz-Date")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Date", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Security-Token")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Security-Token", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Content-Sha256", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Algorithm")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Algorithm", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Signature")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Signature", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-SignedHeaders", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Credential")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Credential", valid_773804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773805: Call_DeleteEventStream_773794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_773805.validator(path, query, header, formData, body)
  let scheme = call_773805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773805.url(scheme.get, call_773805.host, call_773805.base,
                         call_773805.route, valid.getOrDefault("path"))
  result = hook(call_773805, url, valid)

proc call*(call_773806: Call_DeleteEventStream_773794; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773807 = newJObject()
  add(path_773807, "application-id", newJString(applicationId))
  result = call_773806.call(path_773807, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_773794(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_773795, base: "/",
    url: url_DeleteEventStream_773796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_773822 = ref object of OpenApiRestCall_772581
proc url_UpdateGcmChannel_773824(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_773823(path: JsonNode; query: JsonNode;
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
  var valid_773825 = path.getOrDefault("application-id")
  valid_773825 = validateParameter(valid_773825, JString, required = true,
                                 default = nil)
  if valid_773825 != nil:
    section.add "application-id", valid_773825
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773826 = header.getOrDefault("X-Amz-Date")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Date", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Security-Token")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Security-Token", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Content-Sha256", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-Algorithm")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Algorithm", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Signature")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Signature", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-SignedHeaders", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Credential")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Credential", valid_773832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773834: Call_UpdateGcmChannel_773822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_773834.validator(path, query, header, formData, body)
  let scheme = call_773834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773834.url(scheme.get, call_773834.host, call_773834.base,
                         call_773834.route, valid.getOrDefault("path"))
  result = hook(call_773834, url, valid)

proc call*(call_773835: Call_UpdateGcmChannel_773822; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773836 = newJObject()
  var body_773837 = newJObject()
  add(path_773836, "application-id", newJString(applicationId))
  if body != nil:
    body_773837 = body
  result = call_773835.call(path_773836, nil, nil, nil, body_773837)

var updateGcmChannel* = Call_UpdateGcmChannel_773822(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_773823, base: "/",
    url: url_UpdateGcmChannel_773824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_773808 = ref object of OpenApiRestCall_772581
proc url_GetGcmChannel_773810(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_773809(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773811 = path.getOrDefault("application-id")
  valid_773811 = validateParameter(valid_773811, JString, required = true,
                                 default = nil)
  if valid_773811 != nil:
    section.add "application-id", valid_773811
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773812 = header.getOrDefault("X-Amz-Date")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Date", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Security-Token")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Security-Token", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Content-Sha256", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Algorithm")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Algorithm", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Signature")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Signature", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-SignedHeaders", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Credential")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Credential", valid_773818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773819: Call_GetGcmChannel_773808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_773819.validator(path, query, header, formData, body)
  let scheme = call_773819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773819.url(scheme.get, call_773819.host, call_773819.base,
                         call_773819.route, valid.getOrDefault("path"))
  result = hook(call_773819, url, valid)

proc call*(call_773820: Call_GetGcmChannel_773808; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773821 = newJObject()
  add(path_773821, "application-id", newJString(applicationId))
  result = call_773820.call(path_773821, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_773808(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_773809, base: "/", url: url_GetGcmChannel_773810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_773838 = ref object of OpenApiRestCall_772581
proc url_DeleteGcmChannel_773840(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_773839(path: JsonNode; query: JsonNode;
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
  var valid_773841 = path.getOrDefault("application-id")
  valid_773841 = validateParameter(valid_773841, JString, required = true,
                                 default = nil)
  if valid_773841 != nil:
    section.add "application-id", valid_773841
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773842 = header.getOrDefault("X-Amz-Date")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Date", valid_773842
  var valid_773843 = header.getOrDefault("X-Amz-Security-Token")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-Security-Token", valid_773843
  var valid_773844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773844 = validateParameter(valid_773844, JString, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "X-Amz-Content-Sha256", valid_773844
  var valid_773845 = header.getOrDefault("X-Amz-Algorithm")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "X-Amz-Algorithm", valid_773845
  var valid_773846 = header.getOrDefault("X-Amz-Signature")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Signature", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-SignedHeaders", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Credential")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Credential", valid_773848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773849: Call_DeleteGcmChannel_773838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773849.validator(path, query, header, formData, body)
  let scheme = call_773849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773849.url(scheme.get, call_773849.host, call_773849.base,
                         call_773849.route, valid.getOrDefault("path"))
  result = hook(call_773849, url, valid)

proc call*(call_773850: Call_DeleteGcmChannel_773838; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773851 = newJObject()
  add(path_773851, "application-id", newJString(applicationId))
  result = call_773850.call(path_773851, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_773838(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_773839, base: "/",
    url: url_DeleteGcmChannel_773840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_773867 = ref object of OpenApiRestCall_772581
proc url_UpdateSegment_773869(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_773868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773870 = path.getOrDefault("segment-id")
  valid_773870 = validateParameter(valid_773870, JString, required = true,
                                 default = nil)
  if valid_773870 != nil:
    section.add "segment-id", valid_773870
  var valid_773871 = path.getOrDefault("application-id")
  valid_773871 = validateParameter(valid_773871, JString, required = true,
                                 default = nil)
  if valid_773871 != nil:
    section.add "application-id", valid_773871
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773872 = header.getOrDefault("X-Amz-Date")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Date", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Security-Token")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Security-Token", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-Content-Sha256", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Algorithm")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Algorithm", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Signature")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Signature", valid_773876
  var valid_773877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "X-Amz-SignedHeaders", valid_773877
  var valid_773878 = header.getOrDefault("X-Amz-Credential")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-Credential", valid_773878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773880: Call_UpdateSegment_773867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_773880.validator(path, query, header, formData, body)
  let scheme = call_773880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773880.url(scheme.get, call_773880.host, call_773880.base,
                         call_773880.route, valid.getOrDefault("path"))
  result = hook(call_773880, url, valid)

proc call*(call_773881: Call_UpdateSegment_773867; segmentId: string;
          applicationId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773882 = newJObject()
  var body_773883 = newJObject()
  add(path_773882, "segment-id", newJString(segmentId))
  add(path_773882, "application-id", newJString(applicationId))
  if body != nil:
    body_773883 = body
  result = call_773881.call(path_773882, nil, nil, nil, body_773883)

var updateSegment* = Call_UpdateSegment_773867(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_773868, base: "/", url: url_UpdateSegment_773869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_773852 = ref object of OpenApiRestCall_772581
proc url_GetSegment_773854(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_773853(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773855 = path.getOrDefault("segment-id")
  valid_773855 = validateParameter(valid_773855, JString, required = true,
                                 default = nil)
  if valid_773855 != nil:
    section.add "segment-id", valid_773855
  var valid_773856 = path.getOrDefault("application-id")
  valid_773856 = validateParameter(valid_773856, JString, required = true,
                                 default = nil)
  if valid_773856 != nil:
    section.add "application-id", valid_773856
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773857 = header.getOrDefault("X-Amz-Date")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Date", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Security-Token")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Security-Token", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-Content-Sha256", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Algorithm")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Algorithm", valid_773860
  var valid_773861 = header.getOrDefault("X-Amz-Signature")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Signature", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-SignedHeaders", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Credential")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Credential", valid_773863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773864: Call_GetSegment_773852; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_773864.validator(path, query, header, formData, body)
  let scheme = call_773864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773864.url(scheme.get, call_773864.host, call_773864.base,
                         call_773864.route, valid.getOrDefault("path"))
  result = hook(call_773864, url, valid)

proc call*(call_773865: Call_GetSegment_773852; segmentId: string;
          applicationId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773866 = newJObject()
  add(path_773866, "segment-id", newJString(segmentId))
  add(path_773866, "application-id", newJString(applicationId))
  result = call_773865.call(path_773866, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_773852(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_773853,
                                      base: "/", url: url_GetSegment_773854,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_773884 = ref object of OpenApiRestCall_772581
proc url_DeleteSegment_773886(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_773885(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773887 = path.getOrDefault("segment-id")
  valid_773887 = validateParameter(valid_773887, JString, required = true,
                                 default = nil)
  if valid_773887 != nil:
    section.add "segment-id", valid_773887
  var valid_773888 = path.getOrDefault("application-id")
  valid_773888 = validateParameter(valid_773888, JString, required = true,
                                 default = nil)
  if valid_773888 != nil:
    section.add "application-id", valid_773888
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773889 = header.getOrDefault("X-Amz-Date")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Date", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Security-Token")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Security-Token", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Content-Sha256", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-Algorithm")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-Algorithm", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Signature")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Signature", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-SignedHeaders", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Credential")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Credential", valid_773895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773896: Call_DeleteSegment_773884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_773896.validator(path, query, header, formData, body)
  let scheme = call_773896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773896.url(scheme.get, call_773896.host, call_773896.base,
                         call_773896.route, valid.getOrDefault("path"))
  result = hook(call_773896, url, valid)

proc call*(call_773897: Call_DeleteSegment_773884; segmentId: string;
          applicationId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773898 = newJObject()
  add(path_773898, "segment-id", newJString(segmentId))
  add(path_773898, "application-id", newJString(applicationId))
  result = call_773897.call(path_773898, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_773884(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_773885, base: "/", url: url_DeleteSegment_773886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_773913 = ref object of OpenApiRestCall_772581
proc url_UpdateSmsChannel_773915(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_773914(path: JsonNode; query: JsonNode;
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
  var valid_773916 = path.getOrDefault("application-id")
  valid_773916 = validateParameter(valid_773916, JString, required = true,
                                 default = nil)
  if valid_773916 != nil:
    section.add "application-id", valid_773916
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773917 = header.getOrDefault("X-Amz-Date")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Date", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Security-Token")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Security-Token", valid_773918
  var valid_773919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Content-Sha256", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Algorithm")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Algorithm", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Signature")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Signature", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-SignedHeaders", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Credential")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Credential", valid_773923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773925: Call_UpdateSmsChannel_773913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_773925.validator(path, query, header, formData, body)
  let scheme = call_773925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773925.url(scheme.get, call_773925.host, call_773925.base,
                         call_773925.route, valid.getOrDefault("path"))
  result = hook(call_773925, url, valid)

proc call*(call_773926: Call_UpdateSmsChannel_773913; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_773927 = newJObject()
  var body_773928 = newJObject()
  add(path_773927, "application-id", newJString(applicationId))
  if body != nil:
    body_773928 = body
  result = call_773926.call(path_773927, nil, nil, nil, body_773928)

var updateSmsChannel* = Call_UpdateSmsChannel_773913(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_773914, base: "/",
    url: url_UpdateSmsChannel_773915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_773899 = ref object of OpenApiRestCall_772581
proc url_GetSmsChannel_773901(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_773900(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773902 = path.getOrDefault("application-id")
  valid_773902 = validateParameter(valid_773902, JString, required = true,
                                 default = nil)
  if valid_773902 != nil:
    section.add "application-id", valid_773902
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773903 = header.getOrDefault("X-Amz-Date")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Date", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Security-Token")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Security-Token", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Content-Sha256", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Algorithm")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Algorithm", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Signature")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Signature", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-SignedHeaders", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Credential")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Credential", valid_773909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773910: Call_GetSmsChannel_773899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_773910.validator(path, query, header, formData, body)
  let scheme = call_773910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773910.url(scheme.get, call_773910.host, call_773910.base,
                         call_773910.route, valid.getOrDefault("path"))
  result = hook(call_773910, url, valid)

proc call*(call_773911: Call_GetSmsChannel_773899; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773912 = newJObject()
  add(path_773912, "application-id", newJString(applicationId))
  result = call_773911.call(path_773912, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_773899(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_773900, base: "/", url: url_GetSmsChannel_773901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_773929 = ref object of OpenApiRestCall_772581
proc url_DeleteSmsChannel_773931(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_773930(path: JsonNode; query: JsonNode;
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
  var valid_773932 = path.getOrDefault("application-id")
  valid_773932 = validateParameter(valid_773932, JString, required = true,
                                 default = nil)
  if valid_773932 != nil:
    section.add "application-id", valid_773932
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773933 = header.getOrDefault("X-Amz-Date")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Date", valid_773933
  var valid_773934 = header.getOrDefault("X-Amz-Security-Token")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "X-Amz-Security-Token", valid_773934
  var valid_773935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Content-Sha256", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Algorithm")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Algorithm", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Signature")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Signature", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-SignedHeaders", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Credential")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Credential", valid_773939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773940: Call_DeleteSmsChannel_773929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_773940.validator(path, query, header, formData, body)
  let scheme = call_773940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773940.url(scheme.get, call_773940.host, call_773940.base,
                         call_773940.route, valid.getOrDefault("path"))
  result = hook(call_773940, url, valid)

proc call*(call_773941: Call_DeleteSmsChannel_773929; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773942 = newJObject()
  add(path_773942, "application-id", newJString(applicationId))
  result = call_773941.call(path_773942, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_773929(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_773930, base: "/",
    url: url_DeleteSmsChannel_773931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_773943 = ref object of OpenApiRestCall_772581
proc url_GetUserEndpoints_773945(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_773944(path: JsonNode; query: JsonNode;
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
  var valid_773946 = path.getOrDefault("user-id")
  valid_773946 = validateParameter(valid_773946, JString, required = true,
                                 default = nil)
  if valid_773946 != nil:
    section.add "user-id", valid_773946
  var valid_773947 = path.getOrDefault("application-id")
  valid_773947 = validateParameter(valid_773947, JString, required = true,
                                 default = nil)
  if valid_773947 != nil:
    section.add "application-id", valid_773947
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773948 = header.getOrDefault("X-Amz-Date")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-Date", valid_773948
  var valid_773949 = header.getOrDefault("X-Amz-Security-Token")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Security-Token", valid_773949
  var valid_773950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Content-Sha256", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Algorithm")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Algorithm", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Signature")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Signature", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-SignedHeaders", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Credential")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Credential", valid_773954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773955: Call_GetUserEndpoints_773943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_773955.validator(path, query, header, formData, body)
  let scheme = call_773955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773955.url(scheme.get, call_773955.host, call_773955.base,
                         call_773955.route, valid.getOrDefault("path"))
  result = hook(call_773955, url, valid)

proc call*(call_773956: Call_GetUserEndpoints_773943; userId: string;
          applicationId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773957 = newJObject()
  add(path_773957, "user-id", newJString(userId))
  add(path_773957, "application-id", newJString(applicationId))
  result = call_773956.call(path_773957, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_773943(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_773944, base: "/",
    url: url_GetUserEndpoints_773945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_773958 = ref object of OpenApiRestCall_772581
proc url_DeleteUserEndpoints_773960(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_773959(path: JsonNode; query: JsonNode;
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
  var valid_773961 = path.getOrDefault("user-id")
  valid_773961 = validateParameter(valid_773961, JString, required = true,
                                 default = nil)
  if valid_773961 != nil:
    section.add "user-id", valid_773961
  var valid_773962 = path.getOrDefault("application-id")
  valid_773962 = validateParameter(valid_773962, JString, required = true,
                                 default = nil)
  if valid_773962 != nil:
    section.add "application-id", valid_773962
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773963 = header.getOrDefault("X-Amz-Date")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Date", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Security-Token")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Security-Token", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Content-Sha256", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Algorithm")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Algorithm", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-Signature")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Signature", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-SignedHeaders", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Credential")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Credential", valid_773969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773970: Call_DeleteUserEndpoints_773958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_773970.validator(path, query, header, formData, body)
  let scheme = call_773970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773970.url(scheme.get, call_773970.host, call_773970.base,
                         call_773970.route, valid.getOrDefault("path"))
  result = hook(call_773970, url, valid)

proc call*(call_773971: Call_DeleteUserEndpoints_773958; userId: string;
          applicationId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773972 = newJObject()
  add(path_773972, "user-id", newJString(userId))
  add(path_773972, "application-id", newJString(applicationId))
  result = call_773971.call(path_773972, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_773958(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_773959, base: "/",
    url: url_DeleteUserEndpoints_773960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_773987 = ref object of OpenApiRestCall_772581
proc url_UpdateVoiceChannel_773989(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_773988(path: JsonNode; query: JsonNode;
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
  var valid_773990 = path.getOrDefault("application-id")
  valid_773990 = validateParameter(valid_773990, JString, required = true,
                                 default = nil)
  if valid_773990 != nil:
    section.add "application-id", valid_773990
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773991 = header.getOrDefault("X-Amz-Date")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Date", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Security-Token")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Security-Token", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Content-Sha256", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-Algorithm")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-Algorithm", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-Signature")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Signature", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-SignedHeaders", valid_773996
  var valid_773997 = header.getOrDefault("X-Amz-Credential")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Credential", valid_773997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773999: Call_UpdateVoiceChannel_773987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_773999.validator(path, query, header, formData, body)
  let scheme = call_773999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773999.url(scheme.get, call_773999.host, call_773999.base,
                         call_773999.route, valid.getOrDefault("path"))
  result = hook(call_773999, url, valid)

proc call*(call_774000: Call_UpdateVoiceChannel_773987; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774001 = newJObject()
  var body_774002 = newJObject()
  add(path_774001, "application-id", newJString(applicationId))
  if body != nil:
    body_774002 = body
  result = call_774000.call(path_774001, nil, nil, nil, body_774002)

var updateVoiceChannel* = Call_UpdateVoiceChannel_773987(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_773988, base: "/",
    url: url_UpdateVoiceChannel_773989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_773973 = ref object of OpenApiRestCall_772581
proc url_GetVoiceChannel_773975(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_773974(path: JsonNode; query: JsonNode;
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
  var valid_773976 = path.getOrDefault("application-id")
  valid_773976 = validateParameter(valid_773976, JString, required = true,
                                 default = nil)
  if valid_773976 != nil:
    section.add "application-id", valid_773976
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773977 = header.getOrDefault("X-Amz-Date")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Date", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Security-Token")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Security-Token", valid_773978
  var valid_773979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-Content-Sha256", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Algorithm")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Algorithm", valid_773980
  var valid_773981 = header.getOrDefault("X-Amz-Signature")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Signature", valid_773981
  var valid_773982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "X-Amz-SignedHeaders", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-Credential")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Credential", valid_773983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773984: Call_GetVoiceChannel_773973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_773984.validator(path, query, header, formData, body)
  let scheme = call_773984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773984.url(scheme.get, call_773984.host, call_773984.base,
                         call_773984.route, valid.getOrDefault("path"))
  result = hook(call_773984, url, valid)

proc call*(call_773985: Call_GetVoiceChannel_773973; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_773986 = newJObject()
  add(path_773986, "application-id", newJString(applicationId))
  result = call_773985.call(path_773986, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_773973(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_773974, base: "/", url: url_GetVoiceChannel_773975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_774003 = ref object of OpenApiRestCall_772581
proc url_DeleteVoiceChannel_774005(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_774004(path: JsonNode; query: JsonNode;
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
  var valid_774006 = path.getOrDefault("application-id")
  valid_774006 = validateParameter(valid_774006, JString, required = true,
                                 default = nil)
  if valid_774006 != nil:
    section.add "application-id", valid_774006
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774007 = header.getOrDefault("X-Amz-Date")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Date", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Security-Token")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Security-Token", valid_774008
  var valid_774009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-Content-Sha256", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Algorithm")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Algorithm", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-Signature")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Signature", valid_774011
  var valid_774012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-SignedHeaders", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-Credential")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-Credential", valid_774013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774014: Call_DeleteVoiceChannel_774003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_774014.validator(path, query, header, formData, body)
  let scheme = call_774014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774014.url(scheme.get, call_774014.host, call_774014.base,
                         call_774014.route, valid.getOrDefault("path"))
  result = hook(call_774014, url, valid)

proc call*(call_774015: Call_DeleteVoiceChannel_774003; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_774016 = newJObject()
  add(path_774016, "application-id", newJString(applicationId))
  result = call_774015.call(path_774016, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_774003(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_774004, base: "/",
    url: url_DeleteVoiceChannel_774005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_774017 = ref object of OpenApiRestCall_772581
proc url_GetApplicationDateRangeKpi_774019(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_774018(path: JsonNode; query: JsonNode;
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
  var valid_774020 = path.getOrDefault("application-id")
  valid_774020 = validateParameter(valid_774020, JString, required = true,
                                 default = nil)
  if valid_774020 != nil:
    section.add "application-id", valid_774020
  var valid_774021 = path.getOrDefault("kpi-name")
  valid_774021 = validateParameter(valid_774021, JString, required = true,
                                 default = nil)
  if valid_774021 != nil:
    section.add "kpi-name", valid_774021
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
  var valid_774022 = query.getOrDefault("end-time")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "end-time", valid_774022
  var valid_774023 = query.getOrDefault("start-time")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "start-time", valid_774023
  var valid_774024 = query.getOrDefault("next-token")
  valid_774024 = validateParameter(valid_774024, JString, required = false,
                                 default = nil)
  if valid_774024 != nil:
    section.add "next-token", valid_774024
  var valid_774025 = query.getOrDefault("page-size")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "page-size", valid_774025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774026 = header.getOrDefault("X-Amz-Date")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Date", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Security-Token")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Security-Token", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Content-Sha256", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Algorithm")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Algorithm", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Signature")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Signature", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-SignedHeaders", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-Credential")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-Credential", valid_774032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774033: Call_GetApplicationDateRangeKpi_774017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.</p>
  ## 
  let valid = call_774033.validator(path, query, header, formData, body)
  let scheme = call_774033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774033.url(scheme.get, call_774033.host, call_774033.base,
                         call_774033.route, valid.getOrDefault("path"))
  result = hook(call_774033, url, valid)

proc call*(call_774034: Call_GetApplicationDateRangeKpi_774017;
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
  var path_774035 = newJObject()
  var query_774036 = newJObject()
  add(query_774036, "end-time", newJString(endTime))
  add(path_774035, "application-id", newJString(applicationId))
  add(path_774035, "kpi-name", newJString(kpiName))
  add(query_774036, "start-time", newJString(startTime))
  add(query_774036, "next-token", newJString(nextToken))
  add(query_774036, "page-size", newJString(pageSize))
  result = call_774034.call(path_774035, query_774036, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_774017(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_774018, base: "/",
    url: url_GetApplicationDateRangeKpi_774019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_774051 = ref object of OpenApiRestCall_772581
proc url_UpdateApplicationSettings_774053(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_774052(path: JsonNode; query: JsonNode;
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
  var valid_774054 = path.getOrDefault("application-id")
  valid_774054 = validateParameter(valid_774054, JString, required = true,
                                 default = nil)
  if valid_774054 != nil:
    section.add "application-id", valid_774054
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774055 = header.getOrDefault("X-Amz-Date")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Date", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Security-Token")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Security-Token", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-Content-Sha256", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-Algorithm")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-Algorithm", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Signature")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Signature", valid_774059
  var valid_774060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "X-Amz-SignedHeaders", valid_774060
  var valid_774061 = header.getOrDefault("X-Amz-Credential")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Credential", valid_774061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774063: Call_UpdateApplicationSettings_774051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_774063.validator(path, query, header, formData, body)
  let scheme = call_774063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774063.url(scheme.get, call_774063.host, call_774063.base,
                         call_774063.route, valid.getOrDefault("path"))
  result = hook(call_774063, url, valid)

proc call*(call_774064: Call_UpdateApplicationSettings_774051;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774065 = newJObject()
  var body_774066 = newJObject()
  add(path_774065, "application-id", newJString(applicationId))
  if body != nil:
    body_774066 = body
  result = call_774064.call(path_774065, nil, nil, nil, body_774066)

var updateApplicationSettings* = Call_UpdateApplicationSettings_774051(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_774052, base: "/",
    url: url_UpdateApplicationSettings_774053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_774037 = ref object of OpenApiRestCall_772581
proc url_GetApplicationSettings_774039(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_774038(path: JsonNode; query: JsonNode;
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
  var valid_774040 = path.getOrDefault("application-id")
  valid_774040 = validateParameter(valid_774040, JString, required = true,
                                 default = nil)
  if valid_774040 != nil:
    section.add "application-id", valid_774040
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774041 = header.getOrDefault("X-Amz-Date")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Date", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Security-Token")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Security-Token", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Content-Sha256", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Algorithm")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Algorithm", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Signature")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Signature", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-SignedHeaders", valid_774046
  var valid_774047 = header.getOrDefault("X-Amz-Credential")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "X-Amz-Credential", valid_774047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774048: Call_GetApplicationSettings_774037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_774048.validator(path, query, header, formData, body)
  let scheme = call_774048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774048.url(scheme.get, call_774048.host, call_774048.base,
                         call_774048.route, valid.getOrDefault("path"))
  result = hook(call_774048, url, valid)

proc call*(call_774049: Call_GetApplicationSettings_774037; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_774050 = newJObject()
  add(path_774050, "application-id", newJString(applicationId))
  result = call_774049.call(path_774050, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_774037(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_774038, base: "/",
    url: url_GetApplicationSettings_774039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_774067 = ref object of OpenApiRestCall_772581
proc url_GetCampaignActivities_774069(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_774068(path: JsonNode; query: JsonNode;
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
  var valid_774070 = path.getOrDefault("application-id")
  valid_774070 = validateParameter(valid_774070, JString, required = true,
                                 default = nil)
  if valid_774070 != nil:
    section.add "application-id", valid_774070
  var valid_774071 = path.getOrDefault("campaign-id")
  valid_774071 = validateParameter(valid_774071, JString, required = true,
                                 default = nil)
  if valid_774071 != nil:
    section.add "campaign-id", valid_774071
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_774072 = query.getOrDefault("token")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "token", valid_774072
  var valid_774073 = query.getOrDefault("page-size")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "page-size", valid_774073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774074 = header.getOrDefault("X-Amz-Date")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Date", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Security-Token")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Security-Token", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Content-Sha256", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Algorithm")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Algorithm", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-Signature")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Signature", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-SignedHeaders", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Credential")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Credential", valid_774080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774081: Call_GetCampaignActivities_774067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the activity performed by a campaign.
  ## 
  let valid = call_774081.validator(path, query, header, formData, body)
  let scheme = call_774081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774081.url(scheme.get, call_774081.host, call_774081.base,
                         call_774081.route, valid.getOrDefault("path"))
  result = hook(call_774081, url, valid)

proc call*(call_774082: Call_GetCampaignActivities_774067; applicationId: string;
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
  var path_774083 = newJObject()
  var query_774084 = newJObject()
  add(query_774084, "token", newJString(token))
  add(path_774083, "application-id", newJString(applicationId))
  add(path_774083, "campaign-id", newJString(campaignId))
  add(query_774084, "page-size", newJString(pageSize))
  result = call_774082.call(path_774083, query_774084, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_774067(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_774068, base: "/",
    url: url_GetCampaignActivities_774069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_774085 = ref object of OpenApiRestCall_772581
proc url_GetCampaignDateRangeKpi_774087(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_774086(path: JsonNode; query: JsonNode;
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
  var valid_774088 = path.getOrDefault("application-id")
  valid_774088 = validateParameter(valid_774088, JString, required = true,
                                 default = nil)
  if valid_774088 != nil:
    section.add "application-id", valid_774088
  var valid_774089 = path.getOrDefault("kpi-name")
  valid_774089 = validateParameter(valid_774089, JString, required = true,
                                 default = nil)
  if valid_774089 != nil:
    section.add "kpi-name", valid_774089
  var valid_774090 = path.getOrDefault("campaign-id")
  valid_774090 = validateParameter(valid_774090, JString, required = true,
                                 default = nil)
  if valid_774090 != nil:
    section.add "campaign-id", valid_774090
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
  var valid_774091 = query.getOrDefault("end-time")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "end-time", valid_774091
  var valid_774092 = query.getOrDefault("start-time")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "start-time", valid_774092
  var valid_774093 = query.getOrDefault("next-token")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "next-token", valid_774093
  var valid_774094 = query.getOrDefault("page-size")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "page-size", valid_774094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774095 = header.getOrDefault("X-Amz-Date")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "X-Amz-Date", valid_774095
  var valid_774096 = header.getOrDefault("X-Amz-Security-Token")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "X-Amz-Security-Token", valid_774096
  var valid_774097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Content-Sha256", valid_774097
  var valid_774098 = header.getOrDefault("X-Amz-Algorithm")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Algorithm", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Signature")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Signature", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-SignedHeaders", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Credential")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Credential", valid_774101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774102: Call_GetCampaignDateRangeKpi_774085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.</p>
  ## 
  let valid = call_774102.validator(path, query, header, formData, body)
  let scheme = call_774102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774102.url(scheme.get, call_774102.host, call_774102.base,
                         call_774102.route, valid.getOrDefault("path"))
  result = hook(call_774102, url, valid)

proc call*(call_774103: Call_GetCampaignDateRangeKpi_774085; applicationId: string;
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
  var path_774104 = newJObject()
  var query_774105 = newJObject()
  add(query_774105, "end-time", newJString(endTime))
  add(path_774104, "application-id", newJString(applicationId))
  add(path_774104, "kpi-name", newJString(kpiName))
  add(query_774105, "start-time", newJString(startTime))
  add(query_774105, "next-token", newJString(nextToken))
  add(path_774104, "campaign-id", newJString(campaignId))
  add(query_774105, "page-size", newJString(pageSize))
  result = call_774103.call(path_774104, query_774105, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_774085(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_774086, base: "/",
    url: url_GetCampaignDateRangeKpi_774087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_774106 = ref object of OpenApiRestCall_772581
proc url_GetCampaignVersion_774108(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_774107(path: JsonNode; query: JsonNode;
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
  var valid_774109 = path.getOrDefault("version")
  valid_774109 = validateParameter(valid_774109, JString, required = true,
                                 default = nil)
  if valid_774109 != nil:
    section.add "version", valid_774109
  var valid_774110 = path.getOrDefault("application-id")
  valid_774110 = validateParameter(valid_774110, JString, required = true,
                                 default = nil)
  if valid_774110 != nil:
    section.add "application-id", valid_774110
  var valid_774111 = path.getOrDefault("campaign-id")
  valid_774111 = validateParameter(valid_774111, JString, required = true,
                                 default = nil)
  if valid_774111 != nil:
    section.add "campaign-id", valid_774111
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774112 = header.getOrDefault("X-Amz-Date")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Date", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Security-Token")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Security-Token", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Content-Sha256", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Algorithm")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Algorithm", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Signature")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Signature", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-SignedHeaders", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Credential")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Credential", valid_774118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774119: Call_GetCampaignVersion_774106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_774119.validator(path, query, header, formData, body)
  let scheme = call_774119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774119.url(scheme.get, call_774119.host, call_774119.base,
                         call_774119.route, valid.getOrDefault("path"))
  result = hook(call_774119, url, valid)

proc call*(call_774120: Call_GetCampaignVersion_774106; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_774121 = newJObject()
  add(path_774121, "version", newJString(version))
  add(path_774121, "application-id", newJString(applicationId))
  add(path_774121, "campaign-id", newJString(campaignId))
  result = call_774120.call(path_774121, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_774106(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_774107, base: "/",
    url: url_GetCampaignVersion_774108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_774122 = ref object of OpenApiRestCall_772581
proc url_GetCampaignVersions_774124(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_774123(path: JsonNode; query: JsonNode;
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
  var valid_774125 = path.getOrDefault("application-id")
  valid_774125 = validateParameter(valid_774125, JString, required = true,
                                 default = nil)
  if valid_774125 != nil:
    section.add "application-id", valid_774125
  var valid_774126 = path.getOrDefault("campaign-id")
  valid_774126 = validateParameter(valid_774126, JString, required = true,
                                 default = nil)
  if valid_774126 != nil:
    section.add "campaign-id", valid_774126
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_774127 = query.getOrDefault("token")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "token", valid_774127
  var valid_774128 = query.getOrDefault("page-size")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "page-size", valid_774128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774129 = header.getOrDefault("X-Amz-Date")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = nil)
  if valid_774129 != nil:
    section.add "X-Amz-Date", valid_774129
  var valid_774130 = header.getOrDefault("X-Amz-Security-Token")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Security-Token", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Content-Sha256", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-Algorithm")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Algorithm", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Signature")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Signature", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-SignedHeaders", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Credential")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Credential", valid_774135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774136: Call_GetCampaignVersions_774122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ## 
  let valid = call_774136.validator(path, query, header, formData, body)
  let scheme = call_774136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774136.url(scheme.get, call_774136.host, call_774136.base,
                         call_774136.route, valid.getOrDefault("path"))
  result = hook(call_774136, url, valid)

proc call*(call_774137: Call_GetCampaignVersions_774122; applicationId: string;
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
  var path_774138 = newJObject()
  var query_774139 = newJObject()
  add(query_774139, "token", newJString(token))
  add(path_774138, "application-id", newJString(applicationId))
  add(path_774138, "campaign-id", newJString(campaignId))
  add(query_774139, "page-size", newJString(pageSize))
  result = call_774137.call(path_774138, query_774139, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_774122(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_774123, base: "/",
    url: url_GetCampaignVersions_774124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_774140 = ref object of OpenApiRestCall_772581
proc url_GetChannels_774142(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_774141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774143 = path.getOrDefault("application-id")
  valid_774143 = validateParameter(valid_774143, JString, required = true,
                                 default = nil)
  if valid_774143 != nil:
    section.add "application-id", valid_774143
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774144 = header.getOrDefault("X-Amz-Date")
  valid_774144 = validateParameter(valid_774144, JString, required = false,
                                 default = nil)
  if valid_774144 != nil:
    section.add "X-Amz-Date", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-Security-Token")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-Security-Token", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Content-Sha256", valid_774146
  var valid_774147 = header.getOrDefault("X-Amz-Algorithm")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Algorithm", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Signature")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Signature", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-SignedHeaders", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Credential")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Credential", valid_774150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774151: Call_GetChannels_774140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_774151.validator(path, query, header, formData, body)
  let scheme = call_774151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774151.url(scheme.get, call_774151.host, call_774151.base,
                         call_774151.route, valid.getOrDefault("path"))
  result = hook(call_774151, url, valid)

proc call*(call_774152: Call_GetChannels_774140; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_774153 = newJObject()
  add(path_774153, "application-id", newJString(applicationId))
  result = call_774152.call(path_774153, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_774140(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_774141,
                                        base: "/", url: url_GetChannels_774142,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_774154 = ref object of OpenApiRestCall_772581
proc url_GetExportJob_774156(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_774155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774157 = path.getOrDefault("application-id")
  valid_774157 = validateParameter(valid_774157, JString, required = true,
                                 default = nil)
  if valid_774157 != nil:
    section.add "application-id", valid_774157
  var valid_774158 = path.getOrDefault("job-id")
  valid_774158 = validateParameter(valid_774158, JString, required = true,
                                 default = nil)
  if valid_774158 != nil:
    section.add "job-id", valid_774158
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774159 = header.getOrDefault("X-Amz-Date")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Date", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-Security-Token")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-Security-Token", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Content-Sha256", valid_774161
  var valid_774162 = header.getOrDefault("X-Amz-Algorithm")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "X-Amz-Algorithm", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-Signature")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Signature", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-SignedHeaders", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Credential")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Credential", valid_774165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774166: Call_GetExportJob_774154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_774166.validator(path, query, header, formData, body)
  let scheme = call_774166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774166.url(scheme.get, call_774166.host, call_774166.base,
                         call_774166.route, valid.getOrDefault("path"))
  result = hook(call_774166, url, valid)

proc call*(call_774167: Call_GetExportJob_774154; applicationId: string;
          jobId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_774168 = newJObject()
  add(path_774168, "application-id", newJString(applicationId))
  add(path_774168, "job-id", newJString(jobId))
  result = call_774167.call(path_774168, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_774154(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_774155, base: "/", url: url_GetExportJob_774156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_774169 = ref object of OpenApiRestCall_772581
proc url_GetImportJob_774171(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_774170(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774172 = path.getOrDefault("application-id")
  valid_774172 = validateParameter(valid_774172, JString, required = true,
                                 default = nil)
  if valid_774172 != nil:
    section.add "application-id", valid_774172
  var valid_774173 = path.getOrDefault("job-id")
  valid_774173 = validateParameter(valid_774173, JString, required = true,
                                 default = nil)
  if valid_774173 != nil:
    section.add "job-id", valid_774173
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774174 = header.getOrDefault("X-Amz-Date")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "X-Amz-Date", valid_774174
  var valid_774175 = header.getOrDefault("X-Amz-Security-Token")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-Security-Token", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-Content-Sha256", valid_774176
  var valid_774177 = header.getOrDefault("X-Amz-Algorithm")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "X-Amz-Algorithm", valid_774177
  var valid_774178 = header.getOrDefault("X-Amz-Signature")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "X-Amz-Signature", valid_774178
  var valid_774179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "X-Amz-SignedHeaders", valid_774179
  var valid_774180 = header.getOrDefault("X-Amz-Credential")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Credential", valid_774180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774181: Call_GetImportJob_774169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_774181.validator(path, query, header, formData, body)
  let scheme = call_774181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774181.url(scheme.get, call_774181.host, call_774181.base,
                         call_774181.route, valid.getOrDefault("path"))
  result = hook(call_774181, url, valid)

proc call*(call_774182: Call_GetImportJob_774169; applicationId: string;
          jobId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  var path_774183 = newJObject()
  add(path_774183, "application-id", newJString(applicationId))
  add(path_774183, "job-id", newJString(jobId))
  result = call_774182.call(path_774183, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_774169(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_774170, base: "/", url: url_GetImportJob_774171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_774184 = ref object of OpenApiRestCall_772581
proc url_GetSegmentExportJobs_774186(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_774185(path: JsonNode; query: JsonNode;
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
  var valid_774187 = path.getOrDefault("segment-id")
  valid_774187 = validateParameter(valid_774187, JString, required = true,
                                 default = nil)
  if valid_774187 != nil:
    section.add "segment-id", valid_774187
  var valid_774188 = path.getOrDefault("application-id")
  valid_774188 = validateParameter(valid_774188, JString, required = true,
                                 default = nil)
  if valid_774188 != nil:
    section.add "application-id", valid_774188
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_774189 = query.getOrDefault("token")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "token", valid_774189
  var valid_774190 = query.getOrDefault("page-size")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "page-size", valid_774190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774191 = header.getOrDefault("X-Amz-Date")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Date", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-Security-Token")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-Security-Token", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Content-Sha256", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Algorithm")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Algorithm", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Signature")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Signature", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-SignedHeaders", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Credential")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Credential", valid_774197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774198: Call_GetSegmentExportJobs_774184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_774198.validator(path, query, header, formData, body)
  let scheme = call_774198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774198.url(scheme.get, call_774198.host, call_774198.base,
                         call_774198.route, valid.getOrDefault("path"))
  result = hook(call_774198, url, valid)

proc call*(call_774199: Call_GetSegmentExportJobs_774184; segmentId: string;
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
  var path_774200 = newJObject()
  var query_774201 = newJObject()
  add(query_774201, "token", newJString(token))
  add(path_774200, "segment-id", newJString(segmentId))
  add(path_774200, "application-id", newJString(applicationId))
  add(query_774201, "page-size", newJString(pageSize))
  result = call_774199.call(path_774200, query_774201, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_774184(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_774185, base: "/",
    url: url_GetSegmentExportJobs_774186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_774202 = ref object of OpenApiRestCall_772581
proc url_GetSegmentImportJobs_774204(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_774203(path: JsonNode; query: JsonNode;
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
  var valid_774205 = path.getOrDefault("segment-id")
  valid_774205 = validateParameter(valid_774205, JString, required = true,
                                 default = nil)
  if valid_774205 != nil:
    section.add "segment-id", valid_774205
  var valid_774206 = path.getOrDefault("application-id")
  valid_774206 = validateParameter(valid_774206, JString, required = true,
                                 default = nil)
  if valid_774206 != nil:
    section.add "application-id", valid_774206
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_774207 = query.getOrDefault("token")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "token", valid_774207
  var valid_774208 = query.getOrDefault("page-size")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "page-size", valid_774208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774209 = header.getOrDefault("X-Amz-Date")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Date", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Security-Token")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Security-Token", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Content-Sha256", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Algorithm")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Algorithm", valid_774212
  var valid_774213 = header.getOrDefault("X-Amz-Signature")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "X-Amz-Signature", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-SignedHeaders", valid_774214
  var valid_774215 = header.getOrDefault("X-Amz-Credential")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Credential", valid_774215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774216: Call_GetSegmentImportJobs_774202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_774216.validator(path, query, header, formData, body)
  let scheme = call_774216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774216.url(scheme.get, call_774216.host, call_774216.base,
                         call_774216.route, valid.getOrDefault("path"))
  result = hook(call_774216, url, valid)

proc call*(call_774217: Call_GetSegmentImportJobs_774202; segmentId: string;
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
  var path_774218 = newJObject()
  var query_774219 = newJObject()
  add(query_774219, "token", newJString(token))
  add(path_774218, "segment-id", newJString(segmentId))
  add(path_774218, "application-id", newJString(applicationId))
  add(query_774219, "page-size", newJString(pageSize))
  result = call_774217.call(path_774218, query_774219, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_774202(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_774203, base: "/",
    url: url_GetSegmentImportJobs_774204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_774220 = ref object of OpenApiRestCall_772581
proc url_GetSegmentVersion_774222(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_774221(path: JsonNode; query: JsonNode;
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
  var valid_774223 = path.getOrDefault("segment-id")
  valid_774223 = validateParameter(valid_774223, JString, required = true,
                                 default = nil)
  if valid_774223 != nil:
    section.add "segment-id", valid_774223
  var valid_774224 = path.getOrDefault("version")
  valid_774224 = validateParameter(valid_774224, JString, required = true,
                                 default = nil)
  if valid_774224 != nil:
    section.add "version", valid_774224
  var valid_774225 = path.getOrDefault("application-id")
  valid_774225 = validateParameter(valid_774225, JString, required = true,
                                 default = nil)
  if valid_774225 != nil:
    section.add "application-id", valid_774225
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774226 = header.getOrDefault("X-Amz-Date")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Date", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-Security-Token")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-Security-Token", valid_774227
  var valid_774228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "X-Amz-Content-Sha256", valid_774228
  var valid_774229 = header.getOrDefault("X-Amz-Algorithm")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Algorithm", valid_774229
  var valid_774230 = header.getOrDefault("X-Amz-Signature")
  valid_774230 = validateParameter(valid_774230, JString, required = false,
                                 default = nil)
  if valid_774230 != nil:
    section.add "X-Amz-Signature", valid_774230
  var valid_774231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-SignedHeaders", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-Credential")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-Credential", valid_774232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774233: Call_GetSegmentVersion_774220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_774233.validator(path, query, header, formData, body)
  let scheme = call_774233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774233.url(scheme.get, call_774233.host, call_774233.base,
                         call_774233.route, valid.getOrDefault("path"))
  result = hook(call_774233, url, valid)

proc call*(call_774234: Call_GetSegmentVersion_774220; segmentId: string;
          version: string; applicationId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_774235 = newJObject()
  add(path_774235, "segment-id", newJString(segmentId))
  add(path_774235, "version", newJString(version))
  add(path_774235, "application-id", newJString(applicationId))
  result = call_774234.call(path_774235, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_774220(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_774221, base: "/",
    url: url_GetSegmentVersion_774222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_774236 = ref object of OpenApiRestCall_772581
proc url_GetSegmentVersions_774238(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_774237(path: JsonNode; query: JsonNode;
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
  var valid_774239 = path.getOrDefault("segment-id")
  valid_774239 = validateParameter(valid_774239, JString, required = true,
                                 default = nil)
  if valid_774239 != nil:
    section.add "segment-id", valid_774239
  var valid_774240 = path.getOrDefault("application-id")
  valid_774240 = validateParameter(valid_774240, JString, required = true,
                                 default = nil)
  if valid_774240 != nil:
    section.add "application-id", valid_774240
  result.add "path", section
  ## parameters in `query` object:
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the App Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_774241 = query.getOrDefault("token")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "token", valid_774241
  var valid_774242 = query.getOrDefault("page-size")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "page-size", valid_774242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774243 = header.getOrDefault("X-Amz-Date")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-Date", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Security-Token")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Security-Token", valid_774244
  var valid_774245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "X-Amz-Content-Sha256", valid_774245
  var valid_774246 = header.getOrDefault("X-Amz-Algorithm")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "X-Amz-Algorithm", valid_774246
  var valid_774247 = header.getOrDefault("X-Amz-Signature")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Signature", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-SignedHeaders", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-Credential")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-Credential", valid_774249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774250: Call_GetSegmentVersions_774236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_774250.validator(path, query, header, formData, body)
  let scheme = call_774250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774250.url(scheme.get, call_774250.host, call_774250.base,
                         call_774250.route, valid.getOrDefault("path"))
  result = hook(call_774250, url, valid)

proc call*(call_774251: Call_GetSegmentVersions_774236; segmentId: string;
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
  var path_774252 = newJObject()
  var query_774253 = newJObject()
  add(query_774253, "token", newJString(token))
  add(path_774252, "segment-id", newJString(segmentId))
  add(path_774252, "application-id", newJString(applicationId))
  add(query_774253, "page-size", newJString(pageSize))
  result = call_774251.call(path_774252, query_774253, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_774236(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_774237, base: "/",
    url: url_GetSegmentVersions_774238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774268 = ref object of OpenApiRestCall_772581
proc url_TagResource_774270(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_774269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774271 = path.getOrDefault("resource-arn")
  valid_774271 = validateParameter(valid_774271, JString, required = true,
                                 default = nil)
  if valid_774271 != nil:
    section.add "resource-arn", valid_774271
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774272 = header.getOrDefault("X-Amz-Date")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Date", valid_774272
  var valid_774273 = header.getOrDefault("X-Amz-Security-Token")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "X-Amz-Security-Token", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Content-Sha256", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Algorithm")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Algorithm", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Signature")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Signature", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-SignedHeaders", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Credential")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Credential", valid_774278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774280: Call_TagResource_774268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ## 
  let valid = call_774280.validator(path, query, header, formData, body)
  let scheme = call_774280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774280.url(scheme.get, call_774280.host, call_774280.base,
                         call_774280.route, valid.getOrDefault("path"))
  result = hook(call_774280, url, valid)

proc call*(call_774281: Call_TagResource_774268; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  ##   body: JObject (required)
  var path_774282 = newJObject()
  var body_774283 = newJObject()
  add(path_774282, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_774283 = body
  result = call_774281.call(path_774282, nil, nil, nil, body_774283)

var tagResource* = Call_TagResource_774268(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_774269,
                                        base: "/", url: url_TagResource_774270,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_774254 = ref object of OpenApiRestCall_772581
proc url_ListTagsForResource_774256(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_774255(path: JsonNode; query: JsonNode;
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
  var valid_774257 = path.getOrDefault("resource-arn")
  valid_774257 = validateParameter(valid_774257, JString, required = true,
                                 default = nil)
  if valid_774257 != nil:
    section.add "resource-arn", valid_774257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774258 = header.getOrDefault("X-Amz-Date")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Date", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Security-Token")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Security-Token", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-Content-Sha256", valid_774260
  var valid_774261 = header.getOrDefault("X-Amz-Algorithm")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-Algorithm", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-Signature")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-Signature", valid_774262
  var valid_774263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "X-Amz-SignedHeaders", valid_774263
  var valid_774264 = header.getOrDefault("X-Amz-Credential")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "X-Amz-Credential", valid_774264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774265: Call_ListTagsForResource_774254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ## 
  let valid = call_774265.validator(path, query, header, formData, body)
  let scheme = call_774265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774265.url(scheme.get, call_774265.host, call_774265.base,
                         call_774265.route, valid.getOrDefault("path"))
  result = hook(call_774265, url, valid)

proc call*(call_774266: Call_ListTagsForResource_774254; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_774267 = newJObject()
  add(path_774267, "resource-arn", newJString(resourceArn))
  result = call_774266.call(path_774267, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_774254(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_774255, base: "/",
    url: url_ListTagsForResource_774256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_774284 = ref object of OpenApiRestCall_772581
proc url_PhoneNumberValidate_774286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PhoneNumberValidate_774285(path: JsonNode; query: JsonNode;
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
  var valid_774287 = header.getOrDefault("X-Amz-Date")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Date", valid_774287
  var valid_774288 = header.getOrDefault("X-Amz-Security-Token")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "X-Amz-Security-Token", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Content-Sha256", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Algorithm")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Algorithm", valid_774290
  var valid_774291 = header.getOrDefault("X-Amz-Signature")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-Signature", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-SignedHeaders", valid_774292
  var valid_774293 = header.getOrDefault("X-Amz-Credential")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "X-Amz-Credential", valid_774293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774295: Call_PhoneNumberValidate_774284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_774295.validator(path, query, header, formData, body)
  let scheme = call_774295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774295.url(scheme.get, call_774295.host, call_774295.base,
                         call_774295.route, valid.getOrDefault("path"))
  result = hook(call_774295, url, valid)

proc call*(call_774296: Call_PhoneNumberValidate_774284; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_774297 = newJObject()
  if body != nil:
    body_774297 = body
  result = call_774296.call(nil, nil, nil, nil, body_774297)

var phoneNumberValidate* = Call_PhoneNumberValidate_774284(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_774285, base: "/",
    url: url_PhoneNumberValidate_774286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_774298 = ref object of OpenApiRestCall_772581
proc url_PutEvents_774300(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_774299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774301 = path.getOrDefault("application-id")
  valid_774301 = validateParameter(valid_774301, JString, required = true,
                                 default = nil)
  if valid_774301 != nil:
    section.add "application-id", valid_774301
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774302 = header.getOrDefault("X-Amz-Date")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Date", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-Security-Token")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Security-Token", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Content-Sha256", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Algorithm")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Algorithm", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Signature")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Signature", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-SignedHeaders", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Credential")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Credential", valid_774308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774310: Call_PutEvents_774298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_774310.validator(path, query, header, formData, body)
  let scheme = call_774310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774310.url(scheme.get, call_774310.host, call_774310.base,
                         call_774310.route, valid.getOrDefault("path"))
  result = hook(call_774310, url, valid)

proc call*(call_774311: Call_PutEvents_774298; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774312 = newJObject()
  var body_774313 = newJObject()
  add(path_774312, "application-id", newJString(applicationId))
  if body != nil:
    body_774313 = body
  result = call_774311.call(path_774312, nil, nil, nil, body_774313)

var putEvents* = Call_PutEvents_774298(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_774299,
                                    base: "/", url: url_PutEvents_774300,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_774314 = ref object of OpenApiRestCall_772581
proc url_RemoveAttributes_774316(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_774315(path: JsonNode; query: JsonNode;
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
  var valid_774317 = path.getOrDefault("attribute-type")
  valid_774317 = validateParameter(valid_774317, JString, required = true,
                                 default = nil)
  if valid_774317 != nil:
    section.add "attribute-type", valid_774317
  var valid_774318 = path.getOrDefault("application-id")
  valid_774318 = validateParameter(valid_774318, JString, required = true,
                                 default = nil)
  if valid_774318 != nil:
    section.add "application-id", valid_774318
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774319 = header.getOrDefault("X-Amz-Date")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Date", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Security-Token")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Security-Token", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Content-Sha256", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Algorithm")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Algorithm", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-Signature")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-Signature", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-SignedHeaders", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-Credential")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-Credential", valid_774325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774327: Call_RemoveAttributes_774314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_774327.validator(path, query, header, formData, body)
  let scheme = call_774327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774327.url(scheme.get, call_774327.host, call_774327.base,
                         call_774327.route, valid.getOrDefault("path"))
  result = hook(call_774327, url, valid)

proc call*(call_774328: Call_RemoveAttributes_774314; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-custom-metrics - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774329 = newJObject()
  var body_774330 = newJObject()
  add(path_774329, "attribute-type", newJString(attributeType))
  add(path_774329, "application-id", newJString(applicationId))
  if body != nil:
    body_774330 = body
  result = call_774328.call(path_774329, nil, nil, nil, body_774330)

var removeAttributes* = Call_RemoveAttributes_774314(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_774315, base: "/",
    url: url_RemoveAttributes_774316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_774331 = ref object of OpenApiRestCall_772581
proc url_SendMessages_774333(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_774332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774334 = path.getOrDefault("application-id")
  valid_774334 = validateParameter(valid_774334, JString, required = true,
                                 default = nil)
  if valid_774334 != nil:
    section.add "application-id", valid_774334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774335 = header.getOrDefault("X-Amz-Date")
  valid_774335 = validateParameter(valid_774335, JString, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "X-Amz-Date", valid_774335
  var valid_774336 = header.getOrDefault("X-Amz-Security-Token")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "X-Amz-Security-Token", valid_774336
  var valid_774337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "X-Amz-Content-Sha256", valid_774337
  var valid_774338 = header.getOrDefault("X-Amz-Algorithm")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Algorithm", valid_774338
  var valid_774339 = header.getOrDefault("X-Amz-Signature")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-Signature", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-SignedHeaders", valid_774340
  var valid_774341 = header.getOrDefault("X-Amz-Credential")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "X-Amz-Credential", valid_774341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774343: Call_SendMessages_774331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_774343.validator(path, query, header, formData, body)
  let scheme = call_774343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774343.url(scheme.get, call_774343.host, call_774343.base,
                         call_774343.route, valid.getOrDefault("path"))
  result = hook(call_774343, url, valid)

proc call*(call_774344: Call_SendMessages_774331; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774345 = newJObject()
  var body_774346 = newJObject()
  add(path_774345, "application-id", newJString(applicationId))
  if body != nil:
    body_774346 = body
  result = call_774344.call(path_774345, nil, nil, nil, body_774346)

var sendMessages* = Call_SendMessages_774331(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_774332,
    base: "/", url: url_SendMessages_774333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_774347 = ref object of OpenApiRestCall_772581
proc url_SendUsersMessages_774349(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_774348(path: JsonNode; query: JsonNode;
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
  var valid_774350 = path.getOrDefault("application-id")
  valid_774350 = validateParameter(valid_774350, JString, required = true,
                                 default = nil)
  if valid_774350 != nil:
    section.add "application-id", valid_774350
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774351 = header.getOrDefault("X-Amz-Date")
  valid_774351 = validateParameter(valid_774351, JString, required = false,
                                 default = nil)
  if valid_774351 != nil:
    section.add "X-Amz-Date", valid_774351
  var valid_774352 = header.getOrDefault("X-Amz-Security-Token")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "X-Amz-Security-Token", valid_774352
  var valid_774353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774353 = validateParameter(valid_774353, JString, required = false,
                                 default = nil)
  if valid_774353 != nil:
    section.add "X-Amz-Content-Sha256", valid_774353
  var valid_774354 = header.getOrDefault("X-Amz-Algorithm")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Algorithm", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-Signature")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Signature", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-SignedHeaders", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-Credential")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Credential", valid_774357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774359: Call_SendUsersMessages_774347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_774359.validator(path, query, header, formData, body)
  let scheme = call_774359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774359.url(scheme.get, call_774359.host, call_774359.base,
                         call_774359.route, valid.getOrDefault("path"))
  result = hook(call_774359, url, valid)

proc call*(call_774360: Call_SendUsersMessages_774347; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774361 = newJObject()
  var body_774362 = newJObject()
  add(path_774361, "application-id", newJString(applicationId))
  if body != nil:
    body_774362 = body
  result = call_774360.call(path_774361, nil, nil, nil, body_774362)

var sendUsersMessages* = Call_SendUsersMessages_774347(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_774348, base: "/",
    url: url_SendUsersMessages_774349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774363 = ref object of OpenApiRestCall_772581
proc url_UntagResource_774365(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_774364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774366 = path.getOrDefault("resource-arn")
  valid_774366 = validateParameter(valid_774366, JString, required = true,
                                 default = nil)
  if valid_774366 != nil:
    section.add "resource-arn", valid_774366
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_774367 = query.getOrDefault("tagKeys")
  valid_774367 = validateParameter(valid_774367, JArray, required = true, default = nil)
  if valid_774367 != nil:
    section.add "tagKeys", valid_774367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774368 = header.getOrDefault("X-Amz-Date")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "X-Amz-Date", valid_774368
  var valid_774369 = header.getOrDefault("X-Amz-Security-Token")
  valid_774369 = validateParameter(valid_774369, JString, required = false,
                                 default = nil)
  if valid_774369 != nil:
    section.add "X-Amz-Security-Token", valid_774369
  var valid_774370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-Content-Sha256", valid_774370
  var valid_774371 = header.getOrDefault("X-Amz-Algorithm")
  valid_774371 = validateParameter(valid_774371, JString, required = false,
                                 default = nil)
  if valid_774371 != nil:
    section.add "X-Amz-Algorithm", valid_774371
  var valid_774372 = header.getOrDefault("X-Amz-Signature")
  valid_774372 = validateParameter(valid_774372, JString, required = false,
                                 default = nil)
  if valid_774372 != nil:
    section.add "X-Amz-Signature", valid_774372
  var valid_774373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-SignedHeaders", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-Credential")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Credential", valid_774374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774375: Call_UntagResource_774363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ## 
  let valid = call_774375.validator(path, query, header, formData, body)
  let scheme = call_774375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774375.url(scheme.get, call_774375.host, call_774375.base,
                         call_774375.route, valid.getOrDefault("path"))
  result = hook(call_774375, url, valid)

proc call*(call_774376: Call_UntagResource_774363; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, or segment.
  var path_774377 = newJObject()
  var query_774378 = newJObject()
  if tagKeys != nil:
    query_774378.add "tagKeys", tagKeys
  add(path_774377, "resource-arn", newJString(resourceArn))
  result = call_774376.call(path_774377, query_774378, nil, nil, nil)

var untagResource* = Call_UntagResource_774363(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_774364,
    base: "/", url: url_UntagResource_774365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_774379 = ref object of OpenApiRestCall_772581
proc url_UpdateEndpointsBatch_774381(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_774380(path: JsonNode; query: JsonNode;
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
  var valid_774382 = path.getOrDefault("application-id")
  valid_774382 = validateParameter(valid_774382, JString, required = true,
                                 default = nil)
  if valid_774382 != nil:
    section.add "application-id", valid_774382
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774383 = header.getOrDefault("X-Amz-Date")
  valid_774383 = validateParameter(valid_774383, JString, required = false,
                                 default = nil)
  if valid_774383 != nil:
    section.add "X-Amz-Date", valid_774383
  var valid_774384 = header.getOrDefault("X-Amz-Security-Token")
  valid_774384 = validateParameter(valid_774384, JString, required = false,
                                 default = nil)
  if valid_774384 != nil:
    section.add "X-Amz-Security-Token", valid_774384
  var valid_774385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "X-Amz-Content-Sha256", valid_774385
  var valid_774386 = header.getOrDefault("X-Amz-Algorithm")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Algorithm", valid_774386
  var valid_774387 = header.getOrDefault("X-Amz-Signature")
  valid_774387 = validateParameter(valid_774387, JString, required = false,
                                 default = nil)
  if valid_774387 != nil:
    section.add "X-Amz-Signature", valid_774387
  var valid_774388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-SignedHeaders", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Credential")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Credential", valid_774389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774391: Call_UpdateEndpointsBatch_774379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_774391.validator(path, query, header, formData, body)
  let scheme = call_774391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774391.url(scheme.get, call_774391.host, call_774391.base,
                         call_774391.route, valid.getOrDefault("path"))
  result = hook(call_774391, url, valid)

proc call*(call_774392: Call_UpdateEndpointsBatch_774379; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_774393 = newJObject()
  var body_774394 = newJObject()
  add(path_774393, "application-id", newJString(applicationId))
  if body != nil:
    body_774394 = body
  result = call_774392.call(path_774393, nil, nil, nil, body_774394)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_774379(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_774380, base: "/",
    url: url_UpdateEndpointsBatch_774381, schemes: {Scheme.Https, Scheme.Http})
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
