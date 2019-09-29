
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593408 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593408](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593408): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_594002 = ref object of OpenApiRestCall_593408
proc url_CreateConfigurationSet_594004(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfigurationSet_594003(path: JsonNode; query: JsonNode;
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
  var valid_594005 = header.getOrDefault("X-Amz-Date")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Date", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Security-Token")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Security-Token", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Content-Sha256", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Algorithm")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Algorithm", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Signature")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Signature", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-SignedHeaders", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Credential")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Credential", valid_594011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594013: Call_CreateConfigurationSet_594002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_594013.validator(path, query, header, formData, body)
  let scheme = call_594013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594013.url(scheme.get, call_594013.host, call_594013.base,
                         call_594013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594013, url, valid)

proc call*(call_594014: Call_CreateConfigurationSet_594002; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_594015 = newJObject()
  if body != nil:
    body_594015 = body
  result = call_594014.call(nil, nil, nil, nil, body_594015)

var createConfigurationSet* = Call_CreateConfigurationSet_594002(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_594003, base: "/",
    url: url_CreateConfigurationSet_594004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_593745 = ref object of OpenApiRestCall_593408
proc url_ListConfigurationSets_593747(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurationSets_593746(path: JsonNode; query: JsonNode;
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
  var valid_593859 = query.getOrDefault("PageSize")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "PageSize", valid_593859
  var valid_593860 = query.getOrDefault("NextToken")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "NextToken", valid_593860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593861 = header.getOrDefault("X-Amz-Date")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Date", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Security-Token")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Security-Token", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Content-Sha256", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Algorithm")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Algorithm", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-Signature")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-Signature", valid_593865
  var valid_593866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593866 = validateParameter(valid_593866, JString, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "X-Amz-SignedHeaders", valid_593866
  var valid_593867 = header.getOrDefault("X-Amz-Credential")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-Credential", valid_593867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593890: Call_ListConfigurationSets_593745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_593890.validator(path, query, header, formData, body)
  let scheme = call_593890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593890.url(scheme.get, call_593890.host, call_593890.base,
                         call_593890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593890, url, valid)

proc call*(call_593961: Call_ListConfigurationSets_593745; PageSize: string = "";
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  var query_593962 = newJObject()
  add(query_593962, "PageSize", newJString(PageSize))
  add(query_593962, "NextToken", newJString(NextToken))
  result = call_593961.call(nil, query_593962, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_593745(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_593746, base: "/",
    url: url_ListConfigurationSets_593747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_594044 = ref object of OpenApiRestCall_593408
proc url_CreateConfigurationSetEventDestination_594046(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_594045(path: JsonNode;
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
  var valid_594047 = path.getOrDefault("ConfigurationSetName")
  valid_594047 = validateParameter(valid_594047, JString, required = true,
                                 default = nil)
  if valid_594047 != nil:
    section.add "ConfigurationSetName", valid_594047
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594048 = header.getOrDefault("X-Amz-Date")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Date", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Content-Sha256", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Algorithm")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Algorithm", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Signature")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Signature", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-SignedHeaders", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594056: Call_CreateConfigurationSetEventDestination_594044;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_594056.validator(path, query, header, formData, body)
  let scheme = call_594056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594056.url(scheme.get, call_594056.host, call_594056.base,
                         call_594056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594056, url, valid)

proc call*(call_594057: Call_CreateConfigurationSetEventDestination_594044;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_594058 = newJObject()
  var body_594059 = newJObject()
  add(path_594058, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594059 = body
  result = call_594057.call(path_594058, nil, nil, nil, body_594059)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_594044(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_594045, base: "/",
    url: url_CreateConfigurationSetEventDestination_594046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_594016 = ref object of OpenApiRestCall_593408
proc url_GetConfigurationSetEventDestinations_594018(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_594017(path: JsonNode;
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
  var valid_594033 = path.getOrDefault("ConfigurationSetName")
  valid_594033 = validateParameter(valid_594033, JString, required = true,
                                 default = nil)
  if valid_594033 != nil:
    section.add "ConfigurationSetName", valid_594033
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594034 = header.getOrDefault("X-Amz-Date")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Date", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Security-Token")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Security-Token", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Content-Sha256", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Algorithm")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Algorithm", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Signature")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Signature", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-SignedHeaders", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Credential")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Credential", valid_594040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594041: Call_GetConfigurationSetEventDestinations_594016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_594041.validator(path, query, header, formData, body)
  let scheme = call_594041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594041.url(scheme.get, call_594041.host, call_594041.base,
                         call_594041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594041, url, valid)

proc call*(call_594042: Call_GetConfigurationSetEventDestinations_594016;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_594043 = newJObject()
  add(path_594043, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_594042.call(path_594043, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_594016(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_594017, base: "/",
    url: url_GetConfigurationSetEventDestinations_594018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_594060 = ref object of OpenApiRestCall_593408
proc url_DeleteConfigurationSet_594062(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/sms-voice/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_594061(path: JsonNode; query: JsonNode;
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
  var valid_594063 = path.getOrDefault("ConfigurationSetName")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "ConfigurationSetName", valid_594063
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594064 = header.getOrDefault("X-Amz-Date")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Date", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Security-Token")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Security-Token", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Content-Sha256", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Signature")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Signature", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Credential")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Credential", valid_594070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_DeleteConfigurationSet_594060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_DeleteConfigurationSet_594060;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_594073 = newJObject()
  add(path_594073, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_594072.call(path_594073, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_594060(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_594061, base: "/",
    url: url_DeleteConfigurationSet_594062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_594074 = ref object of OpenApiRestCall_593408
proc url_UpdateConfigurationSetEventDestination_594076(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_594075(path: JsonNode;
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
  var valid_594077 = path.getOrDefault("ConfigurationSetName")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "ConfigurationSetName", valid_594077
  var valid_594078 = path.getOrDefault("EventDestinationName")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "EventDestinationName", valid_594078
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594079 = header.getOrDefault("X-Amz-Date")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Date", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Security-Token")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Security-Token", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Content-Sha256", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Algorithm")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Algorithm", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Signature")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Signature", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-SignedHeaders", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Credential")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Credential", valid_594085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594087: Call_UpdateConfigurationSetEventDestination_594074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_594087.validator(path, query, header, formData, body)
  let scheme = call_594087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594087.url(scheme.get, call_594087.host, call_594087.base,
                         call_594087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594087, url, valid)

proc call*(call_594088: Call_UpdateConfigurationSetEventDestination_594074;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_594089 = newJObject()
  var body_594090 = newJObject()
  add(path_594089, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594090 = body
  add(path_594089, "EventDestinationName", newJString(EventDestinationName))
  result = call_594088.call(path_594089, nil, nil, nil, body_594090)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_594074(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_594075, base: "/",
    url: url_UpdateConfigurationSetEventDestination_594076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_594091 = ref object of OpenApiRestCall_593408
proc url_DeleteConfigurationSetEventDestination_594093(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_594092(path: JsonNode;
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
  var valid_594094 = path.getOrDefault("ConfigurationSetName")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "ConfigurationSetName", valid_594094
  var valid_594095 = path.getOrDefault("EventDestinationName")
  valid_594095 = validateParameter(valid_594095, JString, required = true,
                                 default = nil)
  if valid_594095 != nil:
    section.add "EventDestinationName", valid_594095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594096 = header.getOrDefault("X-Amz-Date")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Date", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Security-Token")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Security-Token", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Content-Sha256", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Algorithm")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Algorithm", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Signature")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Signature", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-SignedHeaders", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Credential")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Credential", valid_594102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594103: Call_DeleteConfigurationSetEventDestination_594091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_594103.validator(path, query, header, formData, body)
  let scheme = call_594103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594103.url(scheme.get, call_594103.host, call_594103.base,
                         call_594103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594103, url, valid)

proc call*(call_594104: Call_DeleteConfigurationSetEventDestination_594091;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_594105 = newJObject()
  add(path_594105, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_594105, "EventDestinationName", newJString(EventDestinationName))
  result = call_594104.call(path_594105, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_594091(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_594092, base: "/",
    url: url_DeleteConfigurationSetEventDestination_594093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_594106 = ref object of OpenApiRestCall_593408
proc url_SendVoiceMessage_594108(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendVoiceMessage_594107(path: JsonNode; query: JsonNode;
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
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_SendVoiceMessage_594106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_SendVoiceMessage_594106; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_594119 = newJObject()
  if body != nil:
    body_594119 = body
  result = call_594118.call(nil, nil, nil, nil, body_594119)

var sendVoiceMessage* = Call_SendVoiceMessage_594106(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_594107,
    base: "/", url: url_SendVoiceMessage_594108,
    schemes: {Scheme.Https, Scheme.Http})
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
