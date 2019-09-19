
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint SMS and Voice Service
## version: 2018-09-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Pinpoint SMS and Voice Messaging public facing APIs
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

  OpenApiRestCall_772572 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772572](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772572): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "sms-voice.pinpoint.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sms-voice.pinpoint.ap-southeast-1.amazonaws.com", "us-west-2": "sms-voice.pinpoint.us-west-2.amazonaws.com", "eu-west-2": "sms-voice.pinpoint.eu-west-2.amazonaws.com", "ap-northeast-3": "sms-voice.pinpoint.ap-northeast-3.amazonaws.com", "eu-central-1": "sms-voice.pinpoint.eu-central-1.amazonaws.com", "us-east-2": "sms-voice.pinpoint.us-east-2.amazonaws.com", "us-east-1": "sms-voice.pinpoint.us-east-1.amazonaws.com", "cn-northwest-1": "sms-voice.pinpoint.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "sms-voice.pinpoint.ap-south-1.amazonaws.com", "eu-north-1": "sms-voice.pinpoint.eu-north-1.amazonaws.com", "ap-northeast-2": "sms-voice.pinpoint.ap-northeast-2.amazonaws.com", "us-west-1": "sms-voice.pinpoint.us-west-1.amazonaws.com", "us-gov-east-1": "sms-voice.pinpoint.us-gov-east-1.amazonaws.com", "eu-west-3": "sms-voice.pinpoint.eu-west-3.amazonaws.com", "cn-north-1": "sms-voice.pinpoint.cn-north-1.amazonaws.com.cn", "sa-east-1": "sms-voice.pinpoint.sa-east-1.amazonaws.com", "eu-west-1": "sms-voice.pinpoint.eu-west-1.amazonaws.com", "us-gov-west-1": "sms-voice.pinpoint.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sms-voice.pinpoint.ap-southeast-2.amazonaws.com", "ca-central-1": "sms-voice.pinpoint.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sms-voice.pinpoint.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sms-voice.pinpoint.ap-southeast-1.amazonaws.com",
      "us-west-2": "sms-voice.pinpoint.us-west-2.amazonaws.com",
      "eu-west-2": "sms-voice.pinpoint.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sms-voice.pinpoint.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sms-voice.pinpoint.eu-central-1.amazonaws.com",
      "us-east-2": "sms-voice.pinpoint.us-east-2.amazonaws.com",
      "us-east-1": "sms-voice.pinpoint.us-east-1.amazonaws.com",
      "cn-northwest-1": "sms-voice.pinpoint.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sms-voice.pinpoint.ap-south-1.amazonaws.com",
      "eu-north-1": "sms-voice.pinpoint.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sms-voice.pinpoint.ap-northeast-2.amazonaws.com",
      "us-west-1": "sms-voice.pinpoint.us-west-1.amazonaws.com",
      "us-gov-east-1": "sms-voice.pinpoint.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sms-voice.pinpoint.eu-west-3.amazonaws.com",
      "cn-north-1": "sms-voice.pinpoint.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sms-voice.pinpoint.sa-east-1.amazonaws.com",
      "eu-west-1": "sms-voice.pinpoint.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sms-voice.pinpoint.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sms-voice.pinpoint.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sms-voice.pinpoint.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sms-voice"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_773165 = ref object of OpenApiRestCall_772572
proc url_CreateConfigurationSet_773167(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConfigurationSet_773166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
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
  var valid_773168 = header.getOrDefault("X-Amz-Date")
  valid_773168 = validateParameter(valid_773168, JString, required = false,
                                 default = nil)
  if valid_773168 != nil:
    section.add "X-Amz-Date", valid_773168
  var valid_773169 = header.getOrDefault("X-Amz-Security-Token")
  valid_773169 = validateParameter(valid_773169, JString, required = false,
                                 default = nil)
  if valid_773169 != nil:
    section.add "X-Amz-Security-Token", valid_773169
  var valid_773170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773170 = validateParameter(valid_773170, JString, required = false,
                                 default = nil)
  if valid_773170 != nil:
    section.add "X-Amz-Content-Sha256", valid_773170
  var valid_773171 = header.getOrDefault("X-Amz-Algorithm")
  valid_773171 = validateParameter(valid_773171, JString, required = false,
                                 default = nil)
  if valid_773171 != nil:
    section.add "X-Amz-Algorithm", valid_773171
  var valid_773172 = header.getOrDefault("X-Amz-Signature")
  valid_773172 = validateParameter(valid_773172, JString, required = false,
                                 default = nil)
  if valid_773172 != nil:
    section.add "X-Amz-Signature", valid_773172
  var valid_773173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773173 = validateParameter(valid_773173, JString, required = false,
                                 default = nil)
  if valid_773173 != nil:
    section.add "X-Amz-SignedHeaders", valid_773173
  var valid_773174 = header.getOrDefault("X-Amz-Credential")
  valid_773174 = validateParameter(valid_773174, JString, required = false,
                                 default = nil)
  if valid_773174 != nil:
    section.add "X-Amz-Credential", valid_773174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773176: Call_CreateConfigurationSet_773165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_773176.validator(path, query, header, formData, body)
  let scheme = call_773176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773176.url(scheme.get, call_773176.host, call_773176.base,
                         call_773176.route, valid.getOrDefault("path"))
  result = hook(call_773176, url, valid)

proc call*(call_773177: Call_CreateConfigurationSet_773165; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_773178 = newJObject()
  if body != nil:
    body_773178 = body
  result = call_773177.call(nil, nil, nil, nil, body_773178)

var createConfigurationSet* = Call_CreateConfigurationSet_773165(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_773166, base: "/",
    url: url_CreateConfigurationSet_773167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_772908 = ref object of OpenApiRestCall_772572
proc url_ListConfigurationSets_772910(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConfigurationSets_772909(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Used to specify the number of items that should be returned in the response.
  ##   NextToken: JString
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  section = newJObject()
  var valid_773022 = query.getOrDefault("PageSize")
  valid_773022 = validateParameter(valid_773022, JString, required = false,
                                 default = nil)
  if valid_773022 != nil:
    section.add "PageSize", valid_773022
  var valid_773023 = query.getOrDefault("NextToken")
  valid_773023 = validateParameter(valid_773023, JString, required = false,
                                 default = nil)
  if valid_773023 != nil:
    section.add "NextToken", valid_773023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773024 = header.getOrDefault("X-Amz-Date")
  valid_773024 = validateParameter(valid_773024, JString, required = false,
                                 default = nil)
  if valid_773024 != nil:
    section.add "X-Amz-Date", valid_773024
  var valid_773025 = header.getOrDefault("X-Amz-Security-Token")
  valid_773025 = validateParameter(valid_773025, JString, required = false,
                                 default = nil)
  if valid_773025 != nil:
    section.add "X-Amz-Security-Token", valid_773025
  var valid_773026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773026 = validateParameter(valid_773026, JString, required = false,
                                 default = nil)
  if valid_773026 != nil:
    section.add "X-Amz-Content-Sha256", valid_773026
  var valid_773027 = header.getOrDefault("X-Amz-Algorithm")
  valid_773027 = validateParameter(valid_773027, JString, required = false,
                                 default = nil)
  if valid_773027 != nil:
    section.add "X-Amz-Algorithm", valid_773027
  var valid_773028 = header.getOrDefault("X-Amz-Signature")
  valid_773028 = validateParameter(valid_773028, JString, required = false,
                                 default = nil)
  if valid_773028 != nil:
    section.add "X-Amz-Signature", valid_773028
  var valid_773029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773029 = validateParameter(valid_773029, JString, required = false,
                                 default = nil)
  if valid_773029 != nil:
    section.add "X-Amz-SignedHeaders", valid_773029
  var valid_773030 = header.getOrDefault("X-Amz-Credential")
  valid_773030 = validateParameter(valid_773030, JString, required = false,
                                 default = nil)
  if valid_773030 != nil:
    section.add "X-Amz-Credential", valid_773030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773053: Call_ListConfigurationSets_772908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_773053.validator(path, query, header, formData, body)
  let scheme = call_773053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773053.url(scheme.get, call_773053.host, call_773053.base,
                         call_773053.route, valid.getOrDefault("path"))
  result = hook(call_773053, url, valid)

proc call*(call_773124: Call_ListConfigurationSets_772908; PageSize: string = "";
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  var query_773125 = newJObject()
  add(query_773125, "PageSize", newJString(PageSize))
  add(query_773125, "NextToken", newJString(NextToken))
  result = call_773124.call(nil, query_773125, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_772908(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_772909, base: "/",
    url: url_ListConfigurationSets_772910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_773207 = ref object of OpenApiRestCall_772572
proc url_CreateConfigurationSetEventDestination_773209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateConfigurationSetEventDestination_773208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new event destination in a configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_773210 = path.getOrDefault("ConfigurationSetName")
  valid_773210 = validateParameter(valid_773210, JString, required = true,
                                 default = nil)
  if valid_773210 != nil:
    section.add "ConfigurationSetName", valid_773210
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773211 = header.getOrDefault("X-Amz-Date")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Date", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Security-Token")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Security-Token", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Content-Sha256", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Algorithm")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Algorithm", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Signature")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Signature", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-SignedHeaders", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Credential")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Credential", valid_773217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773219: Call_CreateConfigurationSetEventDestination_773207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_773219.validator(path, query, header, formData, body)
  let scheme = call_773219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773219.url(scheme.get, call_773219.host, call_773219.base,
                         call_773219.route, valid.getOrDefault("path"))
  result = hook(call_773219, url, valid)

proc call*(call_773220: Call_CreateConfigurationSetEventDestination_773207;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_773221 = newJObject()
  var body_773222 = newJObject()
  add(path_773221, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773222 = body
  result = call_773220.call(path_773221, nil, nil, nil, body_773222)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_773207(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_773208, base: "/",
    url: url_CreateConfigurationSetEventDestination_773209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_773179 = ref object of OpenApiRestCall_772572
proc url_GetConfigurationSetEventDestinations_773181(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConfigurationSetEventDestinations_773180(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_773196 = path.getOrDefault("ConfigurationSetName")
  valid_773196 = validateParameter(valid_773196, JString, required = true,
                                 default = nil)
  if valid_773196 != nil:
    section.add "ConfigurationSetName", valid_773196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773197 = header.getOrDefault("X-Amz-Date")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Date", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-Security-Token")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Security-Token", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Content-Sha256", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-Algorithm")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-Algorithm", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Signature")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Signature", valid_773201
  var valid_773202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773202 = validateParameter(valid_773202, JString, required = false,
                                 default = nil)
  if valid_773202 != nil:
    section.add "X-Amz-SignedHeaders", valid_773202
  var valid_773203 = header.getOrDefault("X-Amz-Credential")
  valid_773203 = validateParameter(valid_773203, JString, required = false,
                                 default = nil)
  if valid_773203 != nil:
    section.add "X-Amz-Credential", valid_773203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773204: Call_GetConfigurationSetEventDestinations_773179;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_773204.validator(path, query, header, formData, body)
  let scheme = call_773204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773204.url(scheme.get, call_773204.host, call_773204.base,
                         call_773204.route, valid.getOrDefault("path"))
  result = hook(call_773204, url, valid)

proc call*(call_773205: Call_GetConfigurationSetEventDestinations_773179;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_773206 = newJObject()
  add(path_773206, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_773205.call(path_773206, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_773179(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_773180, base: "/",
    url: url_GetConfigurationSetEventDestinations_773181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_773223 = ref object of OpenApiRestCall_772572
proc url_DeleteConfigurationSet_773225(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConfigurationSet_773224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_773226 = path.getOrDefault("ConfigurationSetName")
  valid_773226 = validateParameter(valid_773226, JString, required = true,
                                 default = nil)
  if valid_773226 != nil:
    section.add "ConfigurationSetName", valid_773226
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773227 = header.getOrDefault("X-Amz-Date")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Date", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Security-Token")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Security-Token", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Content-Sha256", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Algorithm")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Algorithm", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Signature")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Signature", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-SignedHeaders", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Credential")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Credential", valid_773233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773234: Call_DeleteConfigurationSet_773223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_773234.validator(path, query, header, formData, body)
  let scheme = call_773234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773234.url(scheme.get, call_773234.host, call_773234.base,
                         call_773234.route, valid.getOrDefault("path"))
  result = hook(call_773234, url, valid)

proc call*(call_773235: Call_DeleteConfigurationSet_773223;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_773236 = newJObject()
  add(path_773236, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_773235.call(path_773236, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_773223(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_773224, base: "/",
    url: url_DeleteConfigurationSet_773225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_773237 = ref object of OpenApiRestCall_772572
proc url_UpdateConfigurationSetEventDestination_773239(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateConfigurationSetEventDestination_773238(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: JString (required)
  ##                       : EventDestinationName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_773240 = path.getOrDefault("ConfigurationSetName")
  valid_773240 = validateParameter(valid_773240, JString, required = true,
                                 default = nil)
  if valid_773240 != nil:
    section.add "ConfigurationSetName", valid_773240
  var valid_773241 = path.getOrDefault("EventDestinationName")
  valid_773241 = validateParameter(valid_773241, JString, required = true,
                                 default = nil)
  if valid_773241 != nil:
    section.add "EventDestinationName", valid_773241
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773242 = header.getOrDefault("X-Amz-Date")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Date", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Security-Token")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Security-Token", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Content-Sha256", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Algorithm")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Algorithm", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Signature")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Signature", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-SignedHeaders", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Credential")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Credential", valid_773248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773250: Call_UpdateConfigurationSetEventDestination_773237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_773250.validator(path, query, header, formData, body)
  let scheme = call_773250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773250.url(scheme.get, call_773250.host, call_773250.base,
                         call_773250.route, valid.getOrDefault("path"))
  result = hook(call_773250, url, valid)

proc call*(call_773251: Call_UpdateConfigurationSetEventDestination_773237;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_773252 = newJObject()
  var body_773253 = newJObject()
  add(path_773252, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_773253 = body
  add(path_773252, "EventDestinationName", newJString(EventDestinationName))
  result = call_773251.call(path_773252, nil, nil, nil, body_773253)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_773237(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_773238, base: "/",
    url: url_UpdateConfigurationSetEventDestination_773239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_773254 = ref object of OpenApiRestCall_772572
proc url_DeleteConfigurationSetEventDestination_773256(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConfigurationSetEventDestination_773255(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an event destination in a configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: JString (required)
  ##                       : EventDestinationName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_773257 = path.getOrDefault("ConfigurationSetName")
  valid_773257 = validateParameter(valid_773257, JString, required = true,
                                 default = nil)
  if valid_773257 != nil:
    section.add "ConfigurationSetName", valid_773257
  var valid_773258 = path.getOrDefault("EventDestinationName")
  valid_773258 = validateParameter(valid_773258, JString, required = true,
                                 default = nil)
  if valid_773258 != nil:
    section.add "EventDestinationName", valid_773258
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773259 = header.getOrDefault("X-Amz-Date")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Date", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Security-Token")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Security-Token", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Content-Sha256", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Algorithm")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Algorithm", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Signature")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Signature", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-SignedHeaders", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Credential")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Credential", valid_773265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773266: Call_DeleteConfigurationSetEventDestination_773254;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_773266.validator(path, query, header, formData, body)
  let scheme = call_773266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773266.url(scheme.get, call_773266.host, call_773266.base,
                         call_773266.route, valid.getOrDefault("path"))
  result = hook(call_773266, url, valid)

proc call*(call_773267: Call_DeleteConfigurationSetEventDestination_773254;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_773268 = newJObject()
  add(path_773268, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_773268, "EventDestinationName", newJString(EventDestinationName))
  result = call_773267.call(path_773268, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_773254(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_773255, base: "/",
    url: url_DeleteConfigurationSetEventDestination_773256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_773269 = ref object of OpenApiRestCall_772572
proc url_SendVoiceMessage_773271(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendVoiceMessage_773270(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Create a new voice message and send it to a recipient's phone number.
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
  var valid_773272 = header.getOrDefault("X-Amz-Date")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Date", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Security-Token")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Security-Token", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Content-Sha256", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Algorithm")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Algorithm", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Signature")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Signature", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-SignedHeaders", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Credential")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Credential", valid_773278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773280: Call_SendVoiceMessage_773269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_773280.validator(path, query, header, formData, body)
  let scheme = call_773280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773280.url(scheme.get, call_773280.host, call_773280.base,
                         call_773280.route, valid.getOrDefault("path"))
  result = hook(call_773280, url, valid)

proc call*(call_773281: Call_SendVoiceMessage_773269; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_773282 = newJObject()
  if body != nil:
    body_773282 = body
  result = call_773281.call(nil, nil, nil, nil, body_773282)

var sendVoiceMessage* = Call_SendVoiceMessage_773269(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_773270,
    base: "/", url: url_SendVoiceMessage_773271,
    schemes: {Scheme.Https, Scheme.Http})
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
