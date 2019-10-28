
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

  OpenApiRestCall_590348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590348): Option[Scheme] {.used.} =
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
  Call_CreateApp_590944 = ref object of OpenApiRestCall_590348
proc url_CreateApp_590946(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_590945(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590947 = header.getOrDefault("X-Amz-Signature")
  valid_590947 = validateParameter(valid_590947, JString, required = false,
                                 default = nil)
  if valid_590947 != nil:
    section.add "X-Amz-Signature", valid_590947
  var valid_590948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590948 = validateParameter(valid_590948, JString, required = false,
                                 default = nil)
  if valid_590948 != nil:
    section.add "X-Amz-Content-Sha256", valid_590948
  var valid_590949 = header.getOrDefault("X-Amz-Date")
  valid_590949 = validateParameter(valid_590949, JString, required = false,
                                 default = nil)
  if valid_590949 != nil:
    section.add "X-Amz-Date", valid_590949
  var valid_590950 = header.getOrDefault("X-Amz-Credential")
  valid_590950 = validateParameter(valid_590950, JString, required = false,
                                 default = nil)
  if valid_590950 != nil:
    section.add "X-Amz-Credential", valid_590950
  var valid_590951 = header.getOrDefault("X-Amz-Security-Token")
  valid_590951 = validateParameter(valid_590951, JString, required = false,
                                 default = nil)
  if valid_590951 != nil:
    section.add "X-Amz-Security-Token", valid_590951
  var valid_590952 = header.getOrDefault("X-Amz-Algorithm")
  valid_590952 = validateParameter(valid_590952, JString, required = false,
                                 default = nil)
  if valid_590952 != nil:
    section.add "X-Amz-Algorithm", valid_590952
  var valid_590953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590953 = validateParameter(valid_590953, JString, required = false,
                                 default = nil)
  if valid_590953 != nil:
    section.add "X-Amz-SignedHeaders", valid_590953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590955: Call_CreateApp_590944; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates an application.</p>
  ## 
  let valid = call_590955.validator(path, query, header, formData, body)
  let scheme = call_590955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590955.url(scheme.get, call_590955.host, call_590955.base,
                         call_590955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590955, url, valid)

proc call*(call_590956: Call_CreateApp_590944; body: JsonNode): Recallable =
  ## createApp
  ##  <p>Creates an application.</p>
  ##   body: JObject (required)
  var body_590957 = newJObject()
  if body != nil:
    body_590957 = body
  result = call_590956.call(nil, nil, nil, nil, body_590957)

var createApp* = Call_CreateApp_590944(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps",
                                    validator: validate_CreateApp_590945,
                                    base: "/", url: url_CreateApp_590946,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApps_590687 = ref object of OpenApiRestCall_590348
proc url_GetApps_590689(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApps_590688(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about all of your applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_590801 = query.getOrDefault("page-size")
  valid_590801 = validateParameter(valid_590801, JString, required = false,
                                 default = nil)
  if valid_590801 != nil:
    section.add "page-size", valid_590801
  var valid_590802 = query.getOrDefault("token")
  valid_590802 = validateParameter(valid_590802, JString, required = false,
                                 default = nil)
  if valid_590802 != nil:
    section.add "token", valid_590802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590803 = header.getOrDefault("X-Amz-Signature")
  valid_590803 = validateParameter(valid_590803, JString, required = false,
                                 default = nil)
  if valid_590803 != nil:
    section.add "X-Amz-Signature", valid_590803
  var valid_590804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590804 = validateParameter(valid_590804, JString, required = false,
                                 default = nil)
  if valid_590804 != nil:
    section.add "X-Amz-Content-Sha256", valid_590804
  var valid_590805 = header.getOrDefault("X-Amz-Date")
  valid_590805 = validateParameter(valid_590805, JString, required = false,
                                 default = nil)
  if valid_590805 != nil:
    section.add "X-Amz-Date", valid_590805
  var valid_590806 = header.getOrDefault("X-Amz-Credential")
  valid_590806 = validateParameter(valid_590806, JString, required = false,
                                 default = nil)
  if valid_590806 != nil:
    section.add "X-Amz-Credential", valid_590806
  var valid_590807 = header.getOrDefault("X-Amz-Security-Token")
  valid_590807 = validateParameter(valid_590807, JString, required = false,
                                 default = nil)
  if valid_590807 != nil:
    section.add "X-Amz-Security-Token", valid_590807
  var valid_590808 = header.getOrDefault("X-Amz-Algorithm")
  valid_590808 = validateParameter(valid_590808, JString, required = false,
                                 default = nil)
  if valid_590808 != nil:
    section.add "X-Amz-Algorithm", valid_590808
  var valid_590809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590809 = validateParameter(valid_590809, JString, required = false,
                                 default = nil)
  if valid_590809 != nil:
    section.add "X-Amz-SignedHeaders", valid_590809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590832: Call_GetApps_590687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all of your applications.
  ## 
  let valid = call_590832.validator(path, query, header, formData, body)
  let scheme = call_590832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590832.url(scheme.get, call_590832.host, call_590832.base,
                         call_590832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590832, url, valid)

proc call*(call_590903: Call_GetApps_590687; pageSize: string = ""; token: string = ""): Recallable =
  ## getApps
  ## Retrieves information about all of your applications.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var query_590904 = newJObject()
  add(query_590904, "page-size", newJString(pageSize))
  add(query_590904, "token", newJString(token))
  result = call_590903.call(nil, query_590904, nil, nil, nil)

var getApps* = Call_GetApps_590687(name: "getApps", meth: HttpMethod.HttpGet,
                                host: "pinpoint.amazonaws.com", route: "/v1/apps",
                                validator: validate_GetApps_590688, base: "/",
                                url: url_GetApps_590689,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCampaign_590989 = ref object of OpenApiRestCall_590348
proc url_CreateCampaign_590991(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCampaign_590990(path: JsonNode; query: JsonNode;
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
  var valid_590992 = path.getOrDefault("application-id")
  valid_590992 = validateParameter(valid_590992, JString, required = true,
                                 default = nil)
  if valid_590992 != nil:
    section.add "application-id", valid_590992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590993 = header.getOrDefault("X-Amz-Signature")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Signature", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Content-Sha256", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Date")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Date", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Credential")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Credential", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Security-Token")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Security-Token", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Algorithm")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Algorithm", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-SignedHeaders", valid_590999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591001: Call_CreateCampaign_590989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ## 
  let valid = call_591001.validator(path, query, header, formData, body)
  let scheme = call_591001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591001.url(scheme.get, call_591001.host, call_591001.base,
                         call_591001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591001, url, valid)

proc call*(call_591002: Call_CreateCampaign_590989; applicationId: string;
          body: JsonNode): Recallable =
  ## createCampaign
  ## Creates a new campaign for an application or updates the settings of an existing campaign for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591003 = newJObject()
  var body_591004 = newJObject()
  add(path_591003, "application-id", newJString(applicationId))
  if body != nil:
    body_591004 = body
  result = call_591002.call(path_591003, nil, nil, nil, body_591004)

var createCampaign* = Call_CreateCampaign_590989(name: "createCampaign",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_CreateCampaign_590990, base: "/", url: url_CreateCampaign_590991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaigns_590958 = ref object of OpenApiRestCall_590348
proc url_GetCampaigns_590960(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaigns_590959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590975 = path.getOrDefault("application-id")
  valid_590975 = validateParameter(valid_590975, JString, required = true,
                                 default = nil)
  if valid_590975 != nil:
    section.add "application-id", valid_590975
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_590976 = query.getOrDefault("page-size")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "page-size", valid_590976
  var valid_590977 = query.getOrDefault("token")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "token", valid_590977
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590978 = header.getOrDefault("X-Amz-Signature")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Signature", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Content-Sha256", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Date")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Date", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Credential")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Credential", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Security-Token")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Security-Token", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-Algorithm")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-Algorithm", valid_590983
  var valid_590984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590984 = validateParameter(valid_590984, JString, required = false,
                                 default = nil)
  if valid_590984 != nil:
    section.add "X-Amz-SignedHeaders", valid_590984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590985: Call_GetCampaigns_590958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ## 
  let valid = call_590985.validator(path, query, header, formData, body)
  let scheme = call_590985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590985.url(scheme.get, call_590985.host, call_590985.base,
                         call_590985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590985, url, valid)

proc call*(call_590986: Call_GetCampaigns_590958; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaigns
  ## Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_590987 = newJObject()
  var query_590988 = newJObject()
  add(path_590987, "application-id", newJString(applicationId))
  add(query_590988, "page-size", newJString(pageSize))
  add(query_590988, "token", newJString(token))
  result = call_590986.call(path_590987, query_590988, nil, nil, nil)

var getCampaigns* = Call_GetCampaigns_590958(name: "getCampaigns",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns",
    validator: validate_GetCampaigns_590959, base: "/", url: url_GetCampaigns_590960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailTemplate_591019 = ref object of OpenApiRestCall_590348
proc url_UpdateEmailTemplate_591021(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateEmailTemplate_591020(path: JsonNode; query: JsonNode;
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
  var valid_591022 = path.getOrDefault("template-name")
  valid_591022 = validateParameter(valid_591022, JString, required = true,
                                 default = nil)
  if valid_591022 != nil:
    section.add "template-name", valid_591022
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591023 = header.getOrDefault("X-Amz-Signature")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Signature", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Content-Sha256", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Date")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Date", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Credential")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Credential", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Security-Token")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Security-Token", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-Algorithm")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-Algorithm", valid_591028
  var valid_591029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-SignedHeaders", valid_591029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591031: Call_UpdateEmailTemplate_591019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_591031.validator(path, query, header, formData, body)
  let scheme = call_591031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591031.url(scheme.get, call_591031.host, call_591031.base,
                         call_591031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591031, url, valid)

proc call*(call_591032: Call_UpdateEmailTemplate_591019; templateName: string;
          body: JsonNode): Recallable =
  ## updateEmailTemplate
  ## Updates an existing message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591033 = newJObject()
  var body_591034 = newJObject()
  add(path_591033, "template-name", newJString(templateName))
  if body != nil:
    body_591034 = body
  result = call_591032.call(path_591033, nil, nil, nil, body_591034)

var updateEmailTemplate* = Call_UpdateEmailTemplate_591019(
    name: "updateEmailTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_UpdateEmailTemplate_591020, base: "/",
    url: url_UpdateEmailTemplate_591021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailTemplate_591035 = ref object of OpenApiRestCall_590348
proc url_CreateEmailTemplate_591037(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateEmailTemplate_591036(path: JsonNode; query: JsonNode;
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
  var valid_591038 = path.getOrDefault("template-name")
  valid_591038 = validateParameter(valid_591038, JString, required = true,
                                 default = nil)
  if valid_591038 != nil:
    section.add "template-name", valid_591038
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591039 = header.getOrDefault("X-Amz-Signature")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Signature", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Content-Sha256", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Date")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Date", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Credential")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Credential", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-Security-Token")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-Security-Token", valid_591043
  var valid_591044 = header.getOrDefault("X-Amz-Algorithm")
  valid_591044 = validateParameter(valid_591044, JString, required = false,
                                 default = nil)
  if valid_591044 != nil:
    section.add "X-Amz-Algorithm", valid_591044
  var valid_591045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-SignedHeaders", valid_591045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591047: Call_CreateEmailTemplate_591035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_591047.validator(path, query, header, formData, body)
  let scheme = call_591047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591047.url(scheme.get, call_591047.host, call_591047.base,
                         call_591047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591047, url, valid)

proc call*(call_591048: Call_CreateEmailTemplate_591035; templateName: string;
          body: JsonNode): Recallable =
  ## createEmailTemplate
  ## Creates a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591049 = newJObject()
  var body_591050 = newJObject()
  add(path_591049, "template-name", newJString(templateName))
  if body != nil:
    body_591050 = body
  result = call_591048.call(path_591049, nil, nil, nil, body_591050)

var createEmailTemplate* = Call_CreateEmailTemplate_591035(
    name: "createEmailTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_CreateEmailTemplate_591036, base: "/",
    url: url_CreateEmailTemplate_591037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailTemplate_591005 = ref object of OpenApiRestCall_590348
proc url_GetEmailTemplate_591007(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEmailTemplate_591006(path: JsonNode; query: JsonNode;
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
  var valid_591008 = path.getOrDefault("template-name")
  valid_591008 = validateParameter(valid_591008, JString, required = true,
                                 default = nil)
  if valid_591008 != nil:
    section.add "template-name", valid_591008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591009 = header.getOrDefault("X-Amz-Signature")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Signature", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Content-Sha256", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Date")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Date", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-Credential")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-Credential", valid_591012
  var valid_591013 = header.getOrDefault("X-Amz-Security-Token")
  valid_591013 = validateParameter(valid_591013, JString, required = false,
                                 default = nil)
  if valid_591013 != nil:
    section.add "X-Amz-Security-Token", valid_591013
  var valid_591014 = header.getOrDefault("X-Amz-Algorithm")
  valid_591014 = validateParameter(valid_591014, JString, required = false,
                                 default = nil)
  if valid_591014 != nil:
    section.add "X-Amz-Algorithm", valid_591014
  var valid_591015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591015 = validateParameter(valid_591015, JString, required = false,
                                 default = nil)
  if valid_591015 != nil:
    section.add "X-Amz-SignedHeaders", valid_591015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591016: Call_GetEmailTemplate_591005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ## 
  let valid = call_591016.validator(path, query, header, formData, body)
  let scheme = call_591016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591016.url(scheme.get, call_591016.host, call_591016.base,
                         call_591016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591016, url, valid)

proc call*(call_591017: Call_GetEmailTemplate_591005; templateName: string): Recallable =
  ## getEmailTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591018 = newJObject()
  add(path_591018, "template-name", newJString(templateName))
  result = call_591017.call(path_591018, nil, nil, nil, nil)

var getEmailTemplate* = Call_GetEmailTemplate_591005(name: "getEmailTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/email",
    validator: validate_GetEmailTemplate_591006, base: "/",
    url: url_GetEmailTemplate_591007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailTemplate_591051 = ref object of OpenApiRestCall_590348
proc url_DeleteEmailTemplate_591053(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteEmailTemplate_591052(path: JsonNode; query: JsonNode;
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
  var valid_591054 = path.getOrDefault("template-name")
  valid_591054 = validateParameter(valid_591054, JString, required = true,
                                 default = nil)
  if valid_591054 != nil:
    section.add "template-name", valid_591054
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591055 = header.getOrDefault("X-Amz-Signature")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Signature", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Content-Sha256", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Date")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Date", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-Credential")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Credential", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-Security-Token")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-Security-Token", valid_591059
  var valid_591060 = header.getOrDefault("X-Amz-Algorithm")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "X-Amz-Algorithm", valid_591060
  var valid_591061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-SignedHeaders", valid_591061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591062: Call_DeleteEmailTemplate_591051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ## 
  let valid = call_591062.validator(path, query, header, formData, body)
  let scheme = call_591062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591062.url(scheme.get, call_591062.host, call_591062.base,
                         call_591062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591062, url, valid)

proc call*(call_591063: Call_DeleteEmailTemplate_591051; templateName: string): Recallable =
  ## deleteEmailTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the email channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591064 = newJObject()
  add(path_591064, "template-name", newJString(templateName))
  result = call_591063.call(path_591064, nil, nil, nil, nil)

var deleteEmailTemplate* = Call_DeleteEmailTemplate_591051(
    name: "deleteEmailTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/email",
    validator: validate_DeleteEmailTemplate_591052, base: "/",
    url: url_DeleteEmailTemplate_591053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExportJob_591082 = ref object of OpenApiRestCall_590348
proc url_CreateExportJob_591084(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExportJob_591083(path: JsonNode; query: JsonNode;
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
  var valid_591085 = path.getOrDefault("application-id")
  valid_591085 = validateParameter(valid_591085, JString, required = true,
                                 default = nil)
  if valid_591085 != nil:
    section.add "application-id", valid_591085
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591086 = header.getOrDefault("X-Amz-Signature")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Signature", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Content-Sha256", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Date")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Date", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-Credential")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Credential", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Security-Token")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Security-Token", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-Algorithm")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-Algorithm", valid_591091
  var valid_591092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "X-Amz-SignedHeaders", valid_591092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591094: Call_CreateExportJob_591082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an export job for an application.
  ## 
  let valid = call_591094.validator(path, query, header, formData, body)
  let scheme = call_591094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591094.url(scheme.get, call_591094.host, call_591094.base,
                         call_591094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591094, url, valid)

proc call*(call_591095: Call_CreateExportJob_591082; applicationId: string;
          body: JsonNode): Recallable =
  ## createExportJob
  ## Creates an export job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591096 = newJObject()
  var body_591097 = newJObject()
  add(path_591096, "application-id", newJString(applicationId))
  if body != nil:
    body_591097 = body
  result = call_591095.call(path_591096, nil, nil, nil, body_591097)

var createExportJob* = Call_CreateExportJob_591082(name: "createExportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_CreateExportJob_591083, base: "/", url: url_CreateExportJob_591084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJobs_591065 = ref object of OpenApiRestCall_590348
proc url_GetExportJobs_591067(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJobs_591066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591068 = path.getOrDefault("application-id")
  valid_591068 = validateParameter(valid_591068, JString, required = true,
                                 default = nil)
  if valid_591068 != nil:
    section.add "application-id", valid_591068
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_591069 = query.getOrDefault("page-size")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "page-size", valid_591069
  var valid_591070 = query.getOrDefault("token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "token", valid_591070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591071 = header.getOrDefault("X-Amz-Signature")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Signature", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Content-Sha256", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Date")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Date", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Credential")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Credential", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Security-Token")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Security-Token", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-Algorithm")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Algorithm", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-SignedHeaders", valid_591077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591078: Call_GetExportJobs_591065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ## 
  let valid = call_591078.validator(path, query, header, formData, body)
  let scheme = call_591078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591078.url(scheme.get, call_591078.host, call_591078.base,
                         call_591078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591078, url, valid)

proc call*(call_591079: Call_GetExportJobs_591065; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getExportJobs
  ## Retrieves information about the status and settings of all the export jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_591080 = newJObject()
  var query_591081 = newJObject()
  add(path_591080, "application-id", newJString(applicationId))
  add(query_591081, "page-size", newJString(pageSize))
  add(query_591081, "token", newJString(token))
  result = call_591079.call(path_591080, query_591081, nil, nil, nil)

var getExportJobs* = Call_GetExportJobs_591065(name: "getExportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export",
    validator: validate_GetExportJobs_591066, base: "/", url: url_GetExportJobs_591067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImportJob_591115 = ref object of OpenApiRestCall_590348
proc url_CreateImportJob_591117(protocol: Scheme; host: string; base: string;
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

proc validate_CreateImportJob_591116(path: JsonNode; query: JsonNode;
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
  var valid_591118 = path.getOrDefault("application-id")
  valid_591118 = validateParameter(valid_591118, JString, required = true,
                                 default = nil)
  if valid_591118 != nil:
    section.add "application-id", valid_591118
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591119 = header.getOrDefault("X-Amz-Signature")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Signature", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Content-Sha256", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-Date")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-Date", valid_591121
  var valid_591122 = header.getOrDefault("X-Amz-Credential")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = nil)
  if valid_591122 != nil:
    section.add "X-Amz-Credential", valid_591122
  var valid_591123 = header.getOrDefault("X-Amz-Security-Token")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-Security-Token", valid_591123
  var valid_591124 = header.getOrDefault("X-Amz-Algorithm")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "X-Amz-Algorithm", valid_591124
  var valid_591125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-SignedHeaders", valid_591125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591127: Call_CreateImportJob_591115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an import job for an application.
  ## 
  let valid = call_591127.validator(path, query, header, formData, body)
  let scheme = call_591127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591127.url(scheme.get, call_591127.host, call_591127.base,
                         call_591127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591127, url, valid)

proc call*(call_591128: Call_CreateImportJob_591115; applicationId: string;
          body: JsonNode): Recallable =
  ## createImportJob
  ## Creates an import job for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591129 = newJObject()
  var body_591130 = newJObject()
  add(path_591129, "application-id", newJString(applicationId))
  if body != nil:
    body_591130 = body
  result = call_591128.call(path_591129, nil, nil, nil, body_591130)

var createImportJob* = Call_CreateImportJob_591115(name: "createImportJob",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_CreateImportJob_591116, base: "/", url: url_CreateImportJob_591117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJobs_591098 = ref object of OpenApiRestCall_590348
proc url_GetImportJobs_591100(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJobs_591099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591101 = path.getOrDefault("application-id")
  valid_591101 = validateParameter(valid_591101, JString, required = true,
                                 default = nil)
  if valid_591101 != nil:
    section.add "application-id", valid_591101
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_591102 = query.getOrDefault("page-size")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "page-size", valid_591102
  var valid_591103 = query.getOrDefault("token")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "token", valid_591103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591104 = header.getOrDefault("X-Amz-Signature")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Signature", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-Content-Sha256", valid_591105
  var valid_591106 = header.getOrDefault("X-Amz-Date")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "X-Amz-Date", valid_591106
  var valid_591107 = header.getOrDefault("X-Amz-Credential")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "X-Amz-Credential", valid_591107
  var valid_591108 = header.getOrDefault("X-Amz-Security-Token")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "X-Amz-Security-Token", valid_591108
  var valid_591109 = header.getOrDefault("X-Amz-Algorithm")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = nil)
  if valid_591109 != nil:
    section.add "X-Amz-Algorithm", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-SignedHeaders", valid_591110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591111: Call_GetImportJobs_591098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ## 
  let valid = call_591111.validator(path, query, header, formData, body)
  let scheme = call_591111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591111.url(scheme.get, call_591111.host, call_591111.base,
                         call_591111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591111, url, valid)

proc call*(call_591112: Call_GetImportJobs_591098; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getImportJobs
  ## Retrieves information about the status and settings of all the import jobs for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_591113 = newJObject()
  var query_591114 = newJObject()
  add(path_591113, "application-id", newJString(applicationId))
  add(query_591114, "page-size", newJString(pageSize))
  add(query_591114, "token", newJString(token))
  result = call_591112.call(path_591113, query_591114, nil, nil, nil)

var getImportJobs* = Call_GetImportJobs_591098(name: "getImportJobs",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import",
    validator: validate_GetImportJobs_591099, base: "/", url: url_GetImportJobs_591100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePushTemplate_591145 = ref object of OpenApiRestCall_590348
proc url_UpdatePushTemplate_591147(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdatePushTemplate_591146(path: JsonNode; query: JsonNode;
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
  var valid_591148 = path.getOrDefault("template-name")
  valid_591148 = validateParameter(valid_591148, JString, required = true,
                                 default = nil)
  if valid_591148 != nil:
    section.add "template-name", valid_591148
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591149 = header.getOrDefault("X-Amz-Signature")
  valid_591149 = validateParameter(valid_591149, JString, required = false,
                                 default = nil)
  if valid_591149 != nil:
    section.add "X-Amz-Signature", valid_591149
  var valid_591150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591150 = validateParameter(valid_591150, JString, required = false,
                                 default = nil)
  if valid_591150 != nil:
    section.add "X-Amz-Content-Sha256", valid_591150
  var valid_591151 = header.getOrDefault("X-Amz-Date")
  valid_591151 = validateParameter(valid_591151, JString, required = false,
                                 default = nil)
  if valid_591151 != nil:
    section.add "X-Amz-Date", valid_591151
  var valid_591152 = header.getOrDefault("X-Amz-Credential")
  valid_591152 = validateParameter(valid_591152, JString, required = false,
                                 default = nil)
  if valid_591152 != nil:
    section.add "X-Amz-Credential", valid_591152
  var valid_591153 = header.getOrDefault("X-Amz-Security-Token")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = nil)
  if valid_591153 != nil:
    section.add "X-Amz-Security-Token", valid_591153
  var valid_591154 = header.getOrDefault("X-Amz-Algorithm")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Algorithm", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-SignedHeaders", valid_591155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591157: Call_UpdatePushTemplate_591145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_591157.validator(path, query, header, formData, body)
  let scheme = call_591157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591157.url(scheme.get, call_591157.host, call_591157.base,
                         call_591157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591157, url, valid)

proc call*(call_591158: Call_UpdatePushTemplate_591145; templateName: string;
          body: JsonNode): Recallable =
  ## updatePushTemplate
  ## Updates an existing message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591159 = newJObject()
  var body_591160 = newJObject()
  add(path_591159, "template-name", newJString(templateName))
  if body != nil:
    body_591160 = body
  result = call_591158.call(path_591159, nil, nil, nil, body_591160)

var updatePushTemplate* = Call_UpdatePushTemplate_591145(
    name: "updatePushTemplate", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_UpdatePushTemplate_591146, base: "/",
    url: url_UpdatePushTemplate_591147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePushTemplate_591161 = ref object of OpenApiRestCall_590348
proc url_CreatePushTemplate_591163(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreatePushTemplate_591162(path: JsonNode; query: JsonNode;
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
  var valid_591164 = path.getOrDefault("template-name")
  valid_591164 = validateParameter(valid_591164, JString, required = true,
                                 default = nil)
  if valid_591164 != nil:
    section.add "template-name", valid_591164
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591165 = header.getOrDefault("X-Amz-Signature")
  valid_591165 = validateParameter(valid_591165, JString, required = false,
                                 default = nil)
  if valid_591165 != nil:
    section.add "X-Amz-Signature", valid_591165
  var valid_591166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591166 = validateParameter(valid_591166, JString, required = false,
                                 default = nil)
  if valid_591166 != nil:
    section.add "X-Amz-Content-Sha256", valid_591166
  var valid_591167 = header.getOrDefault("X-Amz-Date")
  valid_591167 = validateParameter(valid_591167, JString, required = false,
                                 default = nil)
  if valid_591167 != nil:
    section.add "X-Amz-Date", valid_591167
  var valid_591168 = header.getOrDefault("X-Amz-Credential")
  valid_591168 = validateParameter(valid_591168, JString, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "X-Amz-Credential", valid_591168
  var valid_591169 = header.getOrDefault("X-Amz-Security-Token")
  valid_591169 = validateParameter(valid_591169, JString, required = false,
                                 default = nil)
  if valid_591169 != nil:
    section.add "X-Amz-Security-Token", valid_591169
  var valid_591170 = header.getOrDefault("X-Amz-Algorithm")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Algorithm", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-SignedHeaders", valid_591171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591173: Call_CreatePushTemplate_591161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_591173.validator(path, query, header, formData, body)
  let scheme = call_591173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591173.url(scheme.get, call_591173.host, call_591173.base,
                         call_591173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591173, url, valid)

proc call*(call_591174: Call_CreatePushTemplate_591161; templateName: string;
          body: JsonNode): Recallable =
  ## createPushTemplate
  ## Creates a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591175 = newJObject()
  var body_591176 = newJObject()
  add(path_591175, "template-name", newJString(templateName))
  if body != nil:
    body_591176 = body
  result = call_591174.call(path_591175, nil, nil, nil, body_591176)

var createPushTemplate* = Call_CreatePushTemplate_591161(
    name: "createPushTemplate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_CreatePushTemplate_591162, base: "/",
    url: url_CreatePushTemplate_591163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPushTemplate_591131 = ref object of OpenApiRestCall_590348
proc url_GetPushTemplate_591133(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetPushTemplate_591132(path: JsonNode; query: JsonNode;
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
  var valid_591134 = path.getOrDefault("template-name")
  valid_591134 = validateParameter(valid_591134, JString, required = true,
                                 default = nil)
  if valid_591134 != nil:
    section.add "template-name", valid_591134
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591135 = header.getOrDefault("X-Amz-Signature")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "X-Amz-Signature", valid_591135
  var valid_591136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591136 = validateParameter(valid_591136, JString, required = false,
                                 default = nil)
  if valid_591136 != nil:
    section.add "X-Amz-Content-Sha256", valid_591136
  var valid_591137 = header.getOrDefault("X-Amz-Date")
  valid_591137 = validateParameter(valid_591137, JString, required = false,
                                 default = nil)
  if valid_591137 != nil:
    section.add "X-Amz-Date", valid_591137
  var valid_591138 = header.getOrDefault("X-Amz-Credential")
  valid_591138 = validateParameter(valid_591138, JString, required = false,
                                 default = nil)
  if valid_591138 != nil:
    section.add "X-Amz-Credential", valid_591138
  var valid_591139 = header.getOrDefault("X-Amz-Security-Token")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "X-Amz-Security-Token", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Algorithm")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Algorithm", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-SignedHeaders", valid_591141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591142: Call_GetPushTemplate_591131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ## 
  let valid = call_591142.validator(path, query, header, formData, body)
  let scheme = call_591142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591142.url(scheme.get, call_591142.host, call_591142.base,
                         call_591142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591142, url, valid)

proc call*(call_591143: Call_GetPushTemplate_591131; templateName: string): Recallable =
  ## getPushTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591144 = newJObject()
  add(path_591144, "template-name", newJString(templateName))
  result = call_591143.call(path_591144, nil, nil, nil, nil)

var getPushTemplate* = Call_GetPushTemplate_591131(name: "getPushTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/push",
    validator: validate_GetPushTemplate_591132, base: "/", url: url_GetPushTemplate_591133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePushTemplate_591177 = ref object of OpenApiRestCall_590348
proc url_DeletePushTemplate_591179(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeletePushTemplate_591178(path: JsonNode; query: JsonNode;
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
  var valid_591180 = path.getOrDefault("template-name")
  valid_591180 = validateParameter(valid_591180, JString, required = true,
                                 default = nil)
  if valid_591180 != nil:
    section.add "template-name", valid_591180
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591181 = header.getOrDefault("X-Amz-Signature")
  valid_591181 = validateParameter(valid_591181, JString, required = false,
                                 default = nil)
  if valid_591181 != nil:
    section.add "X-Amz-Signature", valid_591181
  var valid_591182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591182 = validateParameter(valid_591182, JString, required = false,
                                 default = nil)
  if valid_591182 != nil:
    section.add "X-Amz-Content-Sha256", valid_591182
  var valid_591183 = header.getOrDefault("X-Amz-Date")
  valid_591183 = validateParameter(valid_591183, JString, required = false,
                                 default = nil)
  if valid_591183 != nil:
    section.add "X-Amz-Date", valid_591183
  var valid_591184 = header.getOrDefault("X-Amz-Credential")
  valid_591184 = validateParameter(valid_591184, JString, required = false,
                                 default = nil)
  if valid_591184 != nil:
    section.add "X-Amz-Credential", valid_591184
  var valid_591185 = header.getOrDefault("X-Amz-Security-Token")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Security-Token", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Algorithm")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Algorithm", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-SignedHeaders", valid_591187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591188: Call_DeletePushTemplate_591177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ## 
  let valid = call_591188.validator(path, query, header, formData, body)
  let scheme = call_591188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591188.url(scheme.get, call_591188.host, call_591188.base,
                         call_591188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591188, url, valid)

proc call*(call_591189: Call_DeletePushTemplate_591177; templateName: string): Recallable =
  ## deletePushTemplate
  ## Deletes a message template that was designed for use in messages that were sent through a push notification channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591190 = newJObject()
  add(path_591190, "template-name", newJString(templateName))
  result = call_591189.call(path_591190, nil, nil, nil, nil)

var deletePushTemplate* = Call_DeletePushTemplate_591177(
    name: "deletePushTemplate", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com", route: "/v1/templates/{template-name}/push",
    validator: validate_DeletePushTemplate_591178, base: "/",
    url: url_DeletePushTemplate_591179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSegment_591208 = ref object of OpenApiRestCall_590348
proc url_CreateSegment_591210(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSegment_591209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591211 = path.getOrDefault("application-id")
  valid_591211 = validateParameter(valid_591211, JString, required = true,
                                 default = nil)
  if valid_591211 != nil:
    section.add "application-id", valid_591211
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591212 = header.getOrDefault("X-Amz-Signature")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-Signature", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Content-Sha256", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-Date")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-Date", valid_591214
  var valid_591215 = header.getOrDefault("X-Amz-Credential")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "X-Amz-Credential", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Security-Token")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Security-Token", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Algorithm")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Algorithm", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-SignedHeaders", valid_591218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591220: Call_CreateSegment_591208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_591220.validator(path, query, header, formData, body)
  let scheme = call_591220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591220.url(scheme.get, call_591220.host, call_591220.base,
                         call_591220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591220, url, valid)

proc call*(call_591221: Call_CreateSegment_591208; applicationId: string;
          body: JsonNode): Recallable =
  ## createSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591222 = newJObject()
  var body_591223 = newJObject()
  add(path_591222, "application-id", newJString(applicationId))
  if body != nil:
    body_591223 = body
  result = call_591221.call(path_591222, nil, nil, nil, body_591223)

var createSegment* = Call_CreateSegment_591208(name: "createSegment",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments",
    validator: validate_CreateSegment_591209, base: "/", url: url_CreateSegment_591210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegments_591191 = ref object of OpenApiRestCall_590348
proc url_GetSegments_591193(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegments_591192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591194 = path.getOrDefault("application-id")
  valid_591194 = validateParameter(valid_591194, JString, required = true,
                                 default = nil)
  if valid_591194 != nil:
    section.add "application-id", valid_591194
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_591195 = query.getOrDefault("page-size")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "page-size", valid_591195
  var valid_591196 = query.getOrDefault("token")
  valid_591196 = validateParameter(valid_591196, JString, required = false,
                                 default = nil)
  if valid_591196 != nil:
    section.add "token", valid_591196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591197 = header.getOrDefault("X-Amz-Signature")
  valid_591197 = validateParameter(valid_591197, JString, required = false,
                                 default = nil)
  if valid_591197 != nil:
    section.add "X-Amz-Signature", valid_591197
  var valid_591198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "X-Amz-Content-Sha256", valid_591198
  var valid_591199 = header.getOrDefault("X-Amz-Date")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "X-Amz-Date", valid_591199
  var valid_591200 = header.getOrDefault("X-Amz-Credential")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Credential", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Security-Token")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Security-Token", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Algorithm")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Algorithm", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-SignedHeaders", valid_591203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591204: Call_GetSegments_591191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ## 
  let valid = call_591204.validator(path, query, header, formData, body)
  let scheme = call_591204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591204.url(scheme.get, call_591204.host, call_591204.base,
                         call_591204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591204, url, valid)

proc call*(call_591205: Call_GetSegments_591191; applicationId: string;
          pageSize: string = ""; token: string = ""): Recallable =
  ## getSegments
  ## Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_591206 = newJObject()
  var query_591207 = newJObject()
  add(path_591206, "application-id", newJString(applicationId))
  add(query_591207, "page-size", newJString(pageSize))
  add(query_591207, "token", newJString(token))
  result = call_591205.call(path_591206, query_591207, nil, nil, nil)

var getSegments* = Call_GetSegments_591191(name: "getSegments",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments",
                                        validator: validate_GetSegments_591192,
                                        base: "/", url: url_GetSegments_591193,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsTemplate_591238 = ref object of OpenApiRestCall_590348
proc url_UpdateSmsTemplate_591240(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateSmsTemplate_591239(path: JsonNode; query: JsonNode;
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
  var valid_591241 = path.getOrDefault("template-name")
  valid_591241 = validateParameter(valid_591241, JString, required = true,
                                 default = nil)
  if valid_591241 != nil:
    section.add "template-name", valid_591241
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591242 = header.getOrDefault("X-Amz-Signature")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Signature", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Content-Sha256", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Date")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Date", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-Credential")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Credential", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Security-Token")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Security-Token", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Algorithm")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Algorithm", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-SignedHeaders", valid_591248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591250: Call_UpdateSmsTemplate_591238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_591250.validator(path, query, header, formData, body)
  let scheme = call_591250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591250.url(scheme.get, call_591250.host, call_591250.base,
                         call_591250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591250, url, valid)

proc call*(call_591251: Call_UpdateSmsTemplate_591238; templateName: string;
          body: JsonNode): Recallable =
  ## updateSmsTemplate
  ## Updates an existing message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591252 = newJObject()
  var body_591253 = newJObject()
  add(path_591252, "template-name", newJString(templateName))
  if body != nil:
    body_591253 = body
  result = call_591251.call(path_591252, nil, nil, nil, body_591253)

var updateSmsTemplate* = Call_UpdateSmsTemplate_591238(name: "updateSmsTemplate",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_UpdateSmsTemplate_591239, base: "/",
    url: url_UpdateSmsTemplate_591240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSmsTemplate_591254 = ref object of OpenApiRestCall_590348
proc url_CreateSmsTemplate_591256(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateSmsTemplate_591255(path: JsonNode; query: JsonNode;
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
  var valid_591257 = path.getOrDefault("template-name")
  valid_591257 = validateParameter(valid_591257, JString, required = true,
                                 default = nil)
  if valid_591257 != nil:
    section.add "template-name", valid_591257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591258 = header.getOrDefault("X-Amz-Signature")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Signature", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Content-Sha256", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Date")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Date", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Credential")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Credential", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Security-Token")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Security-Token", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Algorithm")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Algorithm", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-SignedHeaders", valid_591264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591266: Call_CreateSmsTemplate_591254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_591266.validator(path, query, header, formData, body)
  let scheme = call_591266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591266.url(scheme.get, call_591266.host, call_591266.base,
                         call_591266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591266, url, valid)

proc call*(call_591267: Call_CreateSmsTemplate_591254; templateName: string;
          body: JsonNode): Recallable =
  ## createSmsTemplate
  ## Creates a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  ##   body: JObject (required)
  var path_591268 = newJObject()
  var body_591269 = newJObject()
  add(path_591268, "template-name", newJString(templateName))
  if body != nil:
    body_591269 = body
  result = call_591267.call(path_591268, nil, nil, nil, body_591269)

var createSmsTemplate* = Call_CreateSmsTemplate_591254(name: "createSmsTemplate",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_CreateSmsTemplate_591255, base: "/",
    url: url_CreateSmsTemplate_591256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsTemplate_591224 = ref object of OpenApiRestCall_590348
proc url_GetSmsTemplate_591226(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSmsTemplate_591225(path: JsonNode; query: JsonNode;
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
  var valid_591227 = path.getOrDefault("template-name")
  valid_591227 = validateParameter(valid_591227, JString, required = true,
                                 default = nil)
  if valid_591227 != nil:
    section.add "template-name", valid_591227
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591228 = header.getOrDefault("X-Amz-Signature")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Signature", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-Content-Sha256", valid_591229
  var valid_591230 = header.getOrDefault("X-Amz-Date")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Date", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Credential")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Credential", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Security-Token")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Security-Token", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Algorithm")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Algorithm", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-SignedHeaders", valid_591234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591235: Call_GetSmsTemplate_591224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ## 
  let valid = call_591235.validator(path, query, header, formData, body)
  let scheme = call_591235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591235.url(scheme.get, call_591235.host, call_591235.base,
                         call_591235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591235, url, valid)

proc call*(call_591236: Call_GetSmsTemplate_591224; templateName: string): Recallable =
  ## getSmsTemplate
  ## Retrieves the content and settings for a message template that you can use in messages that are sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591237 = newJObject()
  add(path_591237, "template-name", newJString(templateName))
  result = call_591236.call(path_591237, nil, nil, nil, nil)

var getSmsTemplate* = Call_GetSmsTemplate_591224(name: "getSmsTemplate",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_GetSmsTemplate_591225, base: "/", url: url_GetSmsTemplate_591226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsTemplate_591270 = ref object of OpenApiRestCall_590348
proc url_DeleteSmsTemplate_591272(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteSmsTemplate_591271(path: JsonNode; query: JsonNode;
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
  var valid_591273 = path.getOrDefault("template-name")
  valid_591273 = validateParameter(valid_591273, JString, required = true,
                                 default = nil)
  if valid_591273 != nil:
    section.add "template-name", valid_591273
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591274 = header.getOrDefault("X-Amz-Signature")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Signature", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Content-Sha256", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Date")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Date", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Credential")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Credential", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Security-Token")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Security-Token", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Algorithm")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Algorithm", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-SignedHeaders", valid_591280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591281: Call_DeleteSmsTemplate_591270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ## 
  let valid = call_591281.validator(path, query, header, formData, body)
  let scheme = call_591281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591281.url(scheme.get, call_591281.host, call_591281.base,
                         call_591281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591281, url, valid)

proc call*(call_591282: Call_DeleteSmsTemplate_591270; templateName: string): Recallable =
  ## deleteSmsTemplate
  ## Deletes a message template that was designed for use in messages that were sent through the SMS channel.
  ##   templateName: string (required)
  ##               : The name of the message template. A template name must start with an alphanumeric character and can contain a maximum of 128 characters. The characters can be alphanumeric characters, underscores (_), or hyphens (-). Template names are case sensitive.
  var path_591283 = newJObject()
  add(path_591283, "template-name", newJString(templateName))
  result = call_591282.call(path_591283, nil, nil, nil, nil)

var deleteSmsTemplate* = Call_DeleteSmsTemplate_591270(name: "deleteSmsTemplate",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/templates/{template-name}/sms",
    validator: validate_DeleteSmsTemplate_591271, base: "/",
    url: url_DeleteSmsTemplate_591272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAdmChannel_591298 = ref object of OpenApiRestCall_590348
proc url_UpdateAdmChannel_591300(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAdmChannel_591299(path: JsonNode; query: JsonNode;
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
  var valid_591301 = path.getOrDefault("application-id")
  valid_591301 = validateParameter(valid_591301, JString, required = true,
                                 default = nil)
  if valid_591301 != nil:
    section.add "application-id", valid_591301
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591302 = header.getOrDefault("X-Amz-Signature")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-Signature", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Content-Sha256", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Date")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Date", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Credential")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Credential", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Security-Token")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Security-Token", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Algorithm")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Algorithm", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-SignedHeaders", valid_591308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591310: Call_UpdateAdmChannel_591298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ## 
  let valid = call_591310.validator(path, query, header, formData, body)
  let scheme = call_591310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591310.url(scheme.get, call_591310.host, call_591310.base,
                         call_591310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591310, url, valid)

proc call*(call_591311: Call_UpdateAdmChannel_591298; applicationId: string;
          body: JsonNode): Recallable =
  ## updateAdmChannel
  ## Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591312 = newJObject()
  var body_591313 = newJObject()
  add(path_591312, "application-id", newJString(applicationId))
  if body != nil:
    body_591313 = body
  result = call_591311.call(path_591312, nil, nil, nil, body_591313)

var updateAdmChannel* = Call_UpdateAdmChannel_591298(name: "updateAdmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_UpdateAdmChannel_591299, base: "/",
    url: url_UpdateAdmChannel_591300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdmChannel_591284 = ref object of OpenApiRestCall_590348
proc url_GetAdmChannel_591286(protocol: Scheme; host: string; base: string;
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

proc validate_GetAdmChannel_591285(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591287 = path.getOrDefault("application-id")
  valid_591287 = validateParameter(valid_591287, JString, required = true,
                                 default = nil)
  if valid_591287 != nil:
    section.add "application-id", valid_591287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591288 = header.getOrDefault("X-Amz-Signature")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Signature", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Content-Sha256", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Date")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Date", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Credential")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Credential", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Security-Token")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Security-Token", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Algorithm")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Algorithm", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-SignedHeaders", valid_591294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591295: Call_GetAdmChannel_591284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ## 
  let valid = call_591295.validator(path, query, header, formData, body)
  let scheme = call_591295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591295.url(scheme.get, call_591295.host, call_591295.base,
                         call_591295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591295, url, valid)

proc call*(call_591296: Call_GetAdmChannel_591284; applicationId: string): Recallable =
  ## getAdmChannel
  ## Retrieves information about the status and settings of the ADM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591297 = newJObject()
  add(path_591297, "application-id", newJString(applicationId))
  result = call_591296.call(path_591297, nil, nil, nil, nil)

var getAdmChannel* = Call_GetAdmChannel_591284(name: "getAdmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_GetAdmChannel_591285, base: "/", url: url_GetAdmChannel_591286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAdmChannel_591314 = ref object of OpenApiRestCall_590348
proc url_DeleteAdmChannel_591316(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAdmChannel_591315(path: JsonNode; query: JsonNode;
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
  var valid_591317 = path.getOrDefault("application-id")
  valid_591317 = validateParameter(valid_591317, JString, required = true,
                                 default = nil)
  if valid_591317 != nil:
    section.add "application-id", valid_591317
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591318 = header.getOrDefault("X-Amz-Signature")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "X-Amz-Signature", valid_591318
  var valid_591319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "X-Amz-Content-Sha256", valid_591319
  var valid_591320 = header.getOrDefault("X-Amz-Date")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Date", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Credential")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Credential", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Security-Token")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Security-Token", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Algorithm")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Algorithm", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-SignedHeaders", valid_591324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591325: Call_DeleteAdmChannel_591314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591325.validator(path, query, header, formData, body)
  let scheme = call_591325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591325.url(scheme.get, call_591325.host, call_591325.base,
                         call_591325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591325, url, valid)

proc call*(call_591326: Call_DeleteAdmChannel_591314; applicationId: string): Recallable =
  ## deleteAdmChannel
  ## Disables the ADM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591327 = newJObject()
  add(path_591327, "application-id", newJString(applicationId))
  result = call_591326.call(path_591327, nil, nil, nil, nil)

var deleteAdmChannel* = Call_DeleteAdmChannel_591314(name: "deleteAdmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/adm",
    validator: validate_DeleteAdmChannel_591315, base: "/",
    url: url_DeleteAdmChannel_591316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsChannel_591342 = ref object of OpenApiRestCall_590348
proc url_UpdateApnsChannel_591344(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsChannel_591343(path: JsonNode; query: JsonNode;
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
  var valid_591345 = path.getOrDefault("application-id")
  valid_591345 = validateParameter(valid_591345, JString, required = true,
                                 default = nil)
  if valid_591345 != nil:
    section.add "application-id", valid_591345
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591346 = header.getOrDefault("X-Amz-Signature")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Signature", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Content-Sha256", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Date")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Date", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Credential")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Credential", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Security-Token")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Security-Token", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Algorithm")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Algorithm", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-SignedHeaders", valid_591352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591354: Call_UpdateApnsChannel_591342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ## 
  let valid = call_591354.validator(path, query, header, formData, body)
  let scheme = call_591354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591354.url(scheme.get, call_591354.host, call_591354.base,
                         call_591354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591354, url, valid)

proc call*(call_591355: Call_UpdateApnsChannel_591342; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsChannel
  ## Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591356 = newJObject()
  var body_591357 = newJObject()
  add(path_591356, "application-id", newJString(applicationId))
  if body != nil:
    body_591357 = body
  result = call_591355.call(path_591356, nil, nil, nil, body_591357)

var updateApnsChannel* = Call_UpdateApnsChannel_591342(name: "updateApnsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_UpdateApnsChannel_591343, base: "/",
    url: url_UpdateApnsChannel_591344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsChannel_591328 = ref object of OpenApiRestCall_590348
proc url_GetApnsChannel_591330(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsChannel_591329(path: JsonNode; query: JsonNode;
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
  var valid_591331 = path.getOrDefault("application-id")
  valid_591331 = validateParameter(valid_591331, JString, required = true,
                                 default = nil)
  if valid_591331 != nil:
    section.add "application-id", valid_591331
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591332 = header.getOrDefault("X-Amz-Signature")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-Signature", valid_591332
  var valid_591333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Content-Sha256", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Date")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Date", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Credential")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Credential", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Security-Token")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Security-Token", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Algorithm")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Algorithm", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-SignedHeaders", valid_591338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591339: Call_GetApnsChannel_591328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ## 
  let valid = call_591339.validator(path, query, header, formData, body)
  let scheme = call_591339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591339.url(scheme.get, call_591339.host, call_591339.base,
                         call_591339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591339, url, valid)

proc call*(call_591340: Call_GetApnsChannel_591328; applicationId: string): Recallable =
  ## getApnsChannel
  ## Retrieves information about the status and settings of the APNs channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591341 = newJObject()
  add(path_591341, "application-id", newJString(applicationId))
  result = call_591340.call(path_591341, nil, nil, nil, nil)

var getApnsChannel* = Call_GetApnsChannel_591328(name: "getApnsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_GetApnsChannel_591329, base: "/", url: url_GetApnsChannel_591330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsChannel_591358 = ref object of OpenApiRestCall_590348
proc url_DeleteApnsChannel_591360(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsChannel_591359(path: JsonNode; query: JsonNode;
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
  var valid_591361 = path.getOrDefault("application-id")
  valid_591361 = validateParameter(valid_591361, JString, required = true,
                                 default = nil)
  if valid_591361 != nil:
    section.add "application-id", valid_591361
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591362 = header.getOrDefault("X-Amz-Signature")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "X-Amz-Signature", valid_591362
  var valid_591363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-Content-Sha256", valid_591363
  var valid_591364 = header.getOrDefault("X-Amz-Date")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Date", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-Credential")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-Credential", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Security-Token")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Security-Token", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Algorithm")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Algorithm", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-SignedHeaders", valid_591368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591369: Call_DeleteApnsChannel_591358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591369.validator(path, query, header, formData, body)
  let scheme = call_591369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591369.url(scheme.get, call_591369.host, call_591369.base,
                         call_591369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591369, url, valid)

proc call*(call_591370: Call_DeleteApnsChannel_591358; applicationId: string): Recallable =
  ## deleteApnsChannel
  ## Disables the APNs channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591371 = newJObject()
  add(path_591371, "application-id", newJString(applicationId))
  result = call_591370.call(path_591371, nil, nil, nil, nil)

var deleteApnsChannel* = Call_DeleteApnsChannel_591358(name: "deleteApnsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns",
    validator: validate_DeleteApnsChannel_591359, base: "/",
    url: url_DeleteApnsChannel_591360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsSandboxChannel_591386 = ref object of OpenApiRestCall_590348
proc url_UpdateApnsSandboxChannel_591388(protocol: Scheme; host: string;
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

proc validate_UpdateApnsSandboxChannel_591387(path: JsonNode; query: JsonNode;
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
  var valid_591389 = path.getOrDefault("application-id")
  valid_591389 = validateParameter(valid_591389, JString, required = true,
                                 default = nil)
  if valid_591389 != nil:
    section.add "application-id", valid_591389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591390 = header.getOrDefault("X-Amz-Signature")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-Signature", valid_591390
  var valid_591391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-Content-Sha256", valid_591391
  var valid_591392 = header.getOrDefault("X-Amz-Date")
  valid_591392 = validateParameter(valid_591392, JString, required = false,
                                 default = nil)
  if valid_591392 != nil:
    section.add "X-Amz-Date", valid_591392
  var valid_591393 = header.getOrDefault("X-Amz-Credential")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-Credential", valid_591393
  var valid_591394 = header.getOrDefault("X-Amz-Security-Token")
  valid_591394 = validateParameter(valid_591394, JString, required = false,
                                 default = nil)
  if valid_591394 != nil:
    section.add "X-Amz-Security-Token", valid_591394
  var valid_591395 = header.getOrDefault("X-Amz-Algorithm")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-Algorithm", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-SignedHeaders", valid_591396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591398: Call_UpdateApnsSandboxChannel_591386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_591398.validator(path, query, header, formData, body)
  let scheme = call_591398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591398.url(scheme.get, call_591398.host, call_591398.base,
                         call_591398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591398, url, valid)

proc call*(call_591399: Call_UpdateApnsSandboxChannel_591386;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsSandboxChannel
  ## Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591400 = newJObject()
  var body_591401 = newJObject()
  add(path_591400, "application-id", newJString(applicationId))
  if body != nil:
    body_591401 = body
  result = call_591399.call(path_591400, nil, nil, nil, body_591401)

var updateApnsSandboxChannel* = Call_UpdateApnsSandboxChannel_591386(
    name: "updateApnsSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_UpdateApnsSandboxChannel_591387, base: "/",
    url: url_UpdateApnsSandboxChannel_591388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsSandboxChannel_591372 = ref object of OpenApiRestCall_590348
proc url_GetApnsSandboxChannel_591374(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsSandboxChannel_591373(path: JsonNode; query: JsonNode;
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
  var valid_591375 = path.getOrDefault("application-id")
  valid_591375 = validateParameter(valid_591375, JString, required = true,
                                 default = nil)
  if valid_591375 != nil:
    section.add "application-id", valid_591375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591376 = header.getOrDefault("X-Amz-Signature")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-Signature", valid_591376
  var valid_591377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Content-Sha256", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-Date")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-Date", valid_591378
  var valid_591379 = header.getOrDefault("X-Amz-Credential")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-Credential", valid_591379
  var valid_591380 = header.getOrDefault("X-Amz-Security-Token")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = nil)
  if valid_591380 != nil:
    section.add "X-Amz-Security-Token", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Algorithm")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Algorithm", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-SignedHeaders", valid_591382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591383: Call_GetApnsSandboxChannel_591372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ## 
  let valid = call_591383.validator(path, query, header, formData, body)
  let scheme = call_591383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591383.url(scheme.get, call_591383.host, call_591383.base,
                         call_591383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591383, url, valid)

proc call*(call_591384: Call_GetApnsSandboxChannel_591372; applicationId: string): Recallable =
  ## getApnsSandboxChannel
  ## Retrieves information about the status and settings of the APNs sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591385 = newJObject()
  add(path_591385, "application-id", newJString(applicationId))
  result = call_591384.call(path_591385, nil, nil, nil, nil)

var getApnsSandboxChannel* = Call_GetApnsSandboxChannel_591372(
    name: "getApnsSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_GetApnsSandboxChannel_591373, base: "/",
    url: url_GetApnsSandboxChannel_591374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsSandboxChannel_591402 = ref object of OpenApiRestCall_590348
proc url_DeleteApnsSandboxChannel_591404(protocol: Scheme; host: string;
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

proc validate_DeleteApnsSandboxChannel_591403(path: JsonNode; query: JsonNode;
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
  var valid_591405 = path.getOrDefault("application-id")
  valid_591405 = validateParameter(valid_591405, JString, required = true,
                                 default = nil)
  if valid_591405 != nil:
    section.add "application-id", valid_591405
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591406 = header.getOrDefault("X-Amz-Signature")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Signature", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-Content-Sha256", valid_591407
  var valid_591408 = header.getOrDefault("X-Amz-Date")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-Date", valid_591408
  var valid_591409 = header.getOrDefault("X-Amz-Credential")
  valid_591409 = validateParameter(valid_591409, JString, required = false,
                                 default = nil)
  if valid_591409 != nil:
    section.add "X-Amz-Credential", valid_591409
  var valid_591410 = header.getOrDefault("X-Amz-Security-Token")
  valid_591410 = validateParameter(valid_591410, JString, required = false,
                                 default = nil)
  if valid_591410 != nil:
    section.add "X-Amz-Security-Token", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Algorithm")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Algorithm", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-SignedHeaders", valid_591412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591413: Call_DeleteApnsSandboxChannel_591402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591413.validator(path, query, header, formData, body)
  let scheme = call_591413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591413.url(scheme.get, call_591413.host, call_591413.base,
                         call_591413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591413, url, valid)

proc call*(call_591414: Call_DeleteApnsSandboxChannel_591402; applicationId: string): Recallable =
  ## deleteApnsSandboxChannel
  ## Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591415 = newJObject()
  add(path_591415, "application-id", newJString(applicationId))
  result = call_591414.call(path_591415, nil, nil, nil, nil)

var deleteApnsSandboxChannel* = Call_DeleteApnsSandboxChannel_591402(
    name: "deleteApnsSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_sandbox",
    validator: validate_DeleteApnsSandboxChannel_591403, base: "/",
    url: url_DeleteApnsSandboxChannel_591404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipChannel_591430 = ref object of OpenApiRestCall_590348
proc url_UpdateApnsVoipChannel_591432(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApnsVoipChannel_591431(path: JsonNode; query: JsonNode;
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
  var valid_591433 = path.getOrDefault("application-id")
  valid_591433 = validateParameter(valid_591433, JString, required = true,
                                 default = nil)
  if valid_591433 != nil:
    section.add "application-id", valid_591433
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591434 = header.getOrDefault("X-Amz-Signature")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Signature", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Content-Sha256", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-Date")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-Date", valid_591436
  var valid_591437 = header.getOrDefault("X-Amz-Credential")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "X-Amz-Credential", valid_591437
  var valid_591438 = header.getOrDefault("X-Amz-Security-Token")
  valid_591438 = validateParameter(valid_591438, JString, required = false,
                                 default = nil)
  if valid_591438 != nil:
    section.add "X-Amz-Security-Token", valid_591438
  var valid_591439 = header.getOrDefault("X-Amz-Algorithm")
  valid_591439 = validateParameter(valid_591439, JString, required = false,
                                 default = nil)
  if valid_591439 != nil:
    section.add "X-Amz-Algorithm", valid_591439
  var valid_591440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591440 = validateParameter(valid_591440, JString, required = false,
                                 default = nil)
  if valid_591440 != nil:
    section.add "X-Amz-SignedHeaders", valid_591440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591442: Call_UpdateApnsVoipChannel_591430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_591442.validator(path, query, header, formData, body)
  let scheme = call_591442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591442.url(scheme.get, call_591442.host, call_591442.base,
                         call_591442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591442, url, valid)

proc call*(call_591443: Call_UpdateApnsVoipChannel_591430; applicationId: string;
          body: JsonNode): Recallable =
  ## updateApnsVoipChannel
  ## Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591444 = newJObject()
  var body_591445 = newJObject()
  add(path_591444, "application-id", newJString(applicationId))
  if body != nil:
    body_591445 = body
  result = call_591443.call(path_591444, nil, nil, nil, body_591445)

var updateApnsVoipChannel* = Call_UpdateApnsVoipChannel_591430(
    name: "updateApnsVoipChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_UpdateApnsVoipChannel_591431, base: "/",
    url: url_UpdateApnsVoipChannel_591432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipChannel_591416 = ref object of OpenApiRestCall_590348
proc url_GetApnsVoipChannel_591418(protocol: Scheme; host: string; base: string;
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

proc validate_GetApnsVoipChannel_591417(path: JsonNode; query: JsonNode;
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
  var valid_591419 = path.getOrDefault("application-id")
  valid_591419 = validateParameter(valid_591419, JString, required = true,
                                 default = nil)
  if valid_591419 != nil:
    section.add "application-id", valid_591419
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591420 = header.getOrDefault("X-Amz-Signature")
  valid_591420 = validateParameter(valid_591420, JString, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "X-Amz-Signature", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-Content-Sha256", valid_591421
  var valid_591422 = header.getOrDefault("X-Amz-Date")
  valid_591422 = validateParameter(valid_591422, JString, required = false,
                                 default = nil)
  if valid_591422 != nil:
    section.add "X-Amz-Date", valid_591422
  var valid_591423 = header.getOrDefault("X-Amz-Credential")
  valid_591423 = validateParameter(valid_591423, JString, required = false,
                                 default = nil)
  if valid_591423 != nil:
    section.add "X-Amz-Credential", valid_591423
  var valid_591424 = header.getOrDefault("X-Amz-Security-Token")
  valid_591424 = validateParameter(valid_591424, JString, required = false,
                                 default = nil)
  if valid_591424 != nil:
    section.add "X-Amz-Security-Token", valid_591424
  var valid_591425 = header.getOrDefault("X-Amz-Algorithm")
  valid_591425 = validateParameter(valid_591425, JString, required = false,
                                 default = nil)
  if valid_591425 != nil:
    section.add "X-Amz-Algorithm", valid_591425
  var valid_591426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-SignedHeaders", valid_591426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591427: Call_GetApnsVoipChannel_591416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ## 
  let valid = call_591427.validator(path, query, header, formData, body)
  let scheme = call_591427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591427.url(scheme.get, call_591427.host, call_591427.base,
                         call_591427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591427, url, valid)

proc call*(call_591428: Call_GetApnsVoipChannel_591416; applicationId: string): Recallable =
  ## getApnsVoipChannel
  ## Retrieves information about the status and settings of the APNs VoIP channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591429 = newJObject()
  add(path_591429, "application-id", newJString(applicationId))
  result = call_591428.call(path_591429, nil, nil, nil, nil)

var getApnsVoipChannel* = Call_GetApnsVoipChannel_591416(
    name: "getApnsVoipChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_GetApnsVoipChannel_591417, base: "/",
    url: url_GetApnsVoipChannel_591418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipChannel_591446 = ref object of OpenApiRestCall_590348
proc url_DeleteApnsVoipChannel_591448(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApnsVoipChannel_591447(path: JsonNode; query: JsonNode;
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
  var valid_591449 = path.getOrDefault("application-id")
  valid_591449 = validateParameter(valid_591449, JString, required = true,
                                 default = nil)
  if valid_591449 != nil:
    section.add "application-id", valid_591449
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591450 = header.getOrDefault("X-Amz-Signature")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Signature", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-Content-Sha256", valid_591451
  var valid_591452 = header.getOrDefault("X-Amz-Date")
  valid_591452 = validateParameter(valid_591452, JString, required = false,
                                 default = nil)
  if valid_591452 != nil:
    section.add "X-Amz-Date", valid_591452
  var valid_591453 = header.getOrDefault("X-Amz-Credential")
  valid_591453 = validateParameter(valid_591453, JString, required = false,
                                 default = nil)
  if valid_591453 != nil:
    section.add "X-Amz-Credential", valid_591453
  var valid_591454 = header.getOrDefault("X-Amz-Security-Token")
  valid_591454 = validateParameter(valid_591454, JString, required = false,
                                 default = nil)
  if valid_591454 != nil:
    section.add "X-Amz-Security-Token", valid_591454
  var valid_591455 = header.getOrDefault("X-Amz-Algorithm")
  valid_591455 = validateParameter(valid_591455, JString, required = false,
                                 default = nil)
  if valid_591455 != nil:
    section.add "X-Amz-Algorithm", valid_591455
  var valid_591456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591456 = validateParameter(valid_591456, JString, required = false,
                                 default = nil)
  if valid_591456 != nil:
    section.add "X-Amz-SignedHeaders", valid_591456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591457: Call_DeleteApnsVoipChannel_591446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591457.validator(path, query, header, formData, body)
  let scheme = call_591457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591457.url(scheme.get, call_591457.host, call_591457.base,
                         call_591457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591457, url, valid)

proc call*(call_591458: Call_DeleteApnsVoipChannel_591446; applicationId: string): Recallable =
  ## deleteApnsVoipChannel
  ## Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591459 = newJObject()
  add(path_591459, "application-id", newJString(applicationId))
  result = call_591458.call(path_591459, nil, nil, nil, nil)

var deleteApnsVoipChannel* = Call_DeleteApnsVoipChannel_591446(
    name: "deleteApnsVoipChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip",
    validator: validate_DeleteApnsVoipChannel_591447, base: "/",
    url: url_DeleteApnsVoipChannel_591448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApnsVoipSandboxChannel_591474 = ref object of OpenApiRestCall_590348
proc url_UpdateApnsVoipSandboxChannel_591476(protocol: Scheme; host: string;
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

proc validate_UpdateApnsVoipSandboxChannel_591475(path: JsonNode; query: JsonNode;
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
  var valid_591477 = path.getOrDefault("application-id")
  valid_591477 = validateParameter(valid_591477, JString, required = true,
                                 default = nil)
  if valid_591477 != nil:
    section.add "application-id", valid_591477
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591478 = header.getOrDefault("X-Amz-Signature")
  valid_591478 = validateParameter(valid_591478, JString, required = false,
                                 default = nil)
  if valid_591478 != nil:
    section.add "X-Amz-Signature", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Content-Sha256", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Date")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Date", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-Credential")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-Credential", valid_591481
  var valid_591482 = header.getOrDefault("X-Amz-Security-Token")
  valid_591482 = validateParameter(valid_591482, JString, required = false,
                                 default = nil)
  if valid_591482 != nil:
    section.add "X-Amz-Security-Token", valid_591482
  var valid_591483 = header.getOrDefault("X-Amz-Algorithm")
  valid_591483 = validateParameter(valid_591483, JString, required = false,
                                 default = nil)
  if valid_591483 != nil:
    section.add "X-Amz-Algorithm", valid_591483
  var valid_591484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591484 = validateParameter(valid_591484, JString, required = false,
                                 default = nil)
  if valid_591484 != nil:
    section.add "X-Amz-SignedHeaders", valid_591484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591486: Call_UpdateApnsVoipSandboxChannel_591474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_591486.validator(path, query, header, formData, body)
  let scheme = call_591486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591486.url(scheme.get, call_591486.host, call_591486.base,
                         call_591486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591486, url, valid)

proc call*(call_591487: Call_UpdateApnsVoipSandboxChannel_591474;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApnsVoipSandboxChannel
  ## Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591488 = newJObject()
  var body_591489 = newJObject()
  add(path_591488, "application-id", newJString(applicationId))
  if body != nil:
    body_591489 = body
  result = call_591487.call(path_591488, nil, nil, nil, body_591489)

var updateApnsVoipSandboxChannel* = Call_UpdateApnsVoipSandboxChannel_591474(
    name: "updateApnsVoipSandboxChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_UpdateApnsVoipSandboxChannel_591475, base: "/",
    url: url_UpdateApnsVoipSandboxChannel_591476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApnsVoipSandboxChannel_591460 = ref object of OpenApiRestCall_590348
proc url_GetApnsVoipSandboxChannel_591462(protocol: Scheme; host: string;
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

proc validate_GetApnsVoipSandboxChannel_591461(path: JsonNode; query: JsonNode;
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
  var valid_591463 = path.getOrDefault("application-id")
  valid_591463 = validateParameter(valid_591463, JString, required = true,
                                 default = nil)
  if valid_591463 != nil:
    section.add "application-id", valid_591463
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591464 = header.getOrDefault("X-Amz-Signature")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Signature", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Content-Sha256", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-Date")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-Date", valid_591466
  var valid_591467 = header.getOrDefault("X-Amz-Credential")
  valid_591467 = validateParameter(valid_591467, JString, required = false,
                                 default = nil)
  if valid_591467 != nil:
    section.add "X-Amz-Credential", valid_591467
  var valid_591468 = header.getOrDefault("X-Amz-Security-Token")
  valid_591468 = validateParameter(valid_591468, JString, required = false,
                                 default = nil)
  if valid_591468 != nil:
    section.add "X-Amz-Security-Token", valid_591468
  var valid_591469 = header.getOrDefault("X-Amz-Algorithm")
  valid_591469 = validateParameter(valid_591469, JString, required = false,
                                 default = nil)
  if valid_591469 != nil:
    section.add "X-Amz-Algorithm", valid_591469
  var valid_591470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591470 = validateParameter(valid_591470, JString, required = false,
                                 default = nil)
  if valid_591470 != nil:
    section.add "X-Amz-SignedHeaders", valid_591470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591471: Call_GetApnsVoipSandboxChannel_591460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ## 
  let valid = call_591471.validator(path, query, header, formData, body)
  let scheme = call_591471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591471.url(scheme.get, call_591471.host, call_591471.base,
                         call_591471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591471, url, valid)

proc call*(call_591472: Call_GetApnsVoipSandboxChannel_591460;
          applicationId: string): Recallable =
  ## getApnsVoipSandboxChannel
  ## Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591473 = newJObject()
  add(path_591473, "application-id", newJString(applicationId))
  result = call_591472.call(path_591473, nil, nil, nil, nil)

var getApnsVoipSandboxChannel* = Call_GetApnsVoipSandboxChannel_591460(
    name: "getApnsVoipSandboxChannel", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_GetApnsVoipSandboxChannel_591461, base: "/",
    url: url_GetApnsVoipSandboxChannel_591462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApnsVoipSandboxChannel_591490 = ref object of OpenApiRestCall_590348
proc url_DeleteApnsVoipSandboxChannel_591492(protocol: Scheme; host: string;
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

proc validate_DeleteApnsVoipSandboxChannel_591491(path: JsonNode; query: JsonNode;
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
  var valid_591493 = path.getOrDefault("application-id")
  valid_591493 = validateParameter(valid_591493, JString, required = true,
                                 default = nil)
  if valid_591493 != nil:
    section.add "application-id", valid_591493
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591494 = header.getOrDefault("X-Amz-Signature")
  valid_591494 = validateParameter(valid_591494, JString, required = false,
                                 default = nil)
  if valid_591494 != nil:
    section.add "X-Amz-Signature", valid_591494
  var valid_591495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591495 = validateParameter(valid_591495, JString, required = false,
                                 default = nil)
  if valid_591495 != nil:
    section.add "X-Amz-Content-Sha256", valid_591495
  var valid_591496 = header.getOrDefault("X-Amz-Date")
  valid_591496 = validateParameter(valid_591496, JString, required = false,
                                 default = nil)
  if valid_591496 != nil:
    section.add "X-Amz-Date", valid_591496
  var valid_591497 = header.getOrDefault("X-Amz-Credential")
  valid_591497 = validateParameter(valid_591497, JString, required = false,
                                 default = nil)
  if valid_591497 != nil:
    section.add "X-Amz-Credential", valid_591497
  var valid_591498 = header.getOrDefault("X-Amz-Security-Token")
  valid_591498 = validateParameter(valid_591498, JString, required = false,
                                 default = nil)
  if valid_591498 != nil:
    section.add "X-Amz-Security-Token", valid_591498
  var valid_591499 = header.getOrDefault("X-Amz-Algorithm")
  valid_591499 = validateParameter(valid_591499, JString, required = false,
                                 default = nil)
  if valid_591499 != nil:
    section.add "X-Amz-Algorithm", valid_591499
  var valid_591500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591500 = validateParameter(valid_591500, JString, required = false,
                                 default = nil)
  if valid_591500 != nil:
    section.add "X-Amz-SignedHeaders", valid_591500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591501: Call_DeleteApnsVoipSandboxChannel_591490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591501.validator(path, query, header, formData, body)
  let scheme = call_591501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591501.url(scheme.get, call_591501.host, call_591501.base,
                         call_591501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591501, url, valid)

proc call*(call_591502: Call_DeleteApnsVoipSandboxChannel_591490;
          applicationId: string): Recallable =
  ## deleteApnsVoipSandboxChannel
  ## Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591503 = newJObject()
  add(path_591503, "application-id", newJString(applicationId))
  result = call_591502.call(path_591503, nil, nil, nil, nil)

var deleteApnsVoipSandboxChannel* = Call_DeleteApnsVoipSandboxChannel_591490(
    name: "deleteApnsVoipSandboxChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/apns_voip_sandbox",
    validator: validate_DeleteApnsVoipSandboxChannel_591491, base: "/",
    url: url_DeleteApnsVoipSandboxChannel_591492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_591504 = ref object of OpenApiRestCall_590348
proc url_GetApp_591506(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_591505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591507 = path.getOrDefault("application-id")
  valid_591507 = validateParameter(valid_591507, JString, required = true,
                                 default = nil)
  if valid_591507 != nil:
    section.add "application-id", valid_591507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591508 = header.getOrDefault("X-Amz-Signature")
  valid_591508 = validateParameter(valid_591508, JString, required = false,
                                 default = nil)
  if valid_591508 != nil:
    section.add "X-Amz-Signature", valid_591508
  var valid_591509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591509 = validateParameter(valid_591509, JString, required = false,
                                 default = nil)
  if valid_591509 != nil:
    section.add "X-Amz-Content-Sha256", valid_591509
  var valid_591510 = header.getOrDefault("X-Amz-Date")
  valid_591510 = validateParameter(valid_591510, JString, required = false,
                                 default = nil)
  if valid_591510 != nil:
    section.add "X-Amz-Date", valid_591510
  var valid_591511 = header.getOrDefault("X-Amz-Credential")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-Credential", valid_591511
  var valid_591512 = header.getOrDefault("X-Amz-Security-Token")
  valid_591512 = validateParameter(valid_591512, JString, required = false,
                                 default = nil)
  if valid_591512 != nil:
    section.add "X-Amz-Security-Token", valid_591512
  var valid_591513 = header.getOrDefault("X-Amz-Algorithm")
  valid_591513 = validateParameter(valid_591513, JString, required = false,
                                 default = nil)
  if valid_591513 != nil:
    section.add "X-Amz-Algorithm", valid_591513
  var valid_591514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591514 = validateParameter(valid_591514, JString, required = false,
                                 default = nil)
  if valid_591514 != nil:
    section.add "X-Amz-SignedHeaders", valid_591514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591515: Call_GetApp_591504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an application.
  ## 
  let valid = call_591515.validator(path, query, header, formData, body)
  let scheme = call_591515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591515.url(scheme.get, call_591515.host, call_591515.base,
                         call_591515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591515, url, valid)

proc call*(call_591516: Call_GetApp_591504; applicationId: string): Recallable =
  ## getApp
  ## Retrieves information about an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591517 = newJObject()
  add(path_591517, "application-id", newJString(applicationId))
  result = call_591516.call(path_591517, nil, nil, nil, nil)

var getApp* = Call_GetApp_591504(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "pinpoint.amazonaws.com",
                              route: "/v1/apps/{application-id}",
                              validator: validate_GetApp_591505, base: "/",
                              url: url_GetApp_591506,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_591518 = ref object of OpenApiRestCall_590348
proc url_DeleteApp_591520(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_591519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591521 = path.getOrDefault("application-id")
  valid_591521 = validateParameter(valid_591521, JString, required = true,
                                 default = nil)
  if valid_591521 != nil:
    section.add "application-id", valid_591521
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591522 = header.getOrDefault("X-Amz-Signature")
  valid_591522 = validateParameter(valid_591522, JString, required = false,
                                 default = nil)
  if valid_591522 != nil:
    section.add "X-Amz-Signature", valid_591522
  var valid_591523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591523 = validateParameter(valid_591523, JString, required = false,
                                 default = nil)
  if valid_591523 != nil:
    section.add "X-Amz-Content-Sha256", valid_591523
  var valid_591524 = header.getOrDefault("X-Amz-Date")
  valid_591524 = validateParameter(valid_591524, JString, required = false,
                                 default = nil)
  if valid_591524 != nil:
    section.add "X-Amz-Date", valid_591524
  var valid_591525 = header.getOrDefault("X-Amz-Credential")
  valid_591525 = validateParameter(valid_591525, JString, required = false,
                                 default = nil)
  if valid_591525 != nil:
    section.add "X-Amz-Credential", valid_591525
  var valid_591526 = header.getOrDefault("X-Amz-Security-Token")
  valid_591526 = validateParameter(valid_591526, JString, required = false,
                                 default = nil)
  if valid_591526 != nil:
    section.add "X-Amz-Security-Token", valid_591526
  var valid_591527 = header.getOrDefault("X-Amz-Algorithm")
  valid_591527 = validateParameter(valid_591527, JString, required = false,
                                 default = nil)
  if valid_591527 != nil:
    section.add "X-Amz-Algorithm", valid_591527
  var valid_591528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591528 = validateParameter(valid_591528, JString, required = false,
                                 default = nil)
  if valid_591528 != nil:
    section.add "X-Amz-SignedHeaders", valid_591528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591529: Call_DeleteApp_591518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_591529.validator(path, query, header, formData, body)
  let scheme = call_591529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591529.url(scheme.get, call_591529.host, call_591529.base,
                         call_591529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591529, url, valid)

proc call*(call_591530: Call_DeleteApp_591518; applicationId: string): Recallable =
  ## deleteApp
  ## Deletes an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591531 = newJObject()
  add(path_591531, "application-id", newJString(applicationId))
  result = call_591530.call(path_591531, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_591518(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}",
                                    validator: validate_DeleteApp_591519,
                                    base: "/", url: url_DeleteApp_591520,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBaiduChannel_591546 = ref object of OpenApiRestCall_590348
proc url_UpdateBaiduChannel_591548(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBaiduChannel_591547(path: JsonNode; query: JsonNode;
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
  var valid_591549 = path.getOrDefault("application-id")
  valid_591549 = validateParameter(valid_591549, JString, required = true,
                                 default = nil)
  if valid_591549 != nil:
    section.add "application-id", valid_591549
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591550 = header.getOrDefault("X-Amz-Signature")
  valid_591550 = validateParameter(valid_591550, JString, required = false,
                                 default = nil)
  if valid_591550 != nil:
    section.add "X-Amz-Signature", valid_591550
  var valid_591551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591551 = validateParameter(valid_591551, JString, required = false,
                                 default = nil)
  if valid_591551 != nil:
    section.add "X-Amz-Content-Sha256", valid_591551
  var valid_591552 = header.getOrDefault("X-Amz-Date")
  valid_591552 = validateParameter(valid_591552, JString, required = false,
                                 default = nil)
  if valid_591552 != nil:
    section.add "X-Amz-Date", valid_591552
  var valid_591553 = header.getOrDefault("X-Amz-Credential")
  valid_591553 = validateParameter(valid_591553, JString, required = false,
                                 default = nil)
  if valid_591553 != nil:
    section.add "X-Amz-Credential", valid_591553
  var valid_591554 = header.getOrDefault("X-Amz-Security-Token")
  valid_591554 = validateParameter(valid_591554, JString, required = false,
                                 default = nil)
  if valid_591554 != nil:
    section.add "X-Amz-Security-Token", valid_591554
  var valid_591555 = header.getOrDefault("X-Amz-Algorithm")
  valid_591555 = validateParameter(valid_591555, JString, required = false,
                                 default = nil)
  if valid_591555 != nil:
    section.add "X-Amz-Algorithm", valid_591555
  var valid_591556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591556 = validateParameter(valid_591556, JString, required = false,
                                 default = nil)
  if valid_591556 != nil:
    section.add "X-Amz-SignedHeaders", valid_591556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591558: Call_UpdateBaiduChannel_591546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_591558.validator(path, query, header, formData, body)
  let scheme = call_591558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591558.url(scheme.get, call_591558.host, call_591558.base,
                         call_591558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591558, url, valid)

proc call*(call_591559: Call_UpdateBaiduChannel_591546; applicationId: string;
          body: JsonNode): Recallable =
  ## updateBaiduChannel
  ## Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591560 = newJObject()
  var body_591561 = newJObject()
  add(path_591560, "application-id", newJString(applicationId))
  if body != nil:
    body_591561 = body
  result = call_591559.call(path_591560, nil, nil, nil, body_591561)

var updateBaiduChannel* = Call_UpdateBaiduChannel_591546(
    name: "updateBaiduChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_UpdateBaiduChannel_591547, base: "/",
    url: url_UpdateBaiduChannel_591548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBaiduChannel_591532 = ref object of OpenApiRestCall_590348
proc url_GetBaiduChannel_591534(protocol: Scheme; host: string; base: string;
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

proc validate_GetBaiduChannel_591533(path: JsonNode; query: JsonNode;
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
  var valid_591535 = path.getOrDefault("application-id")
  valid_591535 = validateParameter(valid_591535, JString, required = true,
                                 default = nil)
  if valid_591535 != nil:
    section.add "application-id", valid_591535
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591536 = header.getOrDefault("X-Amz-Signature")
  valid_591536 = validateParameter(valid_591536, JString, required = false,
                                 default = nil)
  if valid_591536 != nil:
    section.add "X-Amz-Signature", valid_591536
  var valid_591537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591537 = validateParameter(valid_591537, JString, required = false,
                                 default = nil)
  if valid_591537 != nil:
    section.add "X-Amz-Content-Sha256", valid_591537
  var valid_591538 = header.getOrDefault("X-Amz-Date")
  valid_591538 = validateParameter(valid_591538, JString, required = false,
                                 default = nil)
  if valid_591538 != nil:
    section.add "X-Amz-Date", valid_591538
  var valid_591539 = header.getOrDefault("X-Amz-Credential")
  valid_591539 = validateParameter(valid_591539, JString, required = false,
                                 default = nil)
  if valid_591539 != nil:
    section.add "X-Amz-Credential", valid_591539
  var valid_591540 = header.getOrDefault("X-Amz-Security-Token")
  valid_591540 = validateParameter(valid_591540, JString, required = false,
                                 default = nil)
  if valid_591540 != nil:
    section.add "X-Amz-Security-Token", valid_591540
  var valid_591541 = header.getOrDefault("X-Amz-Algorithm")
  valid_591541 = validateParameter(valid_591541, JString, required = false,
                                 default = nil)
  if valid_591541 != nil:
    section.add "X-Amz-Algorithm", valid_591541
  var valid_591542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591542 = validateParameter(valid_591542, JString, required = false,
                                 default = nil)
  if valid_591542 != nil:
    section.add "X-Amz-SignedHeaders", valid_591542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591543: Call_GetBaiduChannel_591532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ## 
  let valid = call_591543.validator(path, query, header, formData, body)
  let scheme = call_591543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591543.url(scheme.get, call_591543.host, call_591543.base,
                         call_591543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591543, url, valid)

proc call*(call_591544: Call_GetBaiduChannel_591532; applicationId: string): Recallable =
  ## getBaiduChannel
  ## Retrieves information about the status and settings of the Baidu channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591545 = newJObject()
  add(path_591545, "application-id", newJString(applicationId))
  result = call_591544.call(path_591545, nil, nil, nil, nil)

var getBaiduChannel* = Call_GetBaiduChannel_591532(name: "getBaiduChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_GetBaiduChannel_591533, base: "/", url: url_GetBaiduChannel_591534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBaiduChannel_591562 = ref object of OpenApiRestCall_590348
proc url_DeleteBaiduChannel_591564(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBaiduChannel_591563(path: JsonNode; query: JsonNode;
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
  var valid_591565 = path.getOrDefault("application-id")
  valid_591565 = validateParameter(valid_591565, JString, required = true,
                                 default = nil)
  if valid_591565 != nil:
    section.add "application-id", valid_591565
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591566 = header.getOrDefault("X-Amz-Signature")
  valid_591566 = validateParameter(valid_591566, JString, required = false,
                                 default = nil)
  if valid_591566 != nil:
    section.add "X-Amz-Signature", valid_591566
  var valid_591567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591567 = validateParameter(valid_591567, JString, required = false,
                                 default = nil)
  if valid_591567 != nil:
    section.add "X-Amz-Content-Sha256", valid_591567
  var valid_591568 = header.getOrDefault("X-Amz-Date")
  valid_591568 = validateParameter(valid_591568, JString, required = false,
                                 default = nil)
  if valid_591568 != nil:
    section.add "X-Amz-Date", valid_591568
  var valid_591569 = header.getOrDefault("X-Amz-Credential")
  valid_591569 = validateParameter(valid_591569, JString, required = false,
                                 default = nil)
  if valid_591569 != nil:
    section.add "X-Amz-Credential", valid_591569
  var valid_591570 = header.getOrDefault("X-Amz-Security-Token")
  valid_591570 = validateParameter(valid_591570, JString, required = false,
                                 default = nil)
  if valid_591570 != nil:
    section.add "X-Amz-Security-Token", valid_591570
  var valid_591571 = header.getOrDefault("X-Amz-Algorithm")
  valid_591571 = validateParameter(valid_591571, JString, required = false,
                                 default = nil)
  if valid_591571 != nil:
    section.add "X-Amz-Algorithm", valid_591571
  var valid_591572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591572 = validateParameter(valid_591572, JString, required = false,
                                 default = nil)
  if valid_591572 != nil:
    section.add "X-Amz-SignedHeaders", valid_591572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591573: Call_DeleteBaiduChannel_591562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591573.validator(path, query, header, formData, body)
  let scheme = call_591573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591573.url(scheme.get, call_591573.host, call_591573.base,
                         call_591573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591573, url, valid)

proc call*(call_591574: Call_DeleteBaiduChannel_591562; applicationId: string): Recallable =
  ## deleteBaiduChannel
  ## Disables the Baidu channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591575 = newJObject()
  add(path_591575, "application-id", newJString(applicationId))
  result = call_591574.call(path_591575, nil, nil, nil, nil)

var deleteBaiduChannel* = Call_DeleteBaiduChannel_591562(
    name: "deleteBaiduChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/baidu",
    validator: validate_DeleteBaiduChannel_591563, base: "/",
    url: url_DeleteBaiduChannel_591564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCampaign_591591 = ref object of OpenApiRestCall_590348
proc url_UpdateCampaign_591593(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCampaign_591592(path: JsonNode; query: JsonNode;
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
  var valid_591594 = path.getOrDefault("application-id")
  valid_591594 = validateParameter(valid_591594, JString, required = true,
                                 default = nil)
  if valid_591594 != nil:
    section.add "application-id", valid_591594
  var valid_591595 = path.getOrDefault("campaign-id")
  valid_591595 = validateParameter(valid_591595, JString, required = true,
                                 default = nil)
  if valid_591595 != nil:
    section.add "campaign-id", valid_591595
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591596 = header.getOrDefault("X-Amz-Signature")
  valid_591596 = validateParameter(valid_591596, JString, required = false,
                                 default = nil)
  if valid_591596 != nil:
    section.add "X-Amz-Signature", valid_591596
  var valid_591597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591597 = validateParameter(valid_591597, JString, required = false,
                                 default = nil)
  if valid_591597 != nil:
    section.add "X-Amz-Content-Sha256", valid_591597
  var valid_591598 = header.getOrDefault("X-Amz-Date")
  valid_591598 = validateParameter(valid_591598, JString, required = false,
                                 default = nil)
  if valid_591598 != nil:
    section.add "X-Amz-Date", valid_591598
  var valid_591599 = header.getOrDefault("X-Amz-Credential")
  valid_591599 = validateParameter(valid_591599, JString, required = false,
                                 default = nil)
  if valid_591599 != nil:
    section.add "X-Amz-Credential", valid_591599
  var valid_591600 = header.getOrDefault("X-Amz-Security-Token")
  valid_591600 = validateParameter(valid_591600, JString, required = false,
                                 default = nil)
  if valid_591600 != nil:
    section.add "X-Amz-Security-Token", valid_591600
  var valid_591601 = header.getOrDefault("X-Amz-Algorithm")
  valid_591601 = validateParameter(valid_591601, JString, required = false,
                                 default = nil)
  if valid_591601 != nil:
    section.add "X-Amz-Algorithm", valid_591601
  var valid_591602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591602 = validateParameter(valid_591602, JString, required = false,
                                 default = nil)
  if valid_591602 != nil:
    section.add "X-Amz-SignedHeaders", valid_591602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591604: Call_UpdateCampaign_591591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for a campaign.
  ## 
  let valid = call_591604.validator(path, query, header, formData, body)
  let scheme = call_591604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591604.url(scheme.get, call_591604.host, call_591604.base,
                         call_591604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591604, url, valid)

proc call*(call_591605: Call_UpdateCampaign_591591; applicationId: string;
          body: JsonNode; campaignId: string): Recallable =
  ## updateCampaign
  ## Updates the settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_591606 = newJObject()
  var body_591607 = newJObject()
  add(path_591606, "application-id", newJString(applicationId))
  if body != nil:
    body_591607 = body
  add(path_591606, "campaign-id", newJString(campaignId))
  result = call_591605.call(path_591606, nil, nil, nil, body_591607)

var updateCampaign* = Call_UpdateCampaign_591591(name: "updateCampaign",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_UpdateCampaign_591592, base: "/", url: url_UpdateCampaign_591593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaign_591576 = ref object of OpenApiRestCall_590348
proc url_GetCampaign_591578(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaign_591577(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591579 = path.getOrDefault("application-id")
  valid_591579 = validateParameter(valid_591579, JString, required = true,
                                 default = nil)
  if valid_591579 != nil:
    section.add "application-id", valid_591579
  var valid_591580 = path.getOrDefault("campaign-id")
  valid_591580 = validateParameter(valid_591580, JString, required = true,
                                 default = nil)
  if valid_591580 != nil:
    section.add "campaign-id", valid_591580
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591581 = header.getOrDefault("X-Amz-Signature")
  valid_591581 = validateParameter(valid_591581, JString, required = false,
                                 default = nil)
  if valid_591581 != nil:
    section.add "X-Amz-Signature", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-Content-Sha256", valid_591582
  var valid_591583 = header.getOrDefault("X-Amz-Date")
  valid_591583 = validateParameter(valid_591583, JString, required = false,
                                 default = nil)
  if valid_591583 != nil:
    section.add "X-Amz-Date", valid_591583
  var valid_591584 = header.getOrDefault("X-Amz-Credential")
  valid_591584 = validateParameter(valid_591584, JString, required = false,
                                 default = nil)
  if valid_591584 != nil:
    section.add "X-Amz-Credential", valid_591584
  var valid_591585 = header.getOrDefault("X-Amz-Security-Token")
  valid_591585 = validateParameter(valid_591585, JString, required = false,
                                 default = nil)
  if valid_591585 != nil:
    section.add "X-Amz-Security-Token", valid_591585
  var valid_591586 = header.getOrDefault("X-Amz-Algorithm")
  valid_591586 = validateParameter(valid_591586, JString, required = false,
                                 default = nil)
  if valid_591586 != nil:
    section.add "X-Amz-Algorithm", valid_591586
  var valid_591587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591587 = validateParameter(valid_591587, JString, required = false,
                                 default = nil)
  if valid_591587 != nil:
    section.add "X-Amz-SignedHeaders", valid_591587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591588: Call_GetCampaign_591576; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ## 
  let valid = call_591588.validator(path, query, header, formData, body)
  let scheme = call_591588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591588.url(scheme.get, call_591588.host, call_591588.base,
                         call_591588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591588, url, valid)

proc call*(call_591589: Call_GetCampaign_591576; applicationId: string;
          campaignId: string): Recallable =
  ## getCampaign
  ## Retrieves information about the status, configuration, and other settings for a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_591590 = newJObject()
  add(path_591590, "application-id", newJString(applicationId))
  add(path_591590, "campaign-id", newJString(campaignId))
  result = call_591589.call(path_591590, nil, nil, nil, nil)

var getCampaign* = Call_GetCampaign_591576(name: "getCampaign",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
                                        validator: validate_GetCampaign_591577,
                                        base: "/", url: url_GetCampaign_591578,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCampaign_591608 = ref object of OpenApiRestCall_590348
proc url_DeleteCampaign_591610(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCampaign_591609(path: JsonNode; query: JsonNode;
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
  var valid_591611 = path.getOrDefault("application-id")
  valid_591611 = validateParameter(valid_591611, JString, required = true,
                                 default = nil)
  if valid_591611 != nil:
    section.add "application-id", valid_591611
  var valid_591612 = path.getOrDefault("campaign-id")
  valid_591612 = validateParameter(valid_591612, JString, required = true,
                                 default = nil)
  if valid_591612 != nil:
    section.add "campaign-id", valid_591612
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591613 = header.getOrDefault("X-Amz-Signature")
  valid_591613 = validateParameter(valid_591613, JString, required = false,
                                 default = nil)
  if valid_591613 != nil:
    section.add "X-Amz-Signature", valid_591613
  var valid_591614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591614 = validateParameter(valid_591614, JString, required = false,
                                 default = nil)
  if valid_591614 != nil:
    section.add "X-Amz-Content-Sha256", valid_591614
  var valid_591615 = header.getOrDefault("X-Amz-Date")
  valid_591615 = validateParameter(valid_591615, JString, required = false,
                                 default = nil)
  if valid_591615 != nil:
    section.add "X-Amz-Date", valid_591615
  var valid_591616 = header.getOrDefault("X-Amz-Credential")
  valid_591616 = validateParameter(valid_591616, JString, required = false,
                                 default = nil)
  if valid_591616 != nil:
    section.add "X-Amz-Credential", valid_591616
  var valid_591617 = header.getOrDefault("X-Amz-Security-Token")
  valid_591617 = validateParameter(valid_591617, JString, required = false,
                                 default = nil)
  if valid_591617 != nil:
    section.add "X-Amz-Security-Token", valid_591617
  var valid_591618 = header.getOrDefault("X-Amz-Algorithm")
  valid_591618 = validateParameter(valid_591618, JString, required = false,
                                 default = nil)
  if valid_591618 != nil:
    section.add "X-Amz-Algorithm", valid_591618
  var valid_591619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591619 = validateParameter(valid_591619, JString, required = false,
                                 default = nil)
  if valid_591619 != nil:
    section.add "X-Amz-SignedHeaders", valid_591619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591620: Call_DeleteCampaign_591608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a campaign from an application.
  ## 
  let valid = call_591620.validator(path, query, header, formData, body)
  let scheme = call_591620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591620.url(scheme.get, call_591620.host, call_591620.base,
                         call_591620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591620, url, valid)

proc call*(call_591621: Call_DeleteCampaign_591608; applicationId: string;
          campaignId: string): Recallable =
  ## deleteCampaign
  ## Deletes a campaign from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_591622 = newJObject()
  add(path_591622, "application-id", newJString(applicationId))
  add(path_591622, "campaign-id", newJString(campaignId))
  result = call_591621.call(path_591622, nil, nil, nil, nil)

var deleteCampaign* = Call_DeleteCampaign_591608(name: "deleteCampaign",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}",
    validator: validate_DeleteCampaign_591609, base: "/", url: url_DeleteCampaign_591610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEmailChannel_591637 = ref object of OpenApiRestCall_590348
proc url_UpdateEmailChannel_591639(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEmailChannel_591638(path: JsonNode; query: JsonNode;
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
  var valid_591640 = path.getOrDefault("application-id")
  valid_591640 = validateParameter(valid_591640, JString, required = true,
                                 default = nil)
  if valid_591640 != nil:
    section.add "application-id", valid_591640
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591641 = header.getOrDefault("X-Amz-Signature")
  valid_591641 = validateParameter(valid_591641, JString, required = false,
                                 default = nil)
  if valid_591641 != nil:
    section.add "X-Amz-Signature", valid_591641
  var valid_591642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591642 = validateParameter(valid_591642, JString, required = false,
                                 default = nil)
  if valid_591642 != nil:
    section.add "X-Amz-Content-Sha256", valid_591642
  var valid_591643 = header.getOrDefault("X-Amz-Date")
  valid_591643 = validateParameter(valid_591643, JString, required = false,
                                 default = nil)
  if valid_591643 != nil:
    section.add "X-Amz-Date", valid_591643
  var valid_591644 = header.getOrDefault("X-Amz-Credential")
  valid_591644 = validateParameter(valid_591644, JString, required = false,
                                 default = nil)
  if valid_591644 != nil:
    section.add "X-Amz-Credential", valid_591644
  var valid_591645 = header.getOrDefault("X-Amz-Security-Token")
  valid_591645 = validateParameter(valid_591645, JString, required = false,
                                 default = nil)
  if valid_591645 != nil:
    section.add "X-Amz-Security-Token", valid_591645
  var valid_591646 = header.getOrDefault("X-Amz-Algorithm")
  valid_591646 = validateParameter(valid_591646, JString, required = false,
                                 default = nil)
  if valid_591646 != nil:
    section.add "X-Amz-Algorithm", valid_591646
  var valid_591647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591647 = validateParameter(valid_591647, JString, required = false,
                                 default = nil)
  if valid_591647 != nil:
    section.add "X-Amz-SignedHeaders", valid_591647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591649: Call_UpdateEmailChannel_591637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ## 
  let valid = call_591649.validator(path, query, header, formData, body)
  let scheme = call_591649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591649.url(scheme.get, call_591649.host, call_591649.base,
                         call_591649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591649, url, valid)

proc call*(call_591650: Call_UpdateEmailChannel_591637; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEmailChannel
  ## Enables the email channel for an application or updates the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591651 = newJObject()
  var body_591652 = newJObject()
  add(path_591651, "application-id", newJString(applicationId))
  if body != nil:
    body_591652 = body
  result = call_591650.call(path_591651, nil, nil, nil, body_591652)

var updateEmailChannel* = Call_UpdateEmailChannel_591637(
    name: "updateEmailChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_UpdateEmailChannel_591638, base: "/",
    url: url_UpdateEmailChannel_591639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailChannel_591623 = ref object of OpenApiRestCall_590348
proc url_GetEmailChannel_591625(protocol: Scheme; host: string; base: string;
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

proc validate_GetEmailChannel_591624(path: JsonNode; query: JsonNode;
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
  var valid_591626 = path.getOrDefault("application-id")
  valid_591626 = validateParameter(valid_591626, JString, required = true,
                                 default = nil)
  if valid_591626 != nil:
    section.add "application-id", valid_591626
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591627 = header.getOrDefault("X-Amz-Signature")
  valid_591627 = validateParameter(valid_591627, JString, required = false,
                                 default = nil)
  if valid_591627 != nil:
    section.add "X-Amz-Signature", valid_591627
  var valid_591628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591628 = validateParameter(valid_591628, JString, required = false,
                                 default = nil)
  if valid_591628 != nil:
    section.add "X-Amz-Content-Sha256", valid_591628
  var valid_591629 = header.getOrDefault("X-Amz-Date")
  valid_591629 = validateParameter(valid_591629, JString, required = false,
                                 default = nil)
  if valid_591629 != nil:
    section.add "X-Amz-Date", valid_591629
  var valid_591630 = header.getOrDefault("X-Amz-Credential")
  valid_591630 = validateParameter(valid_591630, JString, required = false,
                                 default = nil)
  if valid_591630 != nil:
    section.add "X-Amz-Credential", valid_591630
  var valid_591631 = header.getOrDefault("X-Amz-Security-Token")
  valid_591631 = validateParameter(valid_591631, JString, required = false,
                                 default = nil)
  if valid_591631 != nil:
    section.add "X-Amz-Security-Token", valid_591631
  var valid_591632 = header.getOrDefault("X-Amz-Algorithm")
  valid_591632 = validateParameter(valid_591632, JString, required = false,
                                 default = nil)
  if valid_591632 != nil:
    section.add "X-Amz-Algorithm", valid_591632
  var valid_591633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591633 = validateParameter(valid_591633, JString, required = false,
                                 default = nil)
  if valid_591633 != nil:
    section.add "X-Amz-SignedHeaders", valid_591633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591634: Call_GetEmailChannel_591623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the email channel for an application.
  ## 
  let valid = call_591634.validator(path, query, header, formData, body)
  let scheme = call_591634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591634.url(scheme.get, call_591634.host, call_591634.base,
                         call_591634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591634, url, valid)

proc call*(call_591635: Call_GetEmailChannel_591623; applicationId: string): Recallable =
  ## getEmailChannel
  ## Retrieves information about the status and settings of the email channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591636 = newJObject()
  add(path_591636, "application-id", newJString(applicationId))
  result = call_591635.call(path_591636, nil, nil, nil, nil)

var getEmailChannel* = Call_GetEmailChannel_591623(name: "getEmailChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_GetEmailChannel_591624, base: "/", url: url_GetEmailChannel_591625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailChannel_591653 = ref object of OpenApiRestCall_590348
proc url_DeleteEmailChannel_591655(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEmailChannel_591654(path: JsonNode; query: JsonNode;
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
  var valid_591656 = path.getOrDefault("application-id")
  valid_591656 = validateParameter(valid_591656, JString, required = true,
                                 default = nil)
  if valid_591656 != nil:
    section.add "application-id", valid_591656
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591657 = header.getOrDefault("X-Amz-Signature")
  valid_591657 = validateParameter(valid_591657, JString, required = false,
                                 default = nil)
  if valid_591657 != nil:
    section.add "X-Amz-Signature", valid_591657
  var valid_591658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "X-Amz-Content-Sha256", valid_591658
  var valid_591659 = header.getOrDefault("X-Amz-Date")
  valid_591659 = validateParameter(valid_591659, JString, required = false,
                                 default = nil)
  if valid_591659 != nil:
    section.add "X-Amz-Date", valid_591659
  var valid_591660 = header.getOrDefault("X-Amz-Credential")
  valid_591660 = validateParameter(valid_591660, JString, required = false,
                                 default = nil)
  if valid_591660 != nil:
    section.add "X-Amz-Credential", valid_591660
  var valid_591661 = header.getOrDefault("X-Amz-Security-Token")
  valid_591661 = validateParameter(valid_591661, JString, required = false,
                                 default = nil)
  if valid_591661 != nil:
    section.add "X-Amz-Security-Token", valid_591661
  var valid_591662 = header.getOrDefault("X-Amz-Algorithm")
  valid_591662 = validateParameter(valid_591662, JString, required = false,
                                 default = nil)
  if valid_591662 != nil:
    section.add "X-Amz-Algorithm", valid_591662
  var valid_591663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591663 = validateParameter(valid_591663, JString, required = false,
                                 default = nil)
  if valid_591663 != nil:
    section.add "X-Amz-SignedHeaders", valid_591663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591664: Call_DeleteEmailChannel_591653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591664.validator(path, query, header, formData, body)
  let scheme = call_591664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591664.url(scheme.get, call_591664.host, call_591664.base,
                         call_591664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591664, url, valid)

proc call*(call_591665: Call_DeleteEmailChannel_591653; applicationId: string): Recallable =
  ## deleteEmailChannel
  ## Disables the email channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591666 = newJObject()
  add(path_591666, "application-id", newJString(applicationId))
  result = call_591665.call(path_591666, nil, nil, nil, nil)

var deleteEmailChannel* = Call_DeleteEmailChannel_591653(
    name: "deleteEmailChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/email",
    validator: validate_DeleteEmailChannel_591654, base: "/",
    url: url_DeleteEmailChannel_591655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_591682 = ref object of OpenApiRestCall_590348
proc url_UpdateEndpoint_591684(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_591683(path: JsonNode; query: JsonNode;
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
  var valid_591685 = path.getOrDefault("application-id")
  valid_591685 = validateParameter(valid_591685, JString, required = true,
                                 default = nil)
  if valid_591685 != nil:
    section.add "application-id", valid_591685
  var valid_591686 = path.getOrDefault("endpoint-id")
  valid_591686 = validateParameter(valid_591686, JString, required = true,
                                 default = nil)
  if valid_591686 != nil:
    section.add "endpoint-id", valid_591686
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591687 = header.getOrDefault("X-Amz-Signature")
  valid_591687 = validateParameter(valid_591687, JString, required = false,
                                 default = nil)
  if valid_591687 != nil:
    section.add "X-Amz-Signature", valid_591687
  var valid_591688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591688 = validateParameter(valid_591688, JString, required = false,
                                 default = nil)
  if valid_591688 != nil:
    section.add "X-Amz-Content-Sha256", valid_591688
  var valid_591689 = header.getOrDefault("X-Amz-Date")
  valid_591689 = validateParameter(valid_591689, JString, required = false,
                                 default = nil)
  if valid_591689 != nil:
    section.add "X-Amz-Date", valid_591689
  var valid_591690 = header.getOrDefault("X-Amz-Credential")
  valid_591690 = validateParameter(valid_591690, JString, required = false,
                                 default = nil)
  if valid_591690 != nil:
    section.add "X-Amz-Credential", valid_591690
  var valid_591691 = header.getOrDefault("X-Amz-Security-Token")
  valid_591691 = validateParameter(valid_591691, JString, required = false,
                                 default = nil)
  if valid_591691 != nil:
    section.add "X-Amz-Security-Token", valid_591691
  var valid_591692 = header.getOrDefault("X-Amz-Algorithm")
  valid_591692 = validateParameter(valid_591692, JString, required = false,
                                 default = nil)
  if valid_591692 != nil:
    section.add "X-Amz-Algorithm", valid_591692
  var valid_591693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "X-Amz-SignedHeaders", valid_591693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591695: Call_UpdateEndpoint_591682; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ## 
  let valid = call_591695.validator(path, query, header, formData, body)
  let scheme = call_591695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591695.url(scheme.get, call_591695.host, call_591695.base,
                         call_591695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591695, url, valid)

proc call*(call_591696: Call_UpdateEndpoint_591682; applicationId: string;
          body: JsonNode; endpointId: string): Recallable =
  ## updateEndpoint
  ## Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for an endpoint.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_591697 = newJObject()
  var body_591698 = newJObject()
  add(path_591697, "application-id", newJString(applicationId))
  if body != nil:
    body_591698 = body
  add(path_591697, "endpoint-id", newJString(endpointId))
  result = call_591696.call(path_591697, nil, nil, nil, body_591698)

var updateEndpoint* = Call_UpdateEndpoint_591682(name: "updateEndpoint",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_UpdateEndpoint_591683, base: "/", url: url_UpdateEndpoint_591684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEndpoint_591667 = ref object of OpenApiRestCall_590348
proc url_GetEndpoint_591669(protocol: Scheme; host: string; base: string;
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

proc validate_GetEndpoint_591668(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591670 = path.getOrDefault("application-id")
  valid_591670 = validateParameter(valid_591670, JString, required = true,
                                 default = nil)
  if valid_591670 != nil:
    section.add "application-id", valid_591670
  var valid_591671 = path.getOrDefault("endpoint-id")
  valid_591671 = validateParameter(valid_591671, JString, required = true,
                                 default = nil)
  if valid_591671 != nil:
    section.add "endpoint-id", valid_591671
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591672 = header.getOrDefault("X-Amz-Signature")
  valid_591672 = validateParameter(valid_591672, JString, required = false,
                                 default = nil)
  if valid_591672 != nil:
    section.add "X-Amz-Signature", valid_591672
  var valid_591673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591673 = validateParameter(valid_591673, JString, required = false,
                                 default = nil)
  if valid_591673 != nil:
    section.add "X-Amz-Content-Sha256", valid_591673
  var valid_591674 = header.getOrDefault("X-Amz-Date")
  valid_591674 = validateParameter(valid_591674, JString, required = false,
                                 default = nil)
  if valid_591674 != nil:
    section.add "X-Amz-Date", valid_591674
  var valid_591675 = header.getOrDefault("X-Amz-Credential")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "X-Amz-Credential", valid_591675
  var valid_591676 = header.getOrDefault("X-Amz-Security-Token")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "X-Amz-Security-Token", valid_591676
  var valid_591677 = header.getOrDefault("X-Amz-Algorithm")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-Algorithm", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-SignedHeaders", valid_591678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591679: Call_GetEndpoint_591667; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ## 
  let valid = call_591679.validator(path, query, header, formData, body)
  let scheme = call_591679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591679.url(scheme.get, call_591679.host, call_591679.base,
                         call_591679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591679, url, valid)

proc call*(call_591680: Call_GetEndpoint_591667; applicationId: string;
          endpointId: string): Recallable =
  ## getEndpoint
  ## Retrieves information about the settings and attributes of a specific endpoint for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_591681 = newJObject()
  add(path_591681, "application-id", newJString(applicationId))
  add(path_591681, "endpoint-id", newJString(endpointId))
  result = call_591680.call(path_591681, nil, nil, nil, nil)

var getEndpoint* = Call_GetEndpoint_591667(name: "getEndpoint",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
                                        validator: validate_GetEndpoint_591668,
                                        base: "/", url: url_GetEndpoint_591669,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_591699 = ref object of OpenApiRestCall_590348
proc url_DeleteEndpoint_591701(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_591700(path: JsonNode; query: JsonNode;
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
  var valid_591702 = path.getOrDefault("application-id")
  valid_591702 = validateParameter(valid_591702, JString, required = true,
                                 default = nil)
  if valid_591702 != nil:
    section.add "application-id", valid_591702
  var valid_591703 = path.getOrDefault("endpoint-id")
  valid_591703 = validateParameter(valid_591703, JString, required = true,
                                 default = nil)
  if valid_591703 != nil:
    section.add "endpoint-id", valid_591703
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591704 = header.getOrDefault("X-Amz-Signature")
  valid_591704 = validateParameter(valid_591704, JString, required = false,
                                 default = nil)
  if valid_591704 != nil:
    section.add "X-Amz-Signature", valid_591704
  var valid_591705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591705 = validateParameter(valid_591705, JString, required = false,
                                 default = nil)
  if valid_591705 != nil:
    section.add "X-Amz-Content-Sha256", valid_591705
  var valid_591706 = header.getOrDefault("X-Amz-Date")
  valid_591706 = validateParameter(valid_591706, JString, required = false,
                                 default = nil)
  if valid_591706 != nil:
    section.add "X-Amz-Date", valid_591706
  var valid_591707 = header.getOrDefault("X-Amz-Credential")
  valid_591707 = validateParameter(valid_591707, JString, required = false,
                                 default = nil)
  if valid_591707 != nil:
    section.add "X-Amz-Credential", valid_591707
  var valid_591708 = header.getOrDefault("X-Amz-Security-Token")
  valid_591708 = validateParameter(valid_591708, JString, required = false,
                                 default = nil)
  if valid_591708 != nil:
    section.add "X-Amz-Security-Token", valid_591708
  var valid_591709 = header.getOrDefault("X-Amz-Algorithm")
  valid_591709 = validateParameter(valid_591709, JString, required = false,
                                 default = nil)
  if valid_591709 != nil:
    section.add "X-Amz-Algorithm", valid_591709
  var valid_591710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591710 = validateParameter(valid_591710, JString, required = false,
                                 default = nil)
  if valid_591710 != nil:
    section.add "X-Amz-SignedHeaders", valid_591710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591711: Call_DeleteEndpoint_591699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint from an application.
  ## 
  let valid = call_591711.validator(path, query, header, formData, body)
  let scheme = call_591711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591711.url(scheme.get, call_591711.host, call_591711.base,
                         call_591711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591711, url, valid)

proc call*(call_591712: Call_DeleteEndpoint_591699; applicationId: string;
          endpointId: string): Recallable =
  ## deleteEndpoint
  ## Deletes an endpoint from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endpointId: string (required)
  ##             : The unique identifier for the endpoint.
  var path_591713 = newJObject()
  add(path_591713, "application-id", newJString(applicationId))
  add(path_591713, "endpoint-id", newJString(endpointId))
  result = call_591712.call(path_591713, nil, nil, nil, nil)

var deleteEndpoint* = Call_DeleteEndpoint_591699(name: "deleteEndpoint",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/endpoints/{endpoint-id}",
    validator: validate_DeleteEndpoint_591700, base: "/", url: url_DeleteEndpoint_591701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventStream_591728 = ref object of OpenApiRestCall_590348
proc url_PutEventStream_591730(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventStream_591729(path: JsonNode; query: JsonNode;
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
  var valid_591731 = path.getOrDefault("application-id")
  valid_591731 = validateParameter(valid_591731, JString, required = true,
                                 default = nil)
  if valid_591731 != nil:
    section.add "application-id", valid_591731
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591732 = header.getOrDefault("X-Amz-Signature")
  valid_591732 = validateParameter(valid_591732, JString, required = false,
                                 default = nil)
  if valid_591732 != nil:
    section.add "X-Amz-Signature", valid_591732
  var valid_591733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591733 = validateParameter(valid_591733, JString, required = false,
                                 default = nil)
  if valid_591733 != nil:
    section.add "X-Amz-Content-Sha256", valid_591733
  var valid_591734 = header.getOrDefault("X-Amz-Date")
  valid_591734 = validateParameter(valid_591734, JString, required = false,
                                 default = nil)
  if valid_591734 != nil:
    section.add "X-Amz-Date", valid_591734
  var valid_591735 = header.getOrDefault("X-Amz-Credential")
  valid_591735 = validateParameter(valid_591735, JString, required = false,
                                 default = nil)
  if valid_591735 != nil:
    section.add "X-Amz-Credential", valid_591735
  var valid_591736 = header.getOrDefault("X-Amz-Security-Token")
  valid_591736 = validateParameter(valid_591736, JString, required = false,
                                 default = nil)
  if valid_591736 != nil:
    section.add "X-Amz-Security-Token", valid_591736
  var valid_591737 = header.getOrDefault("X-Amz-Algorithm")
  valid_591737 = validateParameter(valid_591737, JString, required = false,
                                 default = nil)
  if valid_591737 != nil:
    section.add "X-Amz-Algorithm", valid_591737
  var valid_591738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591738 = validateParameter(valid_591738, JString, required = false,
                                 default = nil)
  if valid_591738 != nil:
    section.add "X-Amz-SignedHeaders", valid_591738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591740: Call_PutEventStream_591728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ## 
  let valid = call_591740.validator(path, query, header, formData, body)
  let scheme = call_591740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591740.url(scheme.get, call_591740.host, call_591740.base,
                         call_591740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591740, url, valid)

proc call*(call_591741: Call_PutEventStream_591728; applicationId: string;
          body: JsonNode): Recallable =
  ## putEventStream
  ## Creates a new event stream for an application or updates the settings of an existing event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591742 = newJObject()
  var body_591743 = newJObject()
  add(path_591742, "application-id", newJString(applicationId))
  if body != nil:
    body_591743 = body
  result = call_591741.call(path_591742, nil, nil, nil, body_591743)

var putEventStream* = Call_PutEventStream_591728(name: "putEventStream",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_PutEventStream_591729, base: "/", url: url_PutEventStream_591730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventStream_591714 = ref object of OpenApiRestCall_590348
proc url_GetEventStream_591716(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventStream_591715(path: JsonNode; query: JsonNode;
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
  var valid_591717 = path.getOrDefault("application-id")
  valid_591717 = validateParameter(valid_591717, JString, required = true,
                                 default = nil)
  if valid_591717 != nil:
    section.add "application-id", valid_591717
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591718 = header.getOrDefault("X-Amz-Signature")
  valid_591718 = validateParameter(valid_591718, JString, required = false,
                                 default = nil)
  if valid_591718 != nil:
    section.add "X-Amz-Signature", valid_591718
  var valid_591719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591719 = validateParameter(valid_591719, JString, required = false,
                                 default = nil)
  if valid_591719 != nil:
    section.add "X-Amz-Content-Sha256", valid_591719
  var valid_591720 = header.getOrDefault("X-Amz-Date")
  valid_591720 = validateParameter(valid_591720, JString, required = false,
                                 default = nil)
  if valid_591720 != nil:
    section.add "X-Amz-Date", valid_591720
  var valid_591721 = header.getOrDefault("X-Amz-Credential")
  valid_591721 = validateParameter(valid_591721, JString, required = false,
                                 default = nil)
  if valid_591721 != nil:
    section.add "X-Amz-Credential", valid_591721
  var valid_591722 = header.getOrDefault("X-Amz-Security-Token")
  valid_591722 = validateParameter(valid_591722, JString, required = false,
                                 default = nil)
  if valid_591722 != nil:
    section.add "X-Amz-Security-Token", valid_591722
  var valid_591723 = header.getOrDefault("X-Amz-Algorithm")
  valid_591723 = validateParameter(valid_591723, JString, required = false,
                                 default = nil)
  if valid_591723 != nil:
    section.add "X-Amz-Algorithm", valid_591723
  var valid_591724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591724 = validateParameter(valid_591724, JString, required = false,
                                 default = nil)
  if valid_591724 != nil:
    section.add "X-Amz-SignedHeaders", valid_591724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591725: Call_GetEventStream_591714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the event stream settings for an application.
  ## 
  let valid = call_591725.validator(path, query, header, formData, body)
  let scheme = call_591725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591725.url(scheme.get, call_591725.host, call_591725.base,
                         call_591725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591725, url, valid)

proc call*(call_591726: Call_GetEventStream_591714; applicationId: string): Recallable =
  ## getEventStream
  ## Retrieves information about the event stream settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591727 = newJObject()
  add(path_591727, "application-id", newJString(applicationId))
  result = call_591726.call(path_591727, nil, nil, nil, nil)

var getEventStream* = Call_GetEventStream_591714(name: "getEventStream",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_GetEventStream_591715, base: "/", url: url_GetEventStream_591716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventStream_591744 = ref object of OpenApiRestCall_590348
proc url_DeleteEventStream_591746(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEventStream_591745(path: JsonNode; query: JsonNode;
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
  var valid_591747 = path.getOrDefault("application-id")
  valid_591747 = validateParameter(valid_591747, JString, required = true,
                                 default = nil)
  if valid_591747 != nil:
    section.add "application-id", valid_591747
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591748 = header.getOrDefault("X-Amz-Signature")
  valid_591748 = validateParameter(valid_591748, JString, required = false,
                                 default = nil)
  if valid_591748 != nil:
    section.add "X-Amz-Signature", valid_591748
  var valid_591749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591749 = validateParameter(valid_591749, JString, required = false,
                                 default = nil)
  if valid_591749 != nil:
    section.add "X-Amz-Content-Sha256", valid_591749
  var valid_591750 = header.getOrDefault("X-Amz-Date")
  valid_591750 = validateParameter(valid_591750, JString, required = false,
                                 default = nil)
  if valid_591750 != nil:
    section.add "X-Amz-Date", valid_591750
  var valid_591751 = header.getOrDefault("X-Amz-Credential")
  valid_591751 = validateParameter(valid_591751, JString, required = false,
                                 default = nil)
  if valid_591751 != nil:
    section.add "X-Amz-Credential", valid_591751
  var valid_591752 = header.getOrDefault("X-Amz-Security-Token")
  valid_591752 = validateParameter(valid_591752, JString, required = false,
                                 default = nil)
  if valid_591752 != nil:
    section.add "X-Amz-Security-Token", valid_591752
  var valid_591753 = header.getOrDefault("X-Amz-Algorithm")
  valid_591753 = validateParameter(valid_591753, JString, required = false,
                                 default = nil)
  if valid_591753 != nil:
    section.add "X-Amz-Algorithm", valid_591753
  var valid_591754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591754 = validateParameter(valid_591754, JString, required = false,
                                 default = nil)
  if valid_591754 != nil:
    section.add "X-Amz-SignedHeaders", valid_591754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591755: Call_DeleteEventStream_591744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the event stream for an application.
  ## 
  let valid = call_591755.validator(path, query, header, formData, body)
  let scheme = call_591755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591755.url(scheme.get, call_591755.host, call_591755.base,
                         call_591755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591755, url, valid)

proc call*(call_591756: Call_DeleteEventStream_591744; applicationId: string): Recallable =
  ## deleteEventStream
  ## Deletes the event stream for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591757 = newJObject()
  add(path_591757, "application-id", newJString(applicationId))
  result = call_591756.call(path_591757, nil, nil, nil, nil)

var deleteEventStream* = Call_DeleteEventStream_591744(name: "deleteEventStream",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/eventstream",
    validator: validate_DeleteEventStream_591745, base: "/",
    url: url_DeleteEventStream_591746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGcmChannel_591772 = ref object of OpenApiRestCall_590348
proc url_UpdateGcmChannel_591774(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGcmChannel_591773(path: JsonNode; query: JsonNode;
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
  var valid_591775 = path.getOrDefault("application-id")
  valid_591775 = validateParameter(valid_591775, JString, required = true,
                                 default = nil)
  if valid_591775 != nil:
    section.add "application-id", valid_591775
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591776 = header.getOrDefault("X-Amz-Signature")
  valid_591776 = validateParameter(valid_591776, JString, required = false,
                                 default = nil)
  if valid_591776 != nil:
    section.add "X-Amz-Signature", valid_591776
  var valid_591777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591777 = validateParameter(valid_591777, JString, required = false,
                                 default = nil)
  if valid_591777 != nil:
    section.add "X-Amz-Content-Sha256", valid_591777
  var valid_591778 = header.getOrDefault("X-Amz-Date")
  valid_591778 = validateParameter(valid_591778, JString, required = false,
                                 default = nil)
  if valid_591778 != nil:
    section.add "X-Amz-Date", valid_591778
  var valid_591779 = header.getOrDefault("X-Amz-Credential")
  valid_591779 = validateParameter(valid_591779, JString, required = false,
                                 default = nil)
  if valid_591779 != nil:
    section.add "X-Amz-Credential", valid_591779
  var valid_591780 = header.getOrDefault("X-Amz-Security-Token")
  valid_591780 = validateParameter(valid_591780, JString, required = false,
                                 default = nil)
  if valid_591780 != nil:
    section.add "X-Amz-Security-Token", valid_591780
  var valid_591781 = header.getOrDefault("X-Amz-Algorithm")
  valid_591781 = validateParameter(valid_591781, JString, required = false,
                                 default = nil)
  if valid_591781 != nil:
    section.add "X-Amz-Algorithm", valid_591781
  var valid_591782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591782 = validateParameter(valid_591782, JString, required = false,
                                 default = nil)
  if valid_591782 != nil:
    section.add "X-Amz-SignedHeaders", valid_591782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591784: Call_UpdateGcmChannel_591772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ## 
  let valid = call_591784.validator(path, query, header, formData, body)
  let scheme = call_591784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591784.url(scheme.get, call_591784.host, call_591784.base,
                         call_591784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591784, url, valid)

proc call*(call_591785: Call_UpdateGcmChannel_591772; applicationId: string;
          body: JsonNode): Recallable =
  ## updateGcmChannel
  ## Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591786 = newJObject()
  var body_591787 = newJObject()
  add(path_591786, "application-id", newJString(applicationId))
  if body != nil:
    body_591787 = body
  result = call_591785.call(path_591786, nil, nil, nil, body_591787)

var updateGcmChannel* = Call_UpdateGcmChannel_591772(name: "updateGcmChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_UpdateGcmChannel_591773, base: "/",
    url: url_UpdateGcmChannel_591774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGcmChannel_591758 = ref object of OpenApiRestCall_590348
proc url_GetGcmChannel_591760(protocol: Scheme; host: string; base: string;
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

proc validate_GetGcmChannel_591759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591761 = path.getOrDefault("application-id")
  valid_591761 = validateParameter(valid_591761, JString, required = true,
                                 default = nil)
  if valid_591761 != nil:
    section.add "application-id", valid_591761
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591762 = header.getOrDefault("X-Amz-Signature")
  valid_591762 = validateParameter(valid_591762, JString, required = false,
                                 default = nil)
  if valid_591762 != nil:
    section.add "X-Amz-Signature", valid_591762
  var valid_591763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591763 = validateParameter(valid_591763, JString, required = false,
                                 default = nil)
  if valid_591763 != nil:
    section.add "X-Amz-Content-Sha256", valid_591763
  var valid_591764 = header.getOrDefault("X-Amz-Date")
  valid_591764 = validateParameter(valid_591764, JString, required = false,
                                 default = nil)
  if valid_591764 != nil:
    section.add "X-Amz-Date", valid_591764
  var valid_591765 = header.getOrDefault("X-Amz-Credential")
  valid_591765 = validateParameter(valid_591765, JString, required = false,
                                 default = nil)
  if valid_591765 != nil:
    section.add "X-Amz-Credential", valid_591765
  var valid_591766 = header.getOrDefault("X-Amz-Security-Token")
  valid_591766 = validateParameter(valid_591766, JString, required = false,
                                 default = nil)
  if valid_591766 != nil:
    section.add "X-Amz-Security-Token", valid_591766
  var valid_591767 = header.getOrDefault("X-Amz-Algorithm")
  valid_591767 = validateParameter(valid_591767, JString, required = false,
                                 default = nil)
  if valid_591767 != nil:
    section.add "X-Amz-Algorithm", valid_591767
  var valid_591768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591768 = validateParameter(valid_591768, JString, required = false,
                                 default = nil)
  if valid_591768 != nil:
    section.add "X-Amz-SignedHeaders", valid_591768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591769: Call_GetGcmChannel_591758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ## 
  let valid = call_591769.validator(path, query, header, formData, body)
  let scheme = call_591769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591769.url(scheme.get, call_591769.host, call_591769.base,
                         call_591769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591769, url, valid)

proc call*(call_591770: Call_GetGcmChannel_591758; applicationId: string): Recallable =
  ## getGcmChannel
  ## Retrieves information about the status and settings of the GCM channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591771 = newJObject()
  add(path_591771, "application-id", newJString(applicationId))
  result = call_591770.call(path_591771, nil, nil, nil, nil)

var getGcmChannel* = Call_GetGcmChannel_591758(name: "getGcmChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_GetGcmChannel_591759, base: "/", url: url_GetGcmChannel_591760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGcmChannel_591788 = ref object of OpenApiRestCall_590348
proc url_DeleteGcmChannel_591790(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGcmChannel_591789(path: JsonNode; query: JsonNode;
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
  var valid_591791 = path.getOrDefault("application-id")
  valid_591791 = validateParameter(valid_591791, JString, required = true,
                                 default = nil)
  if valid_591791 != nil:
    section.add "application-id", valid_591791
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591792 = header.getOrDefault("X-Amz-Signature")
  valid_591792 = validateParameter(valid_591792, JString, required = false,
                                 default = nil)
  if valid_591792 != nil:
    section.add "X-Amz-Signature", valid_591792
  var valid_591793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591793 = validateParameter(valid_591793, JString, required = false,
                                 default = nil)
  if valid_591793 != nil:
    section.add "X-Amz-Content-Sha256", valid_591793
  var valid_591794 = header.getOrDefault("X-Amz-Date")
  valid_591794 = validateParameter(valid_591794, JString, required = false,
                                 default = nil)
  if valid_591794 != nil:
    section.add "X-Amz-Date", valid_591794
  var valid_591795 = header.getOrDefault("X-Amz-Credential")
  valid_591795 = validateParameter(valid_591795, JString, required = false,
                                 default = nil)
  if valid_591795 != nil:
    section.add "X-Amz-Credential", valid_591795
  var valid_591796 = header.getOrDefault("X-Amz-Security-Token")
  valid_591796 = validateParameter(valid_591796, JString, required = false,
                                 default = nil)
  if valid_591796 != nil:
    section.add "X-Amz-Security-Token", valid_591796
  var valid_591797 = header.getOrDefault("X-Amz-Algorithm")
  valid_591797 = validateParameter(valid_591797, JString, required = false,
                                 default = nil)
  if valid_591797 != nil:
    section.add "X-Amz-Algorithm", valid_591797
  var valid_591798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591798 = validateParameter(valid_591798, JString, required = false,
                                 default = nil)
  if valid_591798 != nil:
    section.add "X-Amz-SignedHeaders", valid_591798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591799: Call_DeleteGcmChannel_591788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591799.validator(path, query, header, formData, body)
  let scheme = call_591799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591799.url(scheme.get, call_591799.host, call_591799.base,
                         call_591799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591799, url, valid)

proc call*(call_591800: Call_DeleteGcmChannel_591788; applicationId: string): Recallable =
  ## deleteGcmChannel
  ## Disables the GCM channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591801 = newJObject()
  add(path_591801, "application-id", newJString(applicationId))
  result = call_591800.call(path_591801, nil, nil, nil, nil)

var deleteGcmChannel* = Call_DeleteGcmChannel_591788(name: "deleteGcmChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/gcm",
    validator: validate_DeleteGcmChannel_591789, base: "/",
    url: url_DeleteGcmChannel_591790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSegment_591817 = ref object of OpenApiRestCall_590348
proc url_UpdateSegment_591819(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSegment_591818(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591820 = path.getOrDefault("application-id")
  valid_591820 = validateParameter(valid_591820, JString, required = true,
                                 default = nil)
  if valid_591820 != nil:
    section.add "application-id", valid_591820
  var valid_591821 = path.getOrDefault("segment-id")
  valid_591821 = validateParameter(valid_591821, JString, required = true,
                                 default = nil)
  if valid_591821 != nil:
    section.add "segment-id", valid_591821
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591822 = header.getOrDefault("X-Amz-Signature")
  valid_591822 = validateParameter(valid_591822, JString, required = false,
                                 default = nil)
  if valid_591822 != nil:
    section.add "X-Amz-Signature", valid_591822
  var valid_591823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-Content-Sha256", valid_591823
  var valid_591824 = header.getOrDefault("X-Amz-Date")
  valid_591824 = validateParameter(valid_591824, JString, required = false,
                                 default = nil)
  if valid_591824 != nil:
    section.add "X-Amz-Date", valid_591824
  var valid_591825 = header.getOrDefault("X-Amz-Credential")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-Credential", valid_591825
  var valid_591826 = header.getOrDefault("X-Amz-Security-Token")
  valid_591826 = validateParameter(valid_591826, JString, required = false,
                                 default = nil)
  if valid_591826 != nil:
    section.add "X-Amz-Security-Token", valid_591826
  var valid_591827 = header.getOrDefault("X-Amz-Algorithm")
  valid_591827 = validateParameter(valid_591827, JString, required = false,
                                 default = nil)
  if valid_591827 != nil:
    section.add "X-Amz-Algorithm", valid_591827
  var valid_591828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591828 = validateParameter(valid_591828, JString, required = false,
                                 default = nil)
  if valid_591828 != nil:
    section.add "X-Amz-SignedHeaders", valid_591828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591830: Call_UpdateSegment_591817; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ## 
  let valid = call_591830.validator(path, query, header, formData, body)
  let scheme = call_591830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591830.url(scheme.get, call_591830.host, call_591830.base,
                         call_591830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591830, url, valid)

proc call*(call_591831: Call_UpdateSegment_591817; applicationId: string;
          segmentId: string; body: JsonNode): Recallable =
  ## updateSegment
  ## Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   body: JObject (required)
  var path_591832 = newJObject()
  var body_591833 = newJObject()
  add(path_591832, "application-id", newJString(applicationId))
  add(path_591832, "segment-id", newJString(segmentId))
  if body != nil:
    body_591833 = body
  result = call_591831.call(path_591832, nil, nil, nil, body_591833)

var updateSegment* = Call_UpdateSegment_591817(name: "updateSegment",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_UpdateSegment_591818, base: "/", url: url_UpdateSegment_591819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegment_591802 = ref object of OpenApiRestCall_590348
proc url_GetSegment_591804(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSegment_591803(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591805 = path.getOrDefault("application-id")
  valid_591805 = validateParameter(valid_591805, JString, required = true,
                                 default = nil)
  if valid_591805 != nil:
    section.add "application-id", valid_591805
  var valid_591806 = path.getOrDefault("segment-id")
  valid_591806 = validateParameter(valid_591806, JString, required = true,
                                 default = nil)
  if valid_591806 != nil:
    section.add "segment-id", valid_591806
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591807 = header.getOrDefault("X-Amz-Signature")
  valid_591807 = validateParameter(valid_591807, JString, required = false,
                                 default = nil)
  if valid_591807 != nil:
    section.add "X-Amz-Signature", valid_591807
  var valid_591808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591808 = validateParameter(valid_591808, JString, required = false,
                                 default = nil)
  if valid_591808 != nil:
    section.add "X-Amz-Content-Sha256", valid_591808
  var valid_591809 = header.getOrDefault("X-Amz-Date")
  valid_591809 = validateParameter(valid_591809, JString, required = false,
                                 default = nil)
  if valid_591809 != nil:
    section.add "X-Amz-Date", valid_591809
  var valid_591810 = header.getOrDefault("X-Amz-Credential")
  valid_591810 = validateParameter(valid_591810, JString, required = false,
                                 default = nil)
  if valid_591810 != nil:
    section.add "X-Amz-Credential", valid_591810
  var valid_591811 = header.getOrDefault("X-Amz-Security-Token")
  valid_591811 = validateParameter(valid_591811, JString, required = false,
                                 default = nil)
  if valid_591811 != nil:
    section.add "X-Amz-Security-Token", valid_591811
  var valid_591812 = header.getOrDefault("X-Amz-Algorithm")
  valid_591812 = validateParameter(valid_591812, JString, required = false,
                                 default = nil)
  if valid_591812 != nil:
    section.add "X-Amz-Algorithm", valid_591812
  var valid_591813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591813 = validateParameter(valid_591813, JString, required = false,
                                 default = nil)
  if valid_591813 != nil:
    section.add "X-Amz-SignedHeaders", valid_591813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591814: Call_GetSegment_591802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ## 
  let valid = call_591814.validator(path, query, header, formData, body)
  let scheme = call_591814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591814.url(scheme.get, call_591814.host, call_591814.base,
                         call_591814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591814, url, valid)

proc call*(call_591815: Call_GetSegment_591802; applicationId: string;
          segmentId: string): Recallable =
  ## getSegment
  ## Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_591816 = newJObject()
  add(path_591816, "application-id", newJString(applicationId))
  add(path_591816, "segment-id", newJString(segmentId))
  result = call_591815.call(path_591816, nil, nil, nil, nil)

var getSegment* = Call_GetSegment_591802(name: "getSegment",
                                      meth: HttpMethod.HttpGet,
                                      host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}",
                                      validator: validate_GetSegment_591803,
                                      base: "/", url: url_GetSegment_591804,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSegment_591834 = ref object of OpenApiRestCall_590348
proc url_DeleteSegment_591836(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSegment_591835(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591837 = path.getOrDefault("application-id")
  valid_591837 = validateParameter(valid_591837, JString, required = true,
                                 default = nil)
  if valid_591837 != nil:
    section.add "application-id", valid_591837
  var valid_591838 = path.getOrDefault("segment-id")
  valid_591838 = validateParameter(valid_591838, JString, required = true,
                                 default = nil)
  if valid_591838 != nil:
    section.add "segment-id", valid_591838
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591839 = header.getOrDefault("X-Amz-Signature")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Signature", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Content-Sha256", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-Date")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-Date", valid_591841
  var valid_591842 = header.getOrDefault("X-Amz-Credential")
  valid_591842 = validateParameter(valid_591842, JString, required = false,
                                 default = nil)
  if valid_591842 != nil:
    section.add "X-Amz-Credential", valid_591842
  var valid_591843 = header.getOrDefault("X-Amz-Security-Token")
  valid_591843 = validateParameter(valid_591843, JString, required = false,
                                 default = nil)
  if valid_591843 != nil:
    section.add "X-Amz-Security-Token", valid_591843
  var valid_591844 = header.getOrDefault("X-Amz-Algorithm")
  valid_591844 = validateParameter(valid_591844, JString, required = false,
                                 default = nil)
  if valid_591844 != nil:
    section.add "X-Amz-Algorithm", valid_591844
  var valid_591845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591845 = validateParameter(valid_591845, JString, required = false,
                                 default = nil)
  if valid_591845 != nil:
    section.add "X-Amz-SignedHeaders", valid_591845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591846: Call_DeleteSegment_591834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a segment from an application.
  ## 
  let valid = call_591846.validator(path, query, header, formData, body)
  let scheme = call_591846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591846.url(scheme.get, call_591846.host, call_591846.base,
                         call_591846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591846, url, valid)

proc call*(call_591847: Call_DeleteSegment_591834; applicationId: string;
          segmentId: string): Recallable =
  ## deleteSegment
  ## Deletes a segment from an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_591848 = newJObject()
  add(path_591848, "application-id", newJString(applicationId))
  add(path_591848, "segment-id", newJString(segmentId))
  result = call_591847.call(path_591848, nil, nil, nil, nil)

var deleteSegment* = Call_DeleteSegment_591834(name: "deleteSegment",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}",
    validator: validate_DeleteSegment_591835, base: "/", url: url_DeleteSegment_591836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSmsChannel_591863 = ref object of OpenApiRestCall_590348
proc url_UpdateSmsChannel_591865(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSmsChannel_591864(path: JsonNode; query: JsonNode;
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
  var valid_591866 = path.getOrDefault("application-id")
  valid_591866 = validateParameter(valid_591866, JString, required = true,
                                 default = nil)
  if valid_591866 != nil:
    section.add "application-id", valid_591866
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591867 = header.getOrDefault("X-Amz-Signature")
  valid_591867 = validateParameter(valid_591867, JString, required = false,
                                 default = nil)
  if valid_591867 != nil:
    section.add "X-Amz-Signature", valid_591867
  var valid_591868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591868 = validateParameter(valid_591868, JString, required = false,
                                 default = nil)
  if valid_591868 != nil:
    section.add "X-Amz-Content-Sha256", valid_591868
  var valid_591869 = header.getOrDefault("X-Amz-Date")
  valid_591869 = validateParameter(valid_591869, JString, required = false,
                                 default = nil)
  if valid_591869 != nil:
    section.add "X-Amz-Date", valid_591869
  var valid_591870 = header.getOrDefault("X-Amz-Credential")
  valid_591870 = validateParameter(valid_591870, JString, required = false,
                                 default = nil)
  if valid_591870 != nil:
    section.add "X-Amz-Credential", valid_591870
  var valid_591871 = header.getOrDefault("X-Amz-Security-Token")
  valid_591871 = validateParameter(valid_591871, JString, required = false,
                                 default = nil)
  if valid_591871 != nil:
    section.add "X-Amz-Security-Token", valid_591871
  var valid_591872 = header.getOrDefault("X-Amz-Algorithm")
  valid_591872 = validateParameter(valid_591872, JString, required = false,
                                 default = nil)
  if valid_591872 != nil:
    section.add "X-Amz-Algorithm", valid_591872
  var valid_591873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591873 = validateParameter(valid_591873, JString, required = false,
                                 default = nil)
  if valid_591873 != nil:
    section.add "X-Amz-SignedHeaders", valid_591873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591875: Call_UpdateSmsChannel_591863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ## 
  let valid = call_591875.validator(path, query, header, formData, body)
  let scheme = call_591875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591875.url(scheme.get, call_591875.host, call_591875.base,
                         call_591875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591875, url, valid)

proc call*(call_591876: Call_UpdateSmsChannel_591863; applicationId: string;
          body: JsonNode): Recallable =
  ## updateSmsChannel
  ## Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591877 = newJObject()
  var body_591878 = newJObject()
  add(path_591877, "application-id", newJString(applicationId))
  if body != nil:
    body_591878 = body
  result = call_591876.call(path_591877, nil, nil, nil, body_591878)

var updateSmsChannel* = Call_UpdateSmsChannel_591863(name: "updateSmsChannel",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_UpdateSmsChannel_591864, base: "/",
    url: url_UpdateSmsChannel_591865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSmsChannel_591849 = ref object of OpenApiRestCall_590348
proc url_GetSmsChannel_591851(protocol: Scheme; host: string; base: string;
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

proc validate_GetSmsChannel_591850(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591852 = path.getOrDefault("application-id")
  valid_591852 = validateParameter(valid_591852, JString, required = true,
                                 default = nil)
  if valid_591852 != nil:
    section.add "application-id", valid_591852
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591853 = header.getOrDefault("X-Amz-Signature")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "X-Amz-Signature", valid_591853
  var valid_591854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591854 = validateParameter(valid_591854, JString, required = false,
                                 default = nil)
  if valid_591854 != nil:
    section.add "X-Amz-Content-Sha256", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Date")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Date", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-Credential")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-Credential", valid_591856
  var valid_591857 = header.getOrDefault("X-Amz-Security-Token")
  valid_591857 = validateParameter(valid_591857, JString, required = false,
                                 default = nil)
  if valid_591857 != nil:
    section.add "X-Amz-Security-Token", valid_591857
  var valid_591858 = header.getOrDefault("X-Amz-Algorithm")
  valid_591858 = validateParameter(valid_591858, JString, required = false,
                                 default = nil)
  if valid_591858 != nil:
    section.add "X-Amz-Algorithm", valid_591858
  var valid_591859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591859 = validateParameter(valid_591859, JString, required = false,
                                 default = nil)
  if valid_591859 != nil:
    section.add "X-Amz-SignedHeaders", valid_591859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591860: Call_GetSmsChannel_591849; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ## 
  let valid = call_591860.validator(path, query, header, formData, body)
  let scheme = call_591860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591860.url(scheme.get, call_591860.host, call_591860.base,
                         call_591860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591860, url, valid)

proc call*(call_591861: Call_GetSmsChannel_591849; applicationId: string): Recallable =
  ## getSmsChannel
  ## Retrieves information about the status and settings of the SMS channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591862 = newJObject()
  add(path_591862, "application-id", newJString(applicationId))
  result = call_591861.call(path_591862, nil, nil, nil, nil)

var getSmsChannel* = Call_GetSmsChannel_591849(name: "getSmsChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_GetSmsChannel_591850, base: "/", url: url_GetSmsChannel_591851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSmsChannel_591879 = ref object of OpenApiRestCall_590348
proc url_DeleteSmsChannel_591881(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSmsChannel_591880(path: JsonNode; query: JsonNode;
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
  var valid_591882 = path.getOrDefault("application-id")
  valid_591882 = validateParameter(valid_591882, JString, required = true,
                                 default = nil)
  if valid_591882 != nil:
    section.add "application-id", valid_591882
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591883 = header.getOrDefault("X-Amz-Signature")
  valid_591883 = validateParameter(valid_591883, JString, required = false,
                                 default = nil)
  if valid_591883 != nil:
    section.add "X-Amz-Signature", valid_591883
  var valid_591884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591884 = validateParameter(valid_591884, JString, required = false,
                                 default = nil)
  if valid_591884 != nil:
    section.add "X-Amz-Content-Sha256", valid_591884
  var valid_591885 = header.getOrDefault("X-Amz-Date")
  valid_591885 = validateParameter(valid_591885, JString, required = false,
                                 default = nil)
  if valid_591885 != nil:
    section.add "X-Amz-Date", valid_591885
  var valid_591886 = header.getOrDefault("X-Amz-Credential")
  valid_591886 = validateParameter(valid_591886, JString, required = false,
                                 default = nil)
  if valid_591886 != nil:
    section.add "X-Amz-Credential", valid_591886
  var valid_591887 = header.getOrDefault("X-Amz-Security-Token")
  valid_591887 = validateParameter(valid_591887, JString, required = false,
                                 default = nil)
  if valid_591887 != nil:
    section.add "X-Amz-Security-Token", valid_591887
  var valid_591888 = header.getOrDefault("X-Amz-Algorithm")
  valid_591888 = validateParameter(valid_591888, JString, required = false,
                                 default = nil)
  if valid_591888 != nil:
    section.add "X-Amz-Algorithm", valid_591888
  var valid_591889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591889 = validateParameter(valid_591889, JString, required = false,
                                 default = nil)
  if valid_591889 != nil:
    section.add "X-Amz-SignedHeaders", valid_591889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591890: Call_DeleteSmsChannel_591879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591890.validator(path, query, header, formData, body)
  let scheme = call_591890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591890.url(scheme.get, call_591890.host, call_591890.base,
                         call_591890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591890, url, valid)

proc call*(call_591891: Call_DeleteSmsChannel_591879; applicationId: string): Recallable =
  ## deleteSmsChannel
  ## Disables the SMS channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591892 = newJObject()
  add(path_591892, "application-id", newJString(applicationId))
  result = call_591891.call(path_591892, nil, nil, nil, nil)

var deleteSmsChannel* = Call_DeleteSmsChannel_591879(name: "deleteSmsChannel",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/sms",
    validator: validate_DeleteSmsChannel_591880, base: "/",
    url: url_DeleteSmsChannel_591881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserEndpoints_591893 = ref object of OpenApiRestCall_590348
proc url_GetUserEndpoints_591895(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserEndpoints_591894(path: JsonNode; query: JsonNode;
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
  var valid_591896 = path.getOrDefault("application-id")
  valid_591896 = validateParameter(valid_591896, JString, required = true,
                                 default = nil)
  if valid_591896 != nil:
    section.add "application-id", valid_591896
  var valid_591897 = path.getOrDefault("user-id")
  valid_591897 = validateParameter(valid_591897, JString, required = true,
                                 default = nil)
  if valid_591897 != nil:
    section.add "user-id", valid_591897
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591898 = header.getOrDefault("X-Amz-Signature")
  valid_591898 = validateParameter(valid_591898, JString, required = false,
                                 default = nil)
  if valid_591898 != nil:
    section.add "X-Amz-Signature", valid_591898
  var valid_591899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591899 = validateParameter(valid_591899, JString, required = false,
                                 default = nil)
  if valid_591899 != nil:
    section.add "X-Amz-Content-Sha256", valid_591899
  var valid_591900 = header.getOrDefault("X-Amz-Date")
  valid_591900 = validateParameter(valid_591900, JString, required = false,
                                 default = nil)
  if valid_591900 != nil:
    section.add "X-Amz-Date", valid_591900
  var valid_591901 = header.getOrDefault("X-Amz-Credential")
  valid_591901 = validateParameter(valid_591901, JString, required = false,
                                 default = nil)
  if valid_591901 != nil:
    section.add "X-Amz-Credential", valid_591901
  var valid_591902 = header.getOrDefault("X-Amz-Security-Token")
  valid_591902 = validateParameter(valid_591902, JString, required = false,
                                 default = nil)
  if valid_591902 != nil:
    section.add "X-Amz-Security-Token", valid_591902
  var valid_591903 = header.getOrDefault("X-Amz-Algorithm")
  valid_591903 = validateParameter(valid_591903, JString, required = false,
                                 default = nil)
  if valid_591903 != nil:
    section.add "X-Amz-Algorithm", valid_591903
  var valid_591904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591904 = validateParameter(valid_591904, JString, required = false,
                                 default = nil)
  if valid_591904 != nil:
    section.add "X-Amz-SignedHeaders", valid_591904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591905: Call_GetUserEndpoints_591893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_591905.validator(path, query, header, formData, body)
  let scheme = call_591905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591905.url(scheme.get, call_591905.host, call_591905.base,
                         call_591905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591905, url, valid)

proc call*(call_591906: Call_GetUserEndpoints_591893; applicationId: string;
          userId: string): Recallable =
  ## getUserEndpoints
  ## Retrieves information about all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_591907 = newJObject()
  add(path_591907, "application-id", newJString(applicationId))
  add(path_591907, "user-id", newJString(userId))
  result = call_591906.call(path_591907, nil, nil, nil, nil)

var getUserEndpoints* = Call_GetUserEndpoints_591893(name: "getUserEndpoints",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_GetUserEndpoints_591894, base: "/",
    url: url_GetUserEndpoints_591895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserEndpoints_591908 = ref object of OpenApiRestCall_590348
proc url_DeleteUserEndpoints_591910(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserEndpoints_591909(path: JsonNode; query: JsonNode;
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
  var valid_591911 = path.getOrDefault("application-id")
  valid_591911 = validateParameter(valid_591911, JString, required = true,
                                 default = nil)
  if valid_591911 != nil:
    section.add "application-id", valid_591911
  var valid_591912 = path.getOrDefault("user-id")
  valid_591912 = validateParameter(valid_591912, JString, required = true,
                                 default = nil)
  if valid_591912 != nil:
    section.add "user-id", valid_591912
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591913 = header.getOrDefault("X-Amz-Signature")
  valid_591913 = validateParameter(valid_591913, JString, required = false,
                                 default = nil)
  if valid_591913 != nil:
    section.add "X-Amz-Signature", valid_591913
  var valid_591914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591914 = validateParameter(valid_591914, JString, required = false,
                                 default = nil)
  if valid_591914 != nil:
    section.add "X-Amz-Content-Sha256", valid_591914
  var valid_591915 = header.getOrDefault("X-Amz-Date")
  valid_591915 = validateParameter(valid_591915, JString, required = false,
                                 default = nil)
  if valid_591915 != nil:
    section.add "X-Amz-Date", valid_591915
  var valid_591916 = header.getOrDefault("X-Amz-Credential")
  valid_591916 = validateParameter(valid_591916, JString, required = false,
                                 default = nil)
  if valid_591916 != nil:
    section.add "X-Amz-Credential", valid_591916
  var valid_591917 = header.getOrDefault("X-Amz-Security-Token")
  valid_591917 = validateParameter(valid_591917, JString, required = false,
                                 default = nil)
  if valid_591917 != nil:
    section.add "X-Amz-Security-Token", valid_591917
  var valid_591918 = header.getOrDefault("X-Amz-Algorithm")
  valid_591918 = validateParameter(valid_591918, JString, required = false,
                                 default = nil)
  if valid_591918 != nil:
    section.add "X-Amz-Algorithm", valid_591918
  var valid_591919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591919 = validateParameter(valid_591919, JString, required = false,
                                 default = nil)
  if valid_591919 != nil:
    section.add "X-Amz-SignedHeaders", valid_591919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591920: Call_DeleteUserEndpoints_591908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all the endpoints that are associated with a specific user ID.
  ## 
  let valid = call_591920.validator(path, query, header, formData, body)
  let scheme = call_591920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591920.url(scheme.get, call_591920.host, call_591920.base,
                         call_591920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591920, url, valid)

proc call*(call_591921: Call_DeleteUserEndpoints_591908; applicationId: string;
          userId: string): Recallable =
  ## deleteUserEndpoints
  ## Deletes all the endpoints that are associated with a specific user ID.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   userId: string (required)
  ##         : The unique identifier for the user.
  var path_591922 = newJObject()
  add(path_591922, "application-id", newJString(applicationId))
  add(path_591922, "user-id", newJString(userId))
  result = call_591921.call(path_591922, nil, nil, nil, nil)

var deleteUserEndpoints* = Call_DeleteUserEndpoints_591908(
    name: "deleteUserEndpoints", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users/{user-id}",
    validator: validate_DeleteUserEndpoints_591909, base: "/",
    url: url_DeleteUserEndpoints_591910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceChannel_591937 = ref object of OpenApiRestCall_590348
proc url_UpdateVoiceChannel_591939(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceChannel_591938(path: JsonNode; query: JsonNode;
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
  var valid_591940 = path.getOrDefault("application-id")
  valid_591940 = validateParameter(valid_591940, JString, required = true,
                                 default = nil)
  if valid_591940 != nil:
    section.add "application-id", valid_591940
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591941 = header.getOrDefault("X-Amz-Signature")
  valid_591941 = validateParameter(valid_591941, JString, required = false,
                                 default = nil)
  if valid_591941 != nil:
    section.add "X-Amz-Signature", valid_591941
  var valid_591942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591942 = validateParameter(valid_591942, JString, required = false,
                                 default = nil)
  if valid_591942 != nil:
    section.add "X-Amz-Content-Sha256", valid_591942
  var valid_591943 = header.getOrDefault("X-Amz-Date")
  valid_591943 = validateParameter(valid_591943, JString, required = false,
                                 default = nil)
  if valid_591943 != nil:
    section.add "X-Amz-Date", valid_591943
  var valid_591944 = header.getOrDefault("X-Amz-Credential")
  valid_591944 = validateParameter(valid_591944, JString, required = false,
                                 default = nil)
  if valid_591944 != nil:
    section.add "X-Amz-Credential", valid_591944
  var valid_591945 = header.getOrDefault("X-Amz-Security-Token")
  valid_591945 = validateParameter(valid_591945, JString, required = false,
                                 default = nil)
  if valid_591945 != nil:
    section.add "X-Amz-Security-Token", valid_591945
  var valid_591946 = header.getOrDefault("X-Amz-Algorithm")
  valid_591946 = validateParameter(valid_591946, JString, required = false,
                                 default = nil)
  if valid_591946 != nil:
    section.add "X-Amz-Algorithm", valid_591946
  var valid_591947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591947 = validateParameter(valid_591947, JString, required = false,
                                 default = nil)
  if valid_591947 != nil:
    section.add "X-Amz-SignedHeaders", valid_591947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591949: Call_UpdateVoiceChannel_591937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ## 
  let valid = call_591949.validator(path, query, header, formData, body)
  let scheme = call_591949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591949.url(scheme.get, call_591949.host, call_591949.base,
                         call_591949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591949, url, valid)

proc call*(call_591950: Call_UpdateVoiceChannel_591937; applicationId: string;
          body: JsonNode): Recallable =
  ## updateVoiceChannel
  ## Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_591951 = newJObject()
  var body_591952 = newJObject()
  add(path_591951, "application-id", newJString(applicationId))
  if body != nil:
    body_591952 = body
  result = call_591950.call(path_591951, nil, nil, nil, body_591952)

var updateVoiceChannel* = Call_UpdateVoiceChannel_591937(
    name: "updateVoiceChannel", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_UpdateVoiceChannel_591938, base: "/",
    url: url_UpdateVoiceChannel_591939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceChannel_591923 = ref object of OpenApiRestCall_590348
proc url_GetVoiceChannel_591925(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceChannel_591924(path: JsonNode; query: JsonNode;
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
  var valid_591926 = path.getOrDefault("application-id")
  valid_591926 = validateParameter(valid_591926, JString, required = true,
                                 default = nil)
  if valid_591926 != nil:
    section.add "application-id", valid_591926
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591927 = header.getOrDefault("X-Amz-Signature")
  valid_591927 = validateParameter(valid_591927, JString, required = false,
                                 default = nil)
  if valid_591927 != nil:
    section.add "X-Amz-Signature", valid_591927
  var valid_591928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591928 = validateParameter(valid_591928, JString, required = false,
                                 default = nil)
  if valid_591928 != nil:
    section.add "X-Amz-Content-Sha256", valid_591928
  var valid_591929 = header.getOrDefault("X-Amz-Date")
  valid_591929 = validateParameter(valid_591929, JString, required = false,
                                 default = nil)
  if valid_591929 != nil:
    section.add "X-Amz-Date", valid_591929
  var valid_591930 = header.getOrDefault("X-Amz-Credential")
  valid_591930 = validateParameter(valid_591930, JString, required = false,
                                 default = nil)
  if valid_591930 != nil:
    section.add "X-Amz-Credential", valid_591930
  var valid_591931 = header.getOrDefault("X-Amz-Security-Token")
  valid_591931 = validateParameter(valid_591931, JString, required = false,
                                 default = nil)
  if valid_591931 != nil:
    section.add "X-Amz-Security-Token", valid_591931
  var valid_591932 = header.getOrDefault("X-Amz-Algorithm")
  valid_591932 = validateParameter(valid_591932, JString, required = false,
                                 default = nil)
  if valid_591932 != nil:
    section.add "X-Amz-Algorithm", valid_591932
  var valid_591933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591933 = validateParameter(valid_591933, JString, required = false,
                                 default = nil)
  if valid_591933 != nil:
    section.add "X-Amz-SignedHeaders", valid_591933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591934: Call_GetVoiceChannel_591923; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the voice channel for an application.
  ## 
  let valid = call_591934.validator(path, query, header, formData, body)
  let scheme = call_591934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591934.url(scheme.get, call_591934.host, call_591934.base,
                         call_591934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591934, url, valid)

proc call*(call_591935: Call_GetVoiceChannel_591923; applicationId: string): Recallable =
  ## getVoiceChannel
  ## Retrieves information about the status and settings of the voice channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591936 = newJObject()
  add(path_591936, "application-id", newJString(applicationId))
  result = call_591935.call(path_591936, nil, nil, nil, nil)

var getVoiceChannel* = Call_GetVoiceChannel_591923(name: "getVoiceChannel",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_GetVoiceChannel_591924, base: "/", url: url_GetVoiceChannel_591925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceChannel_591953 = ref object of OpenApiRestCall_590348
proc url_DeleteVoiceChannel_591955(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceChannel_591954(path: JsonNode; query: JsonNode;
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
  var valid_591956 = path.getOrDefault("application-id")
  valid_591956 = validateParameter(valid_591956, JString, required = true,
                                 default = nil)
  if valid_591956 != nil:
    section.add "application-id", valid_591956
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591957 = header.getOrDefault("X-Amz-Signature")
  valid_591957 = validateParameter(valid_591957, JString, required = false,
                                 default = nil)
  if valid_591957 != nil:
    section.add "X-Amz-Signature", valid_591957
  var valid_591958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591958 = validateParameter(valid_591958, JString, required = false,
                                 default = nil)
  if valid_591958 != nil:
    section.add "X-Amz-Content-Sha256", valid_591958
  var valid_591959 = header.getOrDefault("X-Amz-Date")
  valid_591959 = validateParameter(valid_591959, JString, required = false,
                                 default = nil)
  if valid_591959 != nil:
    section.add "X-Amz-Date", valid_591959
  var valid_591960 = header.getOrDefault("X-Amz-Credential")
  valid_591960 = validateParameter(valid_591960, JString, required = false,
                                 default = nil)
  if valid_591960 != nil:
    section.add "X-Amz-Credential", valid_591960
  var valid_591961 = header.getOrDefault("X-Amz-Security-Token")
  valid_591961 = validateParameter(valid_591961, JString, required = false,
                                 default = nil)
  if valid_591961 != nil:
    section.add "X-Amz-Security-Token", valid_591961
  var valid_591962 = header.getOrDefault("X-Amz-Algorithm")
  valid_591962 = validateParameter(valid_591962, JString, required = false,
                                 default = nil)
  if valid_591962 != nil:
    section.add "X-Amz-Algorithm", valid_591962
  var valid_591963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591963 = validateParameter(valid_591963, JString, required = false,
                                 default = nil)
  if valid_591963 != nil:
    section.add "X-Amz-SignedHeaders", valid_591963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591964: Call_DeleteVoiceChannel_591953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ## 
  let valid = call_591964.validator(path, query, header, formData, body)
  let scheme = call_591964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591964.url(scheme.get, call_591964.host, call_591964.base,
                         call_591964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591964, url, valid)

proc call*(call_591965: Call_DeleteVoiceChannel_591953; applicationId: string): Recallable =
  ## deleteVoiceChannel
  ## Disables the voice channel for an application and deletes any existing settings for the channel.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_591966 = newJObject()
  add(path_591966, "application-id", newJString(applicationId))
  result = call_591965.call(path_591966, nil, nil, nil, nil)

var deleteVoiceChannel* = Call_DeleteVoiceChannel_591953(
    name: "deleteVoiceChannel", meth: HttpMethod.HttpDelete,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/channels/voice",
    validator: validate_DeleteVoiceChannel_591954, base: "/",
    url: url_DeleteVoiceChannel_591955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationDateRangeKpi_591967 = ref object of OpenApiRestCall_590348
proc url_GetApplicationDateRangeKpi_591969(protocol: Scheme; host: string;
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

proc validate_GetApplicationDateRangeKpi_591968(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `kpi-name` field"
  var valid_591970 = path.getOrDefault("kpi-name")
  valid_591970 = validateParameter(valid_591970, JString, required = true,
                                 default = nil)
  if valid_591970 != nil:
    section.add "kpi-name", valid_591970
  var valid_591971 = path.getOrDefault("application-id")
  valid_591971 = validateParameter(valid_591971, JString, required = true,
                                 default = nil)
  if valid_591971 != nil:
    section.add "application-id", valid_591971
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_591972 = query.getOrDefault("end-time")
  valid_591972 = validateParameter(valid_591972, JString, required = false,
                                 default = nil)
  if valid_591972 != nil:
    section.add "end-time", valid_591972
  var valid_591973 = query.getOrDefault("page-size")
  valid_591973 = validateParameter(valid_591973, JString, required = false,
                                 default = nil)
  if valid_591973 != nil:
    section.add "page-size", valid_591973
  var valid_591974 = query.getOrDefault("start-time")
  valid_591974 = validateParameter(valid_591974, JString, required = false,
                                 default = nil)
  if valid_591974 != nil:
    section.add "start-time", valid_591974
  var valid_591975 = query.getOrDefault("next-token")
  valid_591975 = validateParameter(valid_591975, JString, required = false,
                                 default = nil)
  if valid_591975 != nil:
    section.add "next-token", valid_591975
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591983: Call_GetApplicationDateRangeKpi_591967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ## 
  let valid = call_591983.validator(path, query, header, formData, body)
  let scheme = call_591983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591983.url(scheme.get, call_591983.host, call_591983.base,
                         call_591983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591983, url, valid)

proc call*(call_591984: Call_GetApplicationDateRangeKpi_591967; kpiName: string;
          applicationId: string; endTime: string = ""; pageSize: string = "";
          startTime: string = ""; nextToken: string = ""): Recallable =
  ## getApplicationDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  var path_591985 = newJObject()
  var query_591986 = newJObject()
  add(path_591985, "kpi-name", newJString(kpiName))
  add(path_591985, "application-id", newJString(applicationId))
  add(query_591986, "end-time", newJString(endTime))
  add(query_591986, "page-size", newJString(pageSize))
  add(query_591986, "start-time", newJString(startTime))
  add(query_591986, "next-token", newJString(nextToken))
  result = call_591984.call(path_591985, query_591986, nil, nil, nil)

var getApplicationDateRangeKpi* = Call_GetApplicationDateRangeKpi_591967(
    name: "getApplicationDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetApplicationDateRangeKpi_591968, base: "/",
    url: url_GetApplicationDateRangeKpi_591969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplicationSettings_592001 = ref object of OpenApiRestCall_590348
proc url_UpdateApplicationSettings_592003(protocol: Scheme; host: string;
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

proc validate_UpdateApplicationSettings_592002(path: JsonNode; query: JsonNode;
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
  var valid_592004 = path.getOrDefault("application-id")
  valid_592004 = validateParameter(valid_592004, JString, required = true,
                                 default = nil)
  if valid_592004 != nil:
    section.add "application-id", valid_592004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592005 = header.getOrDefault("X-Amz-Signature")
  valid_592005 = validateParameter(valid_592005, JString, required = false,
                                 default = nil)
  if valid_592005 != nil:
    section.add "X-Amz-Signature", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Content-Sha256", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Date")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Date", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Credential")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Credential", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Security-Token")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Security-Token", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Algorithm")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Algorithm", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-SignedHeaders", valid_592011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592013: Call_UpdateApplicationSettings_592001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for an application.
  ## 
  let valid = call_592013.validator(path, query, header, formData, body)
  let scheme = call_592013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592013.url(scheme.get, call_592013.host, call_592013.base,
                         call_592013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592013, url, valid)

proc call*(call_592014: Call_UpdateApplicationSettings_592001;
          applicationId: string; body: JsonNode): Recallable =
  ## updateApplicationSettings
  ## Updates the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592015 = newJObject()
  var body_592016 = newJObject()
  add(path_592015, "application-id", newJString(applicationId))
  if body != nil:
    body_592016 = body
  result = call_592014.call(path_592015, nil, nil, nil, body_592016)

var updateApplicationSettings* = Call_UpdateApplicationSettings_592001(
    name: "updateApplicationSettings", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_UpdateApplicationSettings_592002, base: "/",
    url: url_UpdateApplicationSettings_592003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationSettings_591987 = ref object of OpenApiRestCall_590348
proc url_GetApplicationSettings_591989(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplicationSettings_591988(path: JsonNode; query: JsonNode;
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
  var valid_591990 = path.getOrDefault("application-id")
  valid_591990 = validateParameter(valid_591990, JString, required = true,
                                 default = nil)
  if valid_591990 != nil:
    section.add "application-id", valid_591990
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591998: Call_GetApplicationSettings_591987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the settings for an application.
  ## 
  let valid = call_591998.validator(path, query, header, formData, body)
  let scheme = call_591998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591998.url(scheme.get, call_591998.host, call_591998.base,
                         call_591998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591998, url, valid)

proc call*(call_591999: Call_GetApplicationSettings_591987; applicationId: string): Recallable =
  ## getApplicationSettings
  ## Retrieves information about the settings for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_592000 = newJObject()
  add(path_592000, "application-id", newJString(applicationId))
  result = call_591999.call(path_592000, nil, nil, nil, nil)

var getApplicationSettings* = Call_GetApplicationSettings_591987(
    name: "getApplicationSettings", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/settings",
    validator: validate_GetApplicationSettings_591988, base: "/",
    url: url_GetApplicationSettings_591989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignActivities_592017 = ref object of OpenApiRestCall_590348
proc url_GetCampaignActivities_592019(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignActivities_592018(path: JsonNode; query: JsonNode;
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
  var valid_592020 = path.getOrDefault("application-id")
  valid_592020 = validateParameter(valid_592020, JString, required = true,
                                 default = nil)
  if valid_592020 != nil:
    section.add "application-id", valid_592020
  var valid_592021 = path.getOrDefault("campaign-id")
  valid_592021 = validateParameter(valid_592021, JString, required = true,
                                 default = nil)
  if valid_592021 != nil:
    section.add "campaign-id", valid_592021
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_592022 = query.getOrDefault("page-size")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = nil)
  if valid_592022 != nil:
    section.add "page-size", valid_592022
  var valid_592023 = query.getOrDefault("token")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "token", valid_592023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592024 = header.getOrDefault("X-Amz-Signature")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Signature", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Content-Sha256", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Date")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Date", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-Credential")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-Credential", valid_592027
  var valid_592028 = header.getOrDefault("X-Amz-Security-Token")
  valid_592028 = validateParameter(valid_592028, JString, required = false,
                                 default = nil)
  if valid_592028 != nil:
    section.add "X-Amz-Security-Token", valid_592028
  var valid_592029 = header.getOrDefault("X-Amz-Algorithm")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "X-Amz-Algorithm", valid_592029
  var valid_592030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = nil)
  if valid_592030 != nil:
    section.add "X-Amz-SignedHeaders", valid_592030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592031: Call_GetCampaignActivities_592017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the activity performed by a campaign.
  ## 
  let valid = call_592031.validator(path, query, header, formData, body)
  let scheme = call_592031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592031.url(scheme.get, call_592031.host, call_592031.base,
                         call_592031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592031, url, valid)

proc call*(call_592032: Call_GetCampaignActivities_592017; applicationId: string;
          campaignId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaignActivities
  ## Retrieves information about the activity performed by a campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_592033 = newJObject()
  var query_592034 = newJObject()
  add(path_592033, "application-id", newJString(applicationId))
  add(query_592034, "page-size", newJString(pageSize))
  add(path_592033, "campaign-id", newJString(campaignId))
  add(query_592034, "token", newJString(token))
  result = call_592032.call(path_592033, query_592034, nil, nil, nil)

var getCampaignActivities* = Call_GetCampaignActivities_592017(
    name: "getCampaignActivities", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities",
    validator: validate_GetCampaignActivities_592018, base: "/",
    url: url_GetCampaignActivities_592019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignDateRangeKpi_592035 = ref object of OpenApiRestCall_590348
proc url_GetCampaignDateRangeKpi_592037(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignDateRangeKpi_592036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   kpi-name: JString (required)
  ##           : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   application-id: JString (required)
  ##                 : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaign-id: JString (required)
  ##              : The unique identifier for the campaign.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `kpi-name` field"
  var valid_592038 = path.getOrDefault("kpi-name")
  valid_592038 = validateParameter(valid_592038, JString, required = true,
                                 default = nil)
  if valid_592038 != nil:
    section.add "kpi-name", valid_592038
  var valid_592039 = path.getOrDefault("application-id")
  valid_592039 = validateParameter(valid_592039, JString, required = true,
                                 default = nil)
  if valid_592039 != nil:
    section.add "application-id", valid_592039
  var valid_592040 = path.getOrDefault("campaign-id")
  valid_592040 = validateParameter(valid_592040, JString, required = true,
                                 default = nil)
  if valid_592040 != nil:
    section.add "campaign-id", valid_592040
  result.add "path", section
  ## parameters in `query` object:
  ##   end-time: JString
  ##           : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   start-time: JString
  ##             : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   next-token: JString
  ##             : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_592041 = query.getOrDefault("end-time")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "end-time", valid_592041
  var valid_592042 = query.getOrDefault("page-size")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "page-size", valid_592042
  var valid_592043 = query.getOrDefault("start-time")
  valid_592043 = validateParameter(valid_592043, JString, required = false,
                                 default = nil)
  if valid_592043 != nil:
    section.add "start-time", valid_592043
  var valid_592044 = query.getOrDefault("next-token")
  valid_592044 = validateParameter(valid_592044, JString, required = false,
                                 default = nil)
  if valid_592044 != nil:
    section.add "next-token", valid_592044
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592045 = header.getOrDefault("X-Amz-Signature")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Signature", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-Content-Sha256", valid_592046
  var valid_592047 = header.getOrDefault("X-Amz-Date")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "X-Amz-Date", valid_592047
  var valid_592048 = header.getOrDefault("X-Amz-Credential")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Credential", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Security-Token")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Security-Token", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-Algorithm")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-Algorithm", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-SignedHeaders", valid_592051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592052: Call_GetCampaignDateRangeKpi_592035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ## 
  let valid = call_592052.validator(path, query, header, formData, body)
  let scheme = call_592052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592052.url(scheme.get, call_592052.host, call_592052.base,
                         call_592052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592052, url, valid)

proc call*(call_592053: Call_GetCampaignDateRangeKpi_592035; kpiName: string;
          applicationId: string; campaignId: string; endTime: string = "";
          pageSize: string = ""; startTime: string = ""; nextToken: string = ""): Recallable =
  ## getCampaignDateRangeKpi
  ## Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
  ##   kpiName: string (required)
  ##          : The name of the metric, also referred to as a <i>key performance indicator (KPI)</i>, to retrieve data for. This value describes the associated metric and consists of two or more terms, which are comprised of lowercase alphanumeric characters, separated by a hyphen. Examples are email-open-rate and successful-delivery-rate. For a list of valid values, see the <a href="developerguide.html">Amazon Pinpoint Developer Guide</a>.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   endTime: string
  ##          : The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-19T00:00:00Z for July 19, 2019 and 2019-07-19T20:00:00Z for 8:00 PM July 19, 2019.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   startTime: string
  ##            : The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format, for example: 2019-07-15T00:00:00Z for July 15, 2019 and 2019-07-15T16:00:00Z for 4:00 PM July 15, 2019.
  ##   nextToken: string
  ##            : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  var path_592054 = newJObject()
  var query_592055 = newJObject()
  add(path_592054, "kpi-name", newJString(kpiName))
  add(path_592054, "application-id", newJString(applicationId))
  add(query_592055, "end-time", newJString(endTime))
  add(query_592055, "page-size", newJString(pageSize))
  add(path_592054, "campaign-id", newJString(campaignId))
  add(query_592055, "start-time", newJString(startTime))
  add(query_592055, "next-token", newJString(nextToken))
  result = call_592053.call(path_592054, query_592055, nil, nil, nil)

var getCampaignDateRangeKpi* = Call_GetCampaignDateRangeKpi_592035(
    name: "getCampaignDateRangeKpi", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}",
    validator: validate_GetCampaignDateRangeKpi_592036, base: "/",
    url: url_GetCampaignDateRangeKpi_592037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersion_592056 = ref object of OpenApiRestCall_590348
proc url_GetCampaignVersion_592058(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersion_592057(path: JsonNode; query: JsonNode;
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
  var valid_592059 = path.getOrDefault("version")
  valid_592059 = validateParameter(valid_592059, JString, required = true,
                                 default = nil)
  if valid_592059 != nil:
    section.add "version", valid_592059
  var valid_592060 = path.getOrDefault("application-id")
  valid_592060 = validateParameter(valid_592060, JString, required = true,
                                 default = nil)
  if valid_592060 != nil:
    section.add "application-id", valid_592060
  var valid_592061 = path.getOrDefault("campaign-id")
  valid_592061 = validateParameter(valid_592061, JString, required = true,
                                 default = nil)
  if valid_592061 != nil:
    section.add "campaign-id", valid_592061
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592062 = header.getOrDefault("X-Amz-Signature")
  valid_592062 = validateParameter(valid_592062, JString, required = false,
                                 default = nil)
  if valid_592062 != nil:
    section.add "X-Amz-Signature", valid_592062
  var valid_592063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "X-Amz-Content-Sha256", valid_592063
  var valid_592064 = header.getOrDefault("X-Amz-Date")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-Date", valid_592064
  var valid_592065 = header.getOrDefault("X-Amz-Credential")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-Credential", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Security-Token")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Security-Token", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Algorithm")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Algorithm", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-SignedHeaders", valid_592068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592069: Call_GetCampaignVersion_592056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ## 
  let valid = call_592069.validator(path, query, header, formData, body)
  let scheme = call_592069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592069.url(scheme.get, call_592069.host, call_592069.base,
                         call_592069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592069, url, valid)

proc call*(call_592070: Call_GetCampaignVersion_592056; version: string;
          applicationId: string; campaignId: string): Recallable =
  ## getCampaignVersion
  ## Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  var path_592071 = newJObject()
  add(path_592071, "version", newJString(version))
  add(path_592071, "application-id", newJString(applicationId))
  add(path_592071, "campaign-id", newJString(campaignId))
  result = call_592070.call(path_592071, nil, nil, nil, nil)

var getCampaignVersion* = Call_GetCampaignVersion_592056(
    name: "getCampaignVersion", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}",
    validator: validate_GetCampaignVersion_592057, base: "/",
    url: url_GetCampaignVersion_592058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCampaignVersions_592072 = ref object of OpenApiRestCall_590348
proc url_GetCampaignVersions_592074(protocol: Scheme; host: string; base: string;
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

proc validate_GetCampaignVersions_592073(path: JsonNode; query: JsonNode;
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
  var valid_592075 = path.getOrDefault("application-id")
  valid_592075 = validateParameter(valid_592075, JString, required = true,
                                 default = nil)
  if valid_592075 != nil:
    section.add "application-id", valid_592075
  var valid_592076 = path.getOrDefault("campaign-id")
  valid_592076 = validateParameter(valid_592076, JString, required = true,
                                 default = nil)
  if valid_592076 != nil:
    section.add "campaign-id", valid_592076
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_592077 = query.getOrDefault("page-size")
  valid_592077 = validateParameter(valid_592077, JString, required = false,
                                 default = nil)
  if valid_592077 != nil:
    section.add "page-size", valid_592077
  var valid_592078 = query.getOrDefault("token")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "token", valid_592078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592079 = header.getOrDefault("X-Amz-Signature")
  valid_592079 = validateParameter(valid_592079, JString, required = false,
                                 default = nil)
  if valid_592079 != nil:
    section.add "X-Amz-Signature", valid_592079
  var valid_592080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "X-Amz-Content-Sha256", valid_592080
  var valid_592081 = header.getOrDefault("X-Amz-Date")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Date", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Credential")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Credential", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Security-Token")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Security-Token", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Algorithm")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Algorithm", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-SignedHeaders", valid_592085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592086: Call_GetCampaignVersions_592072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ## 
  let valid = call_592086.validator(path, query, header, formData, body)
  let scheme = call_592086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592086.url(scheme.get, call_592086.host, call_592086.base,
                         call_592086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592086, url, valid)

proc call*(call_592087: Call_GetCampaignVersions_592072; applicationId: string;
          campaignId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getCampaignVersions
  ## Retrieves information about the status, configuration, and other settings for all versions of a specific campaign.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   campaignId: string (required)
  ##             : The unique identifier for the campaign.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_592088 = newJObject()
  var query_592089 = newJObject()
  add(path_592088, "application-id", newJString(applicationId))
  add(query_592089, "page-size", newJString(pageSize))
  add(path_592088, "campaign-id", newJString(campaignId))
  add(query_592089, "token", newJString(token))
  result = call_592087.call(path_592088, query_592089, nil, nil, nil)

var getCampaignVersions* = Call_GetCampaignVersions_592072(
    name: "getCampaignVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions",
    validator: validate_GetCampaignVersions_592073, base: "/",
    url: url_GetCampaignVersions_592074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChannels_592090 = ref object of OpenApiRestCall_590348
proc url_GetChannels_592092(protocol: Scheme; host: string; base: string;
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

proc validate_GetChannels_592091(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592093 = path.getOrDefault("application-id")
  valid_592093 = validateParameter(valid_592093, JString, required = true,
                                 default = nil)
  if valid_592093 != nil:
    section.add "application-id", valid_592093
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592094 = header.getOrDefault("X-Amz-Signature")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-Signature", valid_592094
  var valid_592095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592095 = validateParameter(valid_592095, JString, required = false,
                                 default = nil)
  if valid_592095 != nil:
    section.add "X-Amz-Content-Sha256", valid_592095
  var valid_592096 = header.getOrDefault("X-Amz-Date")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "X-Amz-Date", valid_592096
  var valid_592097 = header.getOrDefault("X-Amz-Credential")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "X-Amz-Credential", valid_592097
  var valid_592098 = header.getOrDefault("X-Amz-Security-Token")
  valid_592098 = validateParameter(valid_592098, JString, required = false,
                                 default = nil)
  if valid_592098 != nil:
    section.add "X-Amz-Security-Token", valid_592098
  var valid_592099 = header.getOrDefault("X-Amz-Algorithm")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "X-Amz-Algorithm", valid_592099
  var valid_592100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "X-Amz-SignedHeaders", valid_592100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592101: Call_GetChannels_592090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the history and status of each channel for an application.
  ## 
  let valid = call_592101.validator(path, query, header, formData, body)
  let scheme = call_592101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592101.url(scheme.get, call_592101.host, call_592101.base,
                         call_592101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592101, url, valid)

proc call*(call_592102: Call_GetChannels_592090; applicationId: string): Recallable =
  ## getChannels
  ## Retrieves information about the history and status of each channel for an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_592103 = newJObject()
  add(path_592103, "application-id", newJString(applicationId))
  result = call_592102.call(path_592103, nil, nil, nil, nil)

var getChannels* = Call_GetChannels_592090(name: "getChannels",
                                        meth: HttpMethod.HttpGet,
                                        host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/channels",
                                        validator: validate_GetChannels_592091,
                                        base: "/", url: url_GetChannels_592092,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportJob_592104 = ref object of OpenApiRestCall_590348
proc url_GetExportJob_592106(protocol: Scheme; host: string; base: string;
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

proc validate_GetExportJob_592105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592107 = path.getOrDefault("job-id")
  valid_592107 = validateParameter(valid_592107, JString, required = true,
                                 default = nil)
  if valid_592107 != nil:
    section.add "job-id", valid_592107
  var valid_592108 = path.getOrDefault("application-id")
  valid_592108 = validateParameter(valid_592108, JString, required = true,
                                 default = nil)
  if valid_592108 != nil:
    section.add "application-id", valid_592108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592109 = header.getOrDefault("X-Amz-Signature")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-Signature", valid_592109
  var valid_592110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592110 = validateParameter(valid_592110, JString, required = false,
                                 default = nil)
  if valid_592110 != nil:
    section.add "X-Amz-Content-Sha256", valid_592110
  var valid_592111 = header.getOrDefault("X-Amz-Date")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-Date", valid_592111
  var valid_592112 = header.getOrDefault("X-Amz-Credential")
  valid_592112 = validateParameter(valid_592112, JString, required = false,
                                 default = nil)
  if valid_592112 != nil:
    section.add "X-Amz-Credential", valid_592112
  var valid_592113 = header.getOrDefault("X-Amz-Security-Token")
  valid_592113 = validateParameter(valid_592113, JString, required = false,
                                 default = nil)
  if valid_592113 != nil:
    section.add "X-Amz-Security-Token", valid_592113
  var valid_592114 = header.getOrDefault("X-Amz-Algorithm")
  valid_592114 = validateParameter(valid_592114, JString, required = false,
                                 default = nil)
  if valid_592114 != nil:
    section.add "X-Amz-Algorithm", valid_592114
  var valid_592115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592115 = validateParameter(valid_592115, JString, required = false,
                                 default = nil)
  if valid_592115 != nil:
    section.add "X-Amz-SignedHeaders", valid_592115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592116: Call_GetExportJob_592104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific export job for an application.
  ## 
  let valid = call_592116.validator(path, query, header, formData, body)
  let scheme = call_592116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592116.url(scheme.get, call_592116.host, call_592116.base,
                         call_592116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592116, url, valid)

proc call*(call_592117: Call_GetExportJob_592104; jobId: string;
          applicationId: string): Recallable =
  ## getExportJob
  ## Retrieves information about the status and settings of a specific export job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_592118 = newJObject()
  add(path_592118, "job-id", newJString(jobId))
  add(path_592118, "application-id", newJString(applicationId))
  result = call_592117.call(path_592118, nil, nil, nil, nil)

var getExportJob* = Call_GetExportJob_592104(name: "getExportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/export/{job-id}",
    validator: validate_GetExportJob_592105, base: "/", url: url_GetExportJob_592106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImportJob_592119 = ref object of OpenApiRestCall_590348
proc url_GetImportJob_592121(protocol: Scheme; host: string; base: string;
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

proc validate_GetImportJob_592120(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592122 = path.getOrDefault("job-id")
  valid_592122 = validateParameter(valid_592122, JString, required = true,
                                 default = nil)
  if valid_592122 != nil:
    section.add "job-id", valid_592122
  var valid_592123 = path.getOrDefault("application-id")
  valid_592123 = validateParameter(valid_592123, JString, required = true,
                                 default = nil)
  if valid_592123 != nil:
    section.add "application-id", valid_592123
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592124 = header.getOrDefault("X-Amz-Signature")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-Signature", valid_592124
  var valid_592125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Content-Sha256", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-Date")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-Date", valid_592126
  var valid_592127 = header.getOrDefault("X-Amz-Credential")
  valid_592127 = validateParameter(valid_592127, JString, required = false,
                                 default = nil)
  if valid_592127 != nil:
    section.add "X-Amz-Credential", valid_592127
  var valid_592128 = header.getOrDefault("X-Amz-Security-Token")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "X-Amz-Security-Token", valid_592128
  var valid_592129 = header.getOrDefault("X-Amz-Algorithm")
  valid_592129 = validateParameter(valid_592129, JString, required = false,
                                 default = nil)
  if valid_592129 != nil:
    section.add "X-Amz-Algorithm", valid_592129
  var valid_592130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592130 = validateParameter(valid_592130, JString, required = false,
                                 default = nil)
  if valid_592130 != nil:
    section.add "X-Amz-SignedHeaders", valid_592130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592131: Call_GetImportJob_592119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of a specific import job for an application.
  ## 
  let valid = call_592131.validator(path, query, header, formData, body)
  let scheme = call_592131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592131.url(scheme.get, call_592131.host, call_592131.base,
                         call_592131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592131, url, valid)

proc call*(call_592132: Call_GetImportJob_592119; jobId: string;
          applicationId: string): Recallable =
  ## getImportJob
  ## Retrieves information about the status and settings of a specific import job for an application.
  ##   jobId: string (required)
  ##        : The unique identifier for the job.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  var path_592133 = newJObject()
  add(path_592133, "job-id", newJString(jobId))
  add(path_592133, "application-id", newJString(applicationId))
  result = call_592132.call(path_592133, nil, nil, nil, nil)

var getImportJob* = Call_GetImportJob_592119(name: "getImportJob",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/jobs/import/{job-id}",
    validator: validate_GetImportJob_592120, base: "/", url: url_GetImportJob_592121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentExportJobs_592134 = ref object of OpenApiRestCall_590348
proc url_GetSegmentExportJobs_592136(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentExportJobs_592135(path: JsonNode; query: JsonNode;
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
  var valid_592137 = path.getOrDefault("application-id")
  valid_592137 = validateParameter(valid_592137, JString, required = true,
                                 default = nil)
  if valid_592137 != nil:
    section.add "application-id", valid_592137
  var valid_592138 = path.getOrDefault("segment-id")
  valid_592138 = validateParameter(valid_592138, JString, required = true,
                                 default = nil)
  if valid_592138 != nil:
    section.add "segment-id", valid_592138
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_592139 = query.getOrDefault("page-size")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "page-size", valid_592139
  var valid_592140 = query.getOrDefault("token")
  valid_592140 = validateParameter(valid_592140, JString, required = false,
                                 default = nil)
  if valid_592140 != nil:
    section.add "token", valid_592140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592141 = header.getOrDefault("X-Amz-Signature")
  valid_592141 = validateParameter(valid_592141, JString, required = false,
                                 default = nil)
  if valid_592141 != nil:
    section.add "X-Amz-Signature", valid_592141
  var valid_592142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-Content-Sha256", valid_592142
  var valid_592143 = header.getOrDefault("X-Amz-Date")
  valid_592143 = validateParameter(valid_592143, JString, required = false,
                                 default = nil)
  if valid_592143 != nil:
    section.add "X-Amz-Date", valid_592143
  var valid_592144 = header.getOrDefault("X-Amz-Credential")
  valid_592144 = validateParameter(valid_592144, JString, required = false,
                                 default = nil)
  if valid_592144 != nil:
    section.add "X-Amz-Credential", valid_592144
  var valid_592145 = header.getOrDefault("X-Amz-Security-Token")
  valid_592145 = validateParameter(valid_592145, JString, required = false,
                                 default = nil)
  if valid_592145 != nil:
    section.add "X-Amz-Security-Token", valid_592145
  var valid_592146 = header.getOrDefault("X-Amz-Algorithm")
  valid_592146 = validateParameter(valid_592146, JString, required = false,
                                 default = nil)
  if valid_592146 != nil:
    section.add "X-Amz-Algorithm", valid_592146
  var valid_592147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592147 = validateParameter(valid_592147, JString, required = false,
                                 default = nil)
  if valid_592147 != nil:
    section.add "X-Amz-SignedHeaders", valid_592147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592148: Call_GetSegmentExportJobs_592134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ## 
  let valid = call_592148.validator(path, query, header, formData, body)
  let scheme = call_592148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592148.url(scheme.get, call_592148.host, call_592148.base,
                         call_592148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592148, url, valid)

proc call*(call_592149: Call_GetSegmentExportJobs_592134; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentExportJobs
  ## Retrieves information about the status and settings of the export jobs for a segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_592150 = newJObject()
  var query_592151 = newJObject()
  add(path_592150, "application-id", newJString(applicationId))
  add(path_592150, "segment-id", newJString(segmentId))
  add(query_592151, "page-size", newJString(pageSize))
  add(query_592151, "token", newJString(token))
  result = call_592149.call(path_592150, query_592151, nil, nil, nil)

var getSegmentExportJobs* = Call_GetSegmentExportJobs_592134(
    name: "getSegmentExportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export",
    validator: validate_GetSegmentExportJobs_592135, base: "/",
    url: url_GetSegmentExportJobs_592136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentImportJobs_592152 = ref object of OpenApiRestCall_590348
proc url_GetSegmentImportJobs_592154(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentImportJobs_592153(path: JsonNode; query: JsonNode;
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
  var valid_592155 = path.getOrDefault("application-id")
  valid_592155 = validateParameter(valid_592155, JString, required = true,
                                 default = nil)
  if valid_592155 != nil:
    section.add "application-id", valid_592155
  var valid_592156 = path.getOrDefault("segment-id")
  valid_592156 = validateParameter(valid_592156, JString, required = true,
                                 default = nil)
  if valid_592156 != nil:
    section.add "segment-id", valid_592156
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_592157 = query.getOrDefault("page-size")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "page-size", valid_592157
  var valid_592158 = query.getOrDefault("token")
  valid_592158 = validateParameter(valid_592158, JString, required = false,
                                 default = nil)
  if valid_592158 != nil:
    section.add "token", valid_592158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592159 = header.getOrDefault("X-Amz-Signature")
  valid_592159 = validateParameter(valid_592159, JString, required = false,
                                 default = nil)
  if valid_592159 != nil:
    section.add "X-Amz-Signature", valid_592159
  var valid_592160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592160 = validateParameter(valid_592160, JString, required = false,
                                 default = nil)
  if valid_592160 != nil:
    section.add "X-Amz-Content-Sha256", valid_592160
  var valid_592161 = header.getOrDefault("X-Amz-Date")
  valid_592161 = validateParameter(valid_592161, JString, required = false,
                                 default = nil)
  if valid_592161 != nil:
    section.add "X-Amz-Date", valid_592161
  var valid_592162 = header.getOrDefault("X-Amz-Credential")
  valid_592162 = validateParameter(valid_592162, JString, required = false,
                                 default = nil)
  if valid_592162 != nil:
    section.add "X-Amz-Credential", valid_592162
  var valid_592163 = header.getOrDefault("X-Amz-Security-Token")
  valid_592163 = validateParameter(valid_592163, JString, required = false,
                                 default = nil)
  if valid_592163 != nil:
    section.add "X-Amz-Security-Token", valid_592163
  var valid_592164 = header.getOrDefault("X-Amz-Algorithm")
  valid_592164 = validateParameter(valid_592164, JString, required = false,
                                 default = nil)
  if valid_592164 != nil:
    section.add "X-Amz-Algorithm", valid_592164
  var valid_592165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592165 = validateParameter(valid_592165, JString, required = false,
                                 default = nil)
  if valid_592165 != nil:
    section.add "X-Amz-SignedHeaders", valid_592165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592166: Call_GetSegmentImportJobs_592152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ## 
  let valid = call_592166.validator(path, query, header, formData, body)
  let scheme = call_592166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592166.url(scheme.get, call_592166.host, call_592166.base,
                         call_592166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592166, url, valid)

proc call*(call_592167: Call_GetSegmentImportJobs_592152; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentImportJobs
  ## Retrieves information about the status and settings of the import jobs for a segment.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_592168 = newJObject()
  var query_592169 = newJObject()
  add(path_592168, "application-id", newJString(applicationId))
  add(path_592168, "segment-id", newJString(segmentId))
  add(query_592169, "page-size", newJString(pageSize))
  add(query_592169, "token", newJString(token))
  result = call_592167.call(path_592168, query_592169, nil, nil, nil)

var getSegmentImportJobs* = Call_GetSegmentImportJobs_592152(
    name: "getSegmentImportJobs", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import",
    validator: validate_GetSegmentImportJobs_592153, base: "/",
    url: url_GetSegmentImportJobs_592154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersion_592170 = ref object of OpenApiRestCall_590348
proc url_GetSegmentVersion_592172(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersion_592171(path: JsonNode; query: JsonNode;
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
  var valid_592173 = path.getOrDefault("version")
  valid_592173 = validateParameter(valid_592173, JString, required = true,
                                 default = nil)
  if valid_592173 != nil:
    section.add "version", valid_592173
  var valid_592174 = path.getOrDefault("application-id")
  valid_592174 = validateParameter(valid_592174, JString, required = true,
                                 default = nil)
  if valid_592174 != nil:
    section.add "application-id", valid_592174
  var valid_592175 = path.getOrDefault("segment-id")
  valid_592175 = validateParameter(valid_592175, JString, required = true,
                                 default = nil)
  if valid_592175 != nil:
    section.add "segment-id", valid_592175
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592176 = header.getOrDefault("X-Amz-Signature")
  valid_592176 = validateParameter(valid_592176, JString, required = false,
                                 default = nil)
  if valid_592176 != nil:
    section.add "X-Amz-Signature", valid_592176
  var valid_592177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592177 = validateParameter(valid_592177, JString, required = false,
                                 default = nil)
  if valid_592177 != nil:
    section.add "X-Amz-Content-Sha256", valid_592177
  var valid_592178 = header.getOrDefault("X-Amz-Date")
  valid_592178 = validateParameter(valid_592178, JString, required = false,
                                 default = nil)
  if valid_592178 != nil:
    section.add "X-Amz-Date", valid_592178
  var valid_592179 = header.getOrDefault("X-Amz-Credential")
  valid_592179 = validateParameter(valid_592179, JString, required = false,
                                 default = nil)
  if valid_592179 != nil:
    section.add "X-Amz-Credential", valid_592179
  var valid_592180 = header.getOrDefault("X-Amz-Security-Token")
  valid_592180 = validateParameter(valid_592180, JString, required = false,
                                 default = nil)
  if valid_592180 != nil:
    section.add "X-Amz-Security-Token", valid_592180
  var valid_592181 = header.getOrDefault("X-Amz-Algorithm")
  valid_592181 = validateParameter(valid_592181, JString, required = false,
                                 default = nil)
  if valid_592181 != nil:
    section.add "X-Amz-Algorithm", valid_592181
  var valid_592182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592182 = validateParameter(valid_592182, JString, required = false,
                                 default = nil)
  if valid_592182 != nil:
    section.add "X-Amz-SignedHeaders", valid_592182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592183: Call_GetSegmentVersion_592170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ## 
  let valid = call_592183.validator(path, query, header, formData, body)
  let scheme = call_592183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592183.url(scheme.get, call_592183.host, call_592183.base,
                         call_592183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592183, url, valid)

proc call*(call_592184: Call_GetSegmentVersion_592170; version: string;
          applicationId: string; segmentId: string): Recallable =
  ## getSegmentVersion
  ## Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
  ##   version: string (required)
  ##          : The unique version number (Version property) for the campaign version.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  var path_592185 = newJObject()
  add(path_592185, "version", newJString(version))
  add(path_592185, "application-id", newJString(applicationId))
  add(path_592185, "segment-id", newJString(segmentId))
  result = call_592184.call(path_592185, nil, nil, nil, nil)

var getSegmentVersion* = Call_GetSegmentVersion_592170(name: "getSegmentVersion",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}",
    validator: validate_GetSegmentVersion_592171, base: "/",
    url: url_GetSegmentVersion_592172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSegmentVersions_592186 = ref object of OpenApiRestCall_590348
proc url_GetSegmentVersions_592188(protocol: Scheme; host: string; base: string;
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

proc validate_GetSegmentVersions_592187(path: JsonNode; query: JsonNode;
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
  var valid_592189 = path.getOrDefault("application-id")
  valid_592189 = validateParameter(valid_592189, JString, required = true,
                                 default = nil)
  if valid_592189 != nil:
    section.add "application-id", valid_592189
  var valid_592190 = path.getOrDefault("segment-id")
  valid_592190 = validateParameter(valid_592190, JString, required = true,
                                 default = nil)
  if valid_592190 != nil:
    section.add "segment-id", valid_592190
  result.add "path", section
  ## parameters in `query` object:
  ##   page-size: JString
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: JString
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  section = newJObject()
  var valid_592191 = query.getOrDefault("page-size")
  valid_592191 = validateParameter(valid_592191, JString, required = false,
                                 default = nil)
  if valid_592191 != nil:
    section.add "page-size", valid_592191
  var valid_592192 = query.getOrDefault("token")
  valid_592192 = validateParameter(valid_592192, JString, required = false,
                                 default = nil)
  if valid_592192 != nil:
    section.add "token", valid_592192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592193 = header.getOrDefault("X-Amz-Signature")
  valid_592193 = validateParameter(valid_592193, JString, required = false,
                                 default = nil)
  if valid_592193 != nil:
    section.add "X-Amz-Signature", valid_592193
  var valid_592194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592194 = validateParameter(valid_592194, JString, required = false,
                                 default = nil)
  if valid_592194 != nil:
    section.add "X-Amz-Content-Sha256", valid_592194
  var valid_592195 = header.getOrDefault("X-Amz-Date")
  valid_592195 = validateParameter(valid_592195, JString, required = false,
                                 default = nil)
  if valid_592195 != nil:
    section.add "X-Amz-Date", valid_592195
  var valid_592196 = header.getOrDefault("X-Amz-Credential")
  valid_592196 = validateParameter(valid_592196, JString, required = false,
                                 default = nil)
  if valid_592196 != nil:
    section.add "X-Amz-Credential", valid_592196
  var valid_592197 = header.getOrDefault("X-Amz-Security-Token")
  valid_592197 = validateParameter(valid_592197, JString, required = false,
                                 default = nil)
  if valid_592197 != nil:
    section.add "X-Amz-Security-Token", valid_592197
  var valid_592198 = header.getOrDefault("X-Amz-Algorithm")
  valid_592198 = validateParameter(valid_592198, JString, required = false,
                                 default = nil)
  if valid_592198 != nil:
    section.add "X-Amz-Algorithm", valid_592198
  var valid_592199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592199 = validateParameter(valid_592199, JString, required = false,
                                 default = nil)
  if valid_592199 != nil:
    section.add "X-Amz-SignedHeaders", valid_592199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592200: Call_GetSegmentVersions_592186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ## 
  let valid = call_592200.validator(path, query, header, formData, body)
  let scheme = call_592200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592200.url(scheme.get, call_592200.host, call_592200.base,
                         call_592200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592200, url, valid)

proc call*(call_592201: Call_GetSegmentVersions_592186; applicationId: string;
          segmentId: string; pageSize: string = ""; token: string = ""): Recallable =
  ## getSegmentVersions
  ## Retrieves information about the configuration, dimension, and other settings for all versions of a specific segment that's associated with an application.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   segmentId: string (required)
  ##            : The unique identifier for the segment.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   token: string
  ##        : The NextToken string that specifies which page of results to return in a paginated response.
  var path_592202 = newJObject()
  var query_592203 = newJObject()
  add(path_592202, "application-id", newJString(applicationId))
  add(path_592202, "segment-id", newJString(segmentId))
  add(query_592203, "page-size", newJString(pageSize))
  add(query_592203, "token", newJString(token))
  result = call_592201.call(path_592202, query_592203, nil, nil, nil)

var getSegmentVersions* = Call_GetSegmentVersions_592186(
    name: "getSegmentVersions", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/segments/{segment-id}/versions",
    validator: validate_GetSegmentVersions_592187, base: "/",
    url: url_GetSegmentVersions_592188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592218 = ref object of OpenApiRestCall_590348
proc url_TagResource_592220(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_592219(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_592221 = path.getOrDefault("resource-arn")
  valid_592221 = validateParameter(valid_592221, JString, required = true,
                                 default = nil)
  if valid_592221 != nil:
    section.add "resource-arn", valid_592221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592222 = header.getOrDefault("X-Amz-Signature")
  valid_592222 = validateParameter(valid_592222, JString, required = false,
                                 default = nil)
  if valid_592222 != nil:
    section.add "X-Amz-Signature", valid_592222
  var valid_592223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592223 = validateParameter(valid_592223, JString, required = false,
                                 default = nil)
  if valid_592223 != nil:
    section.add "X-Amz-Content-Sha256", valid_592223
  var valid_592224 = header.getOrDefault("X-Amz-Date")
  valid_592224 = validateParameter(valid_592224, JString, required = false,
                                 default = nil)
  if valid_592224 != nil:
    section.add "X-Amz-Date", valid_592224
  var valid_592225 = header.getOrDefault("X-Amz-Credential")
  valid_592225 = validateParameter(valid_592225, JString, required = false,
                                 default = nil)
  if valid_592225 != nil:
    section.add "X-Amz-Credential", valid_592225
  var valid_592226 = header.getOrDefault("X-Amz-Security-Token")
  valid_592226 = validateParameter(valid_592226, JString, required = false,
                                 default = nil)
  if valid_592226 != nil:
    section.add "X-Amz-Security-Token", valid_592226
  var valid_592227 = header.getOrDefault("X-Amz-Algorithm")
  valid_592227 = validateParameter(valid_592227, JString, required = false,
                                 default = nil)
  if valid_592227 != nil:
    section.add "X-Amz-Algorithm", valid_592227
  var valid_592228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592228 = validateParameter(valid_592228, JString, required = false,
                                 default = nil)
  if valid_592228 != nil:
    section.add "X-Amz-SignedHeaders", valid_592228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592230: Call_TagResource_592218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
  ## 
  let valid = call_592230.validator(path, query, header, formData, body)
  let scheme = call_592230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592230.url(scheme.get, call_592230.host, call_592230.base,
                         call_592230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592230, url, valid)

proc call*(call_592231: Call_TagResource_592218; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  ##   body: JObject (required)
  var path_592232 = newJObject()
  var body_592233 = newJObject()
  add(path_592232, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_592233 = body
  result = call_592231.call(path_592232, nil, nil, nil, body_592233)

var tagResource* = Call_TagResource_592218(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "pinpoint.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_TagResource_592219,
                                        base: "/", url: url_TagResource_592220,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592204 = ref object of OpenApiRestCall_590348
proc url_ListTagsForResource_592206(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_592205(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_592207 = path.getOrDefault("resource-arn")
  valid_592207 = validateParameter(valid_592207, JString, required = true,
                                 default = nil)
  if valid_592207 != nil:
    section.add "resource-arn", valid_592207
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592208 = header.getOrDefault("X-Amz-Signature")
  valid_592208 = validateParameter(valid_592208, JString, required = false,
                                 default = nil)
  if valid_592208 != nil:
    section.add "X-Amz-Signature", valid_592208
  var valid_592209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592209 = validateParameter(valid_592209, JString, required = false,
                                 default = nil)
  if valid_592209 != nil:
    section.add "X-Amz-Content-Sha256", valid_592209
  var valid_592210 = header.getOrDefault("X-Amz-Date")
  valid_592210 = validateParameter(valid_592210, JString, required = false,
                                 default = nil)
  if valid_592210 != nil:
    section.add "X-Amz-Date", valid_592210
  var valid_592211 = header.getOrDefault("X-Amz-Credential")
  valid_592211 = validateParameter(valid_592211, JString, required = false,
                                 default = nil)
  if valid_592211 != nil:
    section.add "X-Amz-Credential", valid_592211
  var valid_592212 = header.getOrDefault("X-Amz-Security-Token")
  valid_592212 = validateParameter(valid_592212, JString, required = false,
                                 default = nil)
  if valid_592212 != nil:
    section.add "X-Amz-Security-Token", valid_592212
  var valid_592213 = header.getOrDefault("X-Amz-Algorithm")
  valid_592213 = validateParameter(valid_592213, JString, required = false,
                                 default = nil)
  if valid_592213 != nil:
    section.add "X-Amz-Algorithm", valid_592213
  var valid_592214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592214 = validateParameter(valid_592214, JString, required = false,
                                 default = nil)
  if valid_592214 != nil:
    section.add "X-Amz-SignedHeaders", valid_592214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592215: Call_ListTagsForResource_592204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
  ## 
  let valid = call_592215.validator(path, query, header, formData, body)
  let scheme = call_592215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592215.url(scheme.get, call_592215.host, call_592215.base,
                         call_592215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592215, url, valid)

proc call*(call_592216: Call_ListTagsForResource_592204; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  var path_592217 = newJObject()
  add(path_592217, "resource-arn", newJString(resourceArn))
  result = call_592216.call(path_592217, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_592204(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "pinpoint.amazonaws.com", route: "/v1/tags/{resource-arn}",
    validator: validate_ListTagsForResource_592205, base: "/",
    url: url_ListTagsForResource_592206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_592234 = ref object of OpenApiRestCall_590348
proc url_ListTemplates_592236(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTemplates_592235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##            : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   template-type: JString
  ##                : The type of message template to include in the results. Valid values are: EMAIL, SMS, and PUSH. To include all types of templates in the results, don't include this parameter in your request.
  ##   next-token: JString
  ##             : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  section = newJObject()
  var valid_592237 = query.getOrDefault("prefix")
  valid_592237 = validateParameter(valid_592237, JString, required = false,
                                 default = nil)
  if valid_592237 != nil:
    section.add "prefix", valid_592237
  var valid_592238 = query.getOrDefault("page-size")
  valid_592238 = validateParameter(valid_592238, JString, required = false,
                                 default = nil)
  if valid_592238 != nil:
    section.add "page-size", valid_592238
  var valid_592239 = query.getOrDefault("template-type")
  valid_592239 = validateParameter(valid_592239, JString, required = false,
                                 default = nil)
  if valid_592239 != nil:
    section.add "template-type", valid_592239
  var valid_592240 = query.getOrDefault("next-token")
  valid_592240 = validateParameter(valid_592240, JString, required = false,
                                 default = nil)
  if valid_592240 != nil:
    section.add "next-token", valid_592240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592241 = header.getOrDefault("X-Amz-Signature")
  valid_592241 = validateParameter(valid_592241, JString, required = false,
                                 default = nil)
  if valid_592241 != nil:
    section.add "X-Amz-Signature", valid_592241
  var valid_592242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592242 = validateParameter(valid_592242, JString, required = false,
                                 default = nil)
  if valid_592242 != nil:
    section.add "X-Amz-Content-Sha256", valid_592242
  var valid_592243 = header.getOrDefault("X-Amz-Date")
  valid_592243 = validateParameter(valid_592243, JString, required = false,
                                 default = nil)
  if valid_592243 != nil:
    section.add "X-Amz-Date", valid_592243
  var valid_592244 = header.getOrDefault("X-Amz-Credential")
  valid_592244 = validateParameter(valid_592244, JString, required = false,
                                 default = nil)
  if valid_592244 != nil:
    section.add "X-Amz-Credential", valid_592244
  var valid_592245 = header.getOrDefault("X-Amz-Security-Token")
  valid_592245 = validateParameter(valid_592245, JString, required = false,
                                 default = nil)
  if valid_592245 != nil:
    section.add "X-Amz-Security-Token", valid_592245
  var valid_592246 = header.getOrDefault("X-Amz-Algorithm")
  valid_592246 = validateParameter(valid_592246, JString, required = false,
                                 default = nil)
  if valid_592246 != nil:
    section.add "X-Amz-Algorithm", valid_592246
  var valid_592247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592247 = validateParameter(valid_592247, JString, required = false,
                                 default = nil)
  if valid_592247 != nil:
    section.add "X-Amz-SignedHeaders", valid_592247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592248: Call_ListTemplates_592234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_592248.validator(path, query, header, formData, body)
  let scheme = call_592248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592248.url(scheme.get, call_592248.host, call_592248.base,
                         call_592248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592248, url, valid)

proc call*(call_592249: Call_ListTemplates_592234; prefix: string = "";
          pageSize: string = ""; templateType: string = ""; nextToken: string = ""): Recallable =
  ## listTemplates
  ## Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
  ##   prefix: string
  ##         : The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  ##   pageSize: string
  ##           : The maximum number of items to include in each page of a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  ##   templateType: string
  ##               : The type of message template to include in the results. Valid values are: EMAIL, SMS, and PUSH. To include all types of templates in the results, don't include this parameter in your request.
  ##   nextToken: string
  ##            : The NextToken string that specifies which page of results to return in a paginated response. This parameter is currently not supported by the Application Metrics and Campaign Metrics resources.
  var query_592250 = newJObject()
  add(query_592250, "prefix", newJString(prefix))
  add(query_592250, "page-size", newJString(pageSize))
  add(query_592250, "template-type", newJString(templateType))
  add(query_592250, "next-token", newJString(nextToken))
  result = call_592249.call(nil, query_592250, nil, nil, nil)

var listTemplates* = Call_ListTemplates_592234(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "pinpoint.amazonaws.com",
    route: "/v1/templates", validator: validate_ListTemplates_592235, base: "/",
    url: url_ListTemplates_592236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PhoneNumberValidate_592251 = ref object of OpenApiRestCall_590348
proc url_PhoneNumberValidate_592253(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PhoneNumberValidate_592252(path: JsonNode; query: JsonNode;
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
  var valid_592254 = header.getOrDefault("X-Amz-Signature")
  valid_592254 = validateParameter(valid_592254, JString, required = false,
                                 default = nil)
  if valid_592254 != nil:
    section.add "X-Amz-Signature", valid_592254
  var valid_592255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592255 = validateParameter(valid_592255, JString, required = false,
                                 default = nil)
  if valid_592255 != nil:
    section.add "X-Amz-Content-Sha256", valid_592255
  var valid_592256 = header.getOrDefault("X-Amz-Date")
  valid_592256 = validateParameter(valid_592256, JString, required = false,
                                 default = nil)
  if valid_592256 != nil:
    section.add "X-Amz-Date", valid_592256
  var valid_592257 = header.getOrDefault("X-Amz-Credential")
  valid_592257 = validateParameter(valid_592257, JString, required = false,
                                 default = nil)
  if valid_592257 != nil:
    section.add "X-Amz-Credential", valid_592257
  var valid_592258 = header.getOrDefault("X-Amz-Security-Token")
  valid_592258 = validateParameter(valid_592258, JString, required = false,
                                 default = nil)
  if valid_592258 != nil:
    section.add "X-Amz-Security-Token", valid_592258
  var valid_592259 = header.getOrDefault("X-Amz-Algorithm")
  valid_592259 = validateParameter(valid_592259, JString, required = false,
                                 default = nil)
  if valid_592259 != nil:
    section.add "X-Amz-Algorithm", valid_592259
  var valid_592260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592260 = validateParameter(valid_592260, JString, required = false,
                                 default = nil)
  if valid_592260 != nil:
    section.add "X-Amz-SignedHeaders", valid_592260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592262: Call_PhoneNumberValidate_592251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a phone number.
  ## 
  let valid = call_592262.validator(path, query, header, formData, body)
  let scheme = call_592262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592262.url(scheme.get, call_592262.host, call_592262.base,
                         call_592262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592262, url, valid)

proc call*(call_592263: Call_PhoneNumberValidate_592251; body: JsonNode): Recallable =
  ## phoneNumberValidate
  ## Retrieves information about a phone number.
  ##   body: JObject (required)
  var body_592264 = newJObject()
  if body != nil:
    body_592264 = body
  result = call_592263.call(nil, nil, nil, nil, body_592264)

var phoneNumberValidate* = Call_PhoneNumberValidate_592251(
    name: "phoneNumberValidate", meth: HttpMethod.HttpPost,
    host: "pinpoint.amazonaws.com", route: "/v1/phone/number/validate",
    validator: validate_PhoneNumberValidate_592252, base: "/",
    url: url_PhoneNumberValidate_592253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_592265 = ref object of OpenApiRestCall_590348
proc url_PutEvents_592267(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutEvents_592266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592268 = path.getOrDefault("application-id")
  valid_592268 = validateParameter(valid_592268, JString, required = true,
                                 default = nil)
  if valid_592268 != nil:
    section.add "application-id", valid_592268
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592269 = header.getOrDefault("X-Amz-Signature")
  valid_592269 = validateParameter(valid_592269, JString, required = false,
                                 default = nil)
  if valid_592269 != nil:
    section.add "X-Amz-Signature", valid_592269
  var valid_592270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592270 = validateParameter(valid_592270, JString, required = false,
                                 default = nil)
  if valid_592270 != nil:
    section.add "X-Amz-Content-Sha256", valid_592270
  var valid_592271 = header.getOrDefault("X-Amz-Date")
  valid_592271 = validateParameter(valid_592271, JString, required = false,
                                 default = nil)
  if valid_592271 != nil:
    section.add "X-Amz-Date", valid_592271
  var valid_592272 = header.getOrDefault("X-Amz-Credential")
  valid_592272 = validateParameter(valid_592272, JString, required = false,
                                 default = nil)
  if valid_592272 != nil:
    section.add "X-Amz-Credential", valid_592272
  var valid_592273 = header.getOrDefault("X-Amz-Security-Token")
  valid_592273 = validateParameter(valid_592273, JString, required = false,
                                 default = nil)
  if valid_592273 != nil:
    section.add "X-Amz-Security-Token", valid_592273
  var valid_592274 = header.getOrDefault("X-Amz-Algorithm")
  valid_592274 = validateParameter(valid_592274, JString, required = false,
                                 default = nil)
  if valid_592274 != nil:
    section.add "X-Amz-Algorithm", valid_592274
  var valid_592275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592275 = validateParameter(valid_592275, JString, required = false,
                                 default = nil)
  if valid_592275 != nil:
    section.add "X-Amz-SignedHeaders", valid_592275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592277: Call_PutEvents_592265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ## 
  let valid = call_592277.validator(path, query, header, formData, body)
  let scheme = call_592277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592277.url(scheme.get, call_592277.host, call_592277.base,
                         call_592277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592277, url, valid)

proc call*(call_592278: Call_PutEvents_592265; applicationId: string; body: JsonNode): Recallable =
  ## putEvents
  ## Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592279 = newJObject()
  var body_592280 = newJObject()
  add(path_592279, "application-id", newJString(applicationId))
  if body != nil:
    body_592280 = body
  result = call_592278.call(path_592279, nil, nil, nil, body_592280)

var putEvents* = Call_PutEvents_592265(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "pinpoint.amazonaws.com",
                                    route: "/v1/apps/{application-id}/events",
                                    validator: validate_PutEvents_592266,
                                    base: "/", url: url_PutEvents_592267,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributes_592281 = ref object of OpenApiRestCall_590348
proc url_RemoveAttributes_592283(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveAttributes_592282(path: JsonNode; query: JsonNode;
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
  var valid_592284 = path.getOrDefault("attribute-type")
  valid_592284 = validateParameter(valid_592284, JString, required = true,
                                 default = nil)
  if valid_592284 != nil:
    section.add "attribute-type", valid_592284
  var valid_592285 = path.getOrDefault("application-id")
  valid_592285 = validateParameter(valid_592285, JString, required = true,
                                 default = nil)
  if valid_592285 != nil:
    section.add "application-id", valid_592285
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592286 = header.getOrDefault("X-Amz-Signature")
  valid_592286 = validateParameter(valid_592286, JString, required = false,
                                 default = nil)
  if valid_592286 != nil:
    section.add "X-Amz-Signature", valid_592286
  var valid_592287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592287 = validateParameter(valid_592287, JString, required = false,
                                 default = nil)
  if valid_592287 != nil:
    section.add "X-Amz-Content-Sha256", valid_592287
  var valid_592288 = header.getOrDefault("X-Amz-Date")
  valid_592288 = validateParameter(valid_592288, JString, required = false,
                                 default = nil)
  if valid_592288 != nil:
    section.add "X-Amz-Date", valid_592288
  var valid_592289 = header.getOrDefault("X-Amz-Credential")
  valid_592289 = validateParameter(valid_592289, JString, required = false,
                                 default = nil)
  if valid_592289 != nil:
    section.add "X-Amz-Credential", valid_592289
  var valid_592290 = header.getOrDefault("X-Amz-Security-Token")
  valid_592290 = validateParameter(valid_592290, JString, required = false,
                                 default = nil)
  if valid_592290 != nil:
    section.add "X-Amz-Security-Token", valid_592290
  var valid_592291 = header.getOrDefault("X-Amz-Algorithm")
  valid_592291 = validateParameter(valid_592291, JString, required = false,
                                 default = nil)
  if valid_592291 != nil:
    section.add "X-Amz-Algorithm", valid_592291
  var valid_592292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592292 = validateParameter(valid_592292, JString, required = false,
                                 default = nil)
  if valid_592292 != nil:
    section.add "X-Amz-SignedHeaders", valid_592292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592294: Call_RemoveAttributes_592281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ## 
  let valid = call_592294.validator(path, query, header, formData, body)
  let scheme = call_592294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592294.url(scheme.get, call_592294.host, call_592294.base,
                         call_592294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592294, url, valid)

proc call*(call_592295: Call_RemoveAttributes_592281; attributeType: string;
          applicationId: string; body: JsonNode): Recallable =
  ## removeAttributes
  ## Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
  ##   attributeType: string (required)
  ##                :  <p>The type of attribute or attributes to remove. Valid values are:</p> <ul><li><p>endpoint-custom-attributes - Custom attributes that describe endpoints, such as the date when an associated user opted in or out of receiving communications from you through a specific type of channel.</p></li> <li><p>endpoint-custom-metrics - Custom metrics that your app reports to Amazon Pinpoint for endpoints, such as the number of app sessions or the number of items left in a cart.</p></li> <li><p>endpoint-user-attributes - Custom attributes that describe users, such as first name, last name, and age.</p></li></ul>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592296 = newJObject()
  var body_592297 = newJObject()
  add(path_592296, "attribute-type", newJString(attributeType))
  add(path_592296, "application-id", newJString(applicationId))
  if body != nil:
    body_592297 = body
  result = call_592295.call(path_592296, nil, nil, nil, body_592297)

var removeAttributes* = Call_RemoveAttributes_592281(name: "removeAttributes",
    meth: HttpMethod.HttpPut, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/attributes/{attribute-type}",
    validator: validate_RemoveAttributes_592282, base: "/",
    url: url_RemoveAttributes_592283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessages_592298 = ref object of OpenApiRestCall_590348
proc url_SendMessages_592300(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessages_592299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592301 = path.getOrDefault("application-id")
  valid_592301 = validateParameter(valid_592301, JString, required = true,
                                 default = nil)
  if valid_592301 != nil:
    section.add "application-id", valid_592301
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592302 = header.getOrDefault("X-Amz-Signature")
  valid_592302 = validateParameter(valid_592302, JString, required = false,
                                 default = nil)
  if valid_592302 != nil:
    section.add "X-Amz-Signature", valid_592302
  var valid_592303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592303 = validateParameter(valid_592303, JString, required = false,
                                 default = nil)
  if valid_592303 != nil:
    section.add "X-Amz-Content-Sha256", valid_592303
  var valid_592304 = header.getOrDefault("X-Amz-Date")
  valid_592304 = validateParameter(valid_592304, JString, required = false,
                                 default = nil)
  if valid_592304 != nil:
    section.add "X-Amz-Date", valid_592304
  var valid_592305 = header.getOrDefault("X-Amz-Credential")
  valid_592305 = validateParameter(valid_592305, JString, required = false,
                                 default = nil)
  if valid_592305 != nil:
    section.add "X-Amz-Credential", valid_592305
  var valid_592306 = header.getOrDefault("X-Amz-Security-Token")
  valid_592306 = validateParameter(valid_592306, JString, required = false,
                                 default = nil)
  if valid_592306 != nil:
    section.add "X-Amz-Security-Token", valid_592306
  var valid_592307 = header.getOrDefault("X-Amz-Algorithm")
  valid_592307 = validateParameter(valid_592307, JString, required = false,
                                 default = nil)
  if valid_592307 != nil:
    section.add "X-Amz-Algorithm", valid_592307
  var valid_592308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592308 = validateParameter(valid_592308, JString, required = false,
                                 default = nil)
  if valid_592308 != nil:
    section.add "X-Amz-SignedHeaders", valid_592308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592310: Call_SendMessages_592298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a direct message.
  ## 
  let valid = call_592310.validator(path, query, header, formData, body)
  let scheme = call_592310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592310.url(scheme.get, call_592310.host, call_592310.base,
                         call_592310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592310, url, valid)

proc call*(call_592311: Call_SendMessages_592298; applicationId: string;
          body: JsonNode): Recallable =
  ## sendMessages
  ## Creates and sends a direct message.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592312 = newJObject()
  var body_592313 = newJObject()
  add(path_592312, "application-id", newJString(applicationId))
  if body != nil:
    body_592313 = body
  result = call_592311.call(path_592312, nil, nil, nil, body_592313)

var sendMessages* = Call_SendMessages_592298(name: "sendMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/messages", validator: validate_SendMessages_592299,
    base: "/", url: url_SendMessages_592300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendUsersMessages_592314 = ref object of OpenApiRestCall_590348
proc url_SendUsersMessages_592316(protocol: Scheme; host: string; base: string;
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

proc validate_SendUsersMessages_592315(path: JsonNode; query: JsonNode;
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
  var valid_592317 = path.getOrDefault("application-id")
  valid_592317 = validateParameter(valid_592317, JString, required = true,
                                 default = nil)
  if valid_592317 != nil:
    section.add "application-id", valid_592317
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592318 = header.getOrDefault("X-Amz-Signature")
  valid_592318 = validateParameter(valid_592318, JString, required = false,
                                 default = nil)
  if valid_592318 != nil:
    section.add "X-Amz-Signature", valid_592318
  var valid_592319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592319 = validateParameter(valid_592319, JString, required = false,
                                 default = nil)
  if valid_592319 != nil:
    section.add "X-Amz-Content-Sha256", valid_592319
  var valid_592320 = header.getOrDefault("X-Amz-Date")
  valid_592320 = validateParameter(valid_592320, JString, required = false,
                                 default = nil)
  if valid_592320 != nil:
    section.add "X-Amz-Date", valid_592320
  var valid_592321 = header.getOrDefault("X-Amz-Credential")
  valid_592321 = validateParameter(valid_592321, JString, required = false,
                                 default = nil)
  if valid_592321 != nil:
    section.add "X-Amz-Credential", valid_592321
  var valid_592322 = header.getOrDefault("X-Amz-Security-Token")
  valid_592322 = validateParameter(valid_592322, JString, required = false,
                                 default = nil)
  if valid_592322 != nil:
    section.add "X-Amz-Security-Token", valid_592322
  var valid_592323 = header.getOrDefault("X-Amz-Algorithm")
  valid_592323 = validateParameter(valid_592323, JString, required = false,
                                 default = nil)
  if valid_592323 != nil:
    section.add "X-Amz-Algorithm", valid_592323
  var valid_592324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592324 = validateParameter(valid_592324, JString, required = false,
                                 default = nil)
  if valid_592324 != nil:
    section.add "X-Amz-SignedHeaders", valid_592324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592326: Call_SendUsersMessages_592314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and sends a message to a list of users.
  ## 
  let valid = call_592326.validator(path, query, header, formData, body)
  let scheme = call_592326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592326.url(scheme.get, call_592326.host, call_592326.base,
                         call_592326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592326, url, valid)

proc call*(call_592327: Call_SendUsersMessages_592314; applicationId: string;
          body: JsonNode): Recallable =
  ## sendUsersMessages
  ## Creates and sends a message to a list of users.
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592328 = newJObject()
  var body_592329 = newJObject()
  add(path_592328, "application-id", newJString(applicationId))
  if body != nil:
    body_592329 = body
  result = call_592327.call(path_592328, nil, nil, nil, body_592329)

var sendUsersMessages* = Call_SendUsersMessages_592314(name: "sendUsersMessages",
    meth: HttpMethod.HttpPost, host: "pinpoint.amazonaws.com",
    route: "/v1/apps/{application-id}/users-messages",
    validator: validate_SendUsersMessages_592315, base: "/",
    url: url_SendUsersMessages_592316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592330 = ref object of OpenApiRestCall_590348
proc url_UntagResource_592332(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_592331(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_592333 = path.getOrDefault("resource-arn")
  valid_592333 = validateParameter(valid_592333, JString, required = true,
                                 default = nil)
  if valid_592333 != nil:
    section.add "resource-arn", valid_592333
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, message template, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_592334 = query.getOrDefault("tagKeys")
  valid_592334 = validateParameter(valid_592334, JArray, required = true, default = nil)
  if valid_592334 != nil:
    section.add "tagKeys", valid_592334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592335 = header.getOrDefault("X-Amz-Signature")
  valid_592335 = validateParameter(valid_592335, JString, required = false,
                                 default = nil)
  if valid_592335 != nil:
    section.add "X-Amz-Signature", valid_592335
  var valid_592336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592336 = validateParameter(valid_592336, JString, required = false,
                                 default = nil)
  if valid_592336 != nil:
    section.add "X-Amz-Content-Sha256", valid_592336
  var valid_592337 = header.getOrDefault("X-Amz-Date")
  valid_592337 = validateParameter(valid_592337, JString, required = false,
                                 default = nil)
  if valid_592337 != nil:
    section.add "X-Amz-Date", valid_592337
  var valid_592338 = header.getOrDefault("X-Amz-Credential")
  valid_592338 = validateParameter(valid_592338, JString, required = false,
                                 default = nil)
  if valid_592338 != nil:
    section.add "X-Amz-Credential", valid_592338
  var valid_592339 = header.getOrDefault("X-Amz-Security-Token")
  valid_592339 = validateParameter(valid_592339, JString, required = false,
                                 default = nil)
  if valid_592339 != nil:
    section.add "X-Amz-Security-Token", valid_592339
  var valid_592340 = header.getOrDefault("X-Amz-Algorithm")
  valid_592340 = validateParameter(valid_592340, JString, required = false,
                                 default = nil)
  if valid_592340 != nil:
    section.add "X-Amz-Algorithm", valid_592340
  var valid_592341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592341 = validateParameter(valid_592341, JString, required = false,
                                 default = nil)
  if valid_592341 != nil:
    section.add "X-Amz-SignedHeaders", valid_592341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592342: Call_UntagResource_592330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
  ## 
  let valid = call_592342.validator(path, query, header, formData, body)
  let scheme = call_592342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592342.url(scheme.get, call_592342.host, call_592342.base,
                         call_592342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592342, url, valid)

proc call*(call_592343: Call_UntagResource_592330; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the application, campaign, message template, or segment.
  ##   tagKeys: JArray (required)
  ##          : The key of the tag to remove from the application, campaign, message template, or segment. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&amp;).
  var path_592344 = newJObject()
  var query_592345 = newJObject()
  add(path_592344, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_592345.add "tagKeys", tagKeys
  result = call_592343.call(path_592344, query_592345, nil, nil, nil)

var untagResource* = Call_UntagResource_592330(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "pinpoint.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_592331,
    base: "/", url: url_UntagResource_592332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointsBatch_592346 = ref object of OpenApiRestCall_590348
proc url_UpdateEndpointsBatch_592348(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpointsBatch_592347(path: JsonNode; query: JsonNode;
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
  var valid_592349 = path.getOrDefault("application-id")
  valid_592349 = validateParameter(valid_592349, JString, required = true,
                                 default = nil)
  if valid_592349 != nil:
    section.add "application-id", valid_592349
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592350 = header.getOrDefault("X-Amz-Signature")
  valid_592350 = validateParameter(valid_592350, JString, required = false,
                                 default = nil)
  if valid_592350 != nil:
    section.add "X-Amz-Signature", valid_592350
  var valid_592351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592351 = validateParameter(valid_592351, JString, required = false,
                                 default = nil)
  if valid_592351 != nil:
    section.add "X-Amz-Content-Sha256", valid_592351
  var valid_592352 = header.getOrDefault("X-Amz-Date")
  valid_592352 = validateParameter(valid_592352, JString, required = false,
                                 default = nil)
  if valid_592352 != nil:
    section.add "X-Amz-Date", valid_592352
  var valid_592353 = header.getOrDefault("X-Amz-Credential")
  valid_592353 = validateParameter(valid_592353, JString, required = false,
                                 default = nil)
  if valid_592353 != nil:
    section.add "X-Amz-Credential", valid_592353
  var valid_592354 = header.getOrDefault("X-Amz-Security-Token")
  valid_592354 = validateParameter(valid_592354, JString, required = false,
                                 default = nil)
  if valid_592354 != nil:
    section.add "X-Amz-Security-Token", valid_592354
  var valid_592355 = header.getOrDefault("X-Amz-Algorithm")
  valid_592355 = validateParameter(valid_592355, JString, required = false,
                                 default = nil)
  if valid_592355 != nil:
    section.add "X-Amz-Algorithm", valid_592355
  var valid_592356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592356 = validateParameter(valid_592356, JString, required = false,
                                 default = nil)
  if valid_592356 != nil:
    section.add "X-Amz-SignedHeaders", valid_592356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592358: Call_UpdateEndpointsBatch_592346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ## 
  let valid = call_592358.validator(path, query, header, formData, body)
  let scheme = call_592358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592358.url(scheme.get, call_592358.host, call_592358.base,
                         call_592358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592358, url, valid)

proc call*(call_592359: Call_UpdateEndpointsBatch_592346; applicationId: string;
          body: JsonNode): Recallable =
  ## updateEndpointsBatch
  ##  <p>Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes (Attributes, Metrics, and UserAttributes properties) for a batch of endpoints.</p>
  ##   applicationId: string (required)
  ##                : The unique identifier for the application. This identifier is displayed as the <b>Project ID</b> on the Amazon Pinpoint console.
  ##   body: JObject (required)
  var path_592360 = newJObject()
  var body_592361 = newJObject()
  add(path_592360, "application-id", newJString(applicationId))
  if body != nil:
    body_592361 = body
  result = call_592359.call(path_592360, nil, nil, nil, body_592361)

var updateEndpointsBatch* = Call_UpdateEndpointsBatch_592346(
    name: "updateEndpointsBatch", meth: HttpMethod.HttpPut,
    host: "pinpoint.amazonaws.com", route: "/v1/apps/{application-id}/endpoints",
    validator: validate_UpdateEndpointsBatch_592347, base: "/",
    url: url_UpdateEndpointsBatch_592348, schemes: {Scheme.Https, Scheme.Http})
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
