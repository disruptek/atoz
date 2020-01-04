
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601364): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_601959 = ref object of OpenApiRestCall_601364
proc url_CreateConfigurationSet_601961(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfigurationSet_601960(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601962 = header.getOrDefault("X-Amz-Signature")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Signature", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Content-Sha256", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Date")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Date", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Credential")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Credential", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Security-Token")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Security-Token", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Algorithm")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Algorithm", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-SignedHeaders", valid_601968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601970: Call_CreateConfigurationSet_601959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_601970.validator(path, query, header, formData, body)
  let scheme = call_601970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601970.url(scheme.get, call_601970.host, call_601970.base,
                         call_601970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601970, url, valid)

proc call*(call_601971: Call_CreateConfigurationSet_601959; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_601972 = newJObject()
  if body != nil:
    body_601972 = body
  result = call_601971.call(nil, nil, nil, nil, body_601972)

var createConfigurationSet* = Call_CreateConfigurationSet_601959(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_601960, base: "/",
    url: url_CreateConfigurationSet_601961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_601702 = ref object of OpenApiRestCall_601364
proc url_ListConfigurationSets_601704(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigurationSets_601703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  ##   PageSize: JString
  ##           : Used to specify the number of items that should be returned in the response.
  section = newJObject()
  var valid_601816 = query.getOrDefault("NextToken")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "NextToken", valid_601816
  var valid_601817 = query.getOrDefault("PageSize")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "PageSize", valid_601817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601818 = header.getOrDefault("X-Amz-Signature")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Signature", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Content-Sha256", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Date")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Date", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Credential")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Credential", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Security-Token")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Security-Token", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Algorithm")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Algorithm", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-SignedHeaders", valid_601824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601847: Call_ListConfigurationSets_601702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_601847.validator(path, query, header, formData, body)
  let scheme = call_601847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601847.url(scheme.get, call_601847.host, call_601847.base,
                         call_601847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601847, url, valid)

proc call*(call_601918: Call_ListConfigurationSets_601702; NextToken: string = "";
          PageSize: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  var query_601919 = newJObject()
  add(query_601919, "NextToken", newJString(NextToken))
  add(query_601919, "PageSize", newJString(PageSize))
  result = call_601918.call(nil, query_601919, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_601702(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_601703, base: "/",
    url: url_ListConfigurationSets_601704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_602001 = ref object of OpenApiRestCall_601364
proc url_CreateConfigurationSetEventDestination_602003(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_602002(path: JsonNode;
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
  var valid_602004 = path.getOrDefault("ConfigurationSetName")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = nil)
  if valid_602004 != nil:
    section.add "ConfigurationSetName", valid_602004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602005 = header.getOrDefault("X-Amz-Signature")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Signature", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Content-Sha256", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Credential")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Credential", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Security-Token")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Security-Token", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602013: Call_CreateConfigurationSetEventDestination_602001;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_602013.validator(path, query, header, formData, body)
  let scheme = call_602013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602013.url(scheme.get, call_602013.host, call_602013.base,
                         call_602013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602013, url, valid)

proc call*(call_602014: Call_CreateConfigurationSetEventDestination_602001;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_602015 = newJObject()
  var body_602016 = newJObject()
  add(path_602015, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602016 = body
  result = call_602014.call(path_602015, nil, nil, nil, body_602016)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_602001(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_602002, base: "/",
    url: url_CreateConfigurationSetEventDestination_602003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_601973 = ref object of OpenApiRestCall_601364
proc url_GetConfigurationSetEventDestinations_601975(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_601974(path: JsonNode;
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
  var valid_601990 = path.getOrDefault("ConfigurationSetName")
  valid_601990 = validateParameter(valid_601990, JString, required = true,
                                 default = nil)
  if valid_601990 != nil:
    section.add "ConfigurationSetName", valid_601990
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601991 = header.getOrDefault("X-Amz-Signature")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Signature", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Date")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Date", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Algorithm")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Algorithm", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601998: Call_GetConfigurationSetEventDestinations_601973;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_601998.validator(path, query, header, formData, body)
  let scheme = call_601998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601998.url(scheme.get, call_601998.host, call_601998.base,
                         call_601998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601998, url, valid)

proc call*(call_601999: Call_GetConfigurationSetEventDestinations_601973;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_602000 = newJObject()
  add(path_602000, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_601999.call(path_602000, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_601973(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_601974, base: "/",
    url: url_GetConfigurationSetEventDestinations_601975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_602017 = ref object of OpenApiRestCall_601364
proc url_DeleteConfigurationSet_602019(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_602018(path: JsonNode; query: JsonNode;
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
  var valid_602020 = path.getOrDefault("ConfigurationSetName")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "ConfigurationSetName", valid_602020
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602021 = header.getOrDefault("X-Amz-Signature")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Signature", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Content-Sha256", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Credential")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Credential", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Security-Token")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Security-Token", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_DeleteConfigurationSet_602017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_DeleteConfigurationSet_602017;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_602030 = newJObject()
  add(path_602030, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_602029.call(path_602030, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_602017(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_602018, base: "/",
    url: url_DeleteConfigurationSet_602019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_602031 = ref object of OpenApiRestCall_601364
proc url_UpdateConfigurationSetEventDestination_602033(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_602032(path: JsonNode;
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
  var valid_602034 = path.getOrDefault("ConfigurationSetName")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = nil)
  if valid_602034 != nil:
    section.add "ConfigurationSetName", valid_602034
  var valid_602035 = path.getOrDefault("EventDestinationName")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "EventDestinationName", valid_602035
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Security-Token")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Security-Token", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602044: Call_UpdateConfigurationSetEventDestination_602031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_602044.validator(path, query, header, formData, body)
  let scheme = call_602044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602044.url(scheme.get, call_602044.host, call_602044.base,
                         call_602044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602044, url, valid)

proc call*(call_602045: Call_UpdateConfigurationSetEventDestination_602031;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  ##   body: JObject (required)
  var path_602046 = newJObject()
  var body_602047 = newJObject()
  add(path_602046, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_602046, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_602047 = body
  result = call_602045.call(path_602046, nil, nil, nil, body_602047)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_602031(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_602032, base: "/",
    url: url_UpdateConfigurationSetEventDestination_602033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_602048 = ref object of OpenApiRestCall_601364
proc url_DeleteConfigurationSetEventDestination_602050(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_602049(path: JsonNode;
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
  var valid_602051 = path.getOrDefault("ConfigurationSetName")
  valid_602051 = validateParameter(valid_602051, JString, required = true,
                                 default = nil)
  if valid_602051 != nil:
    section.add "ConfigurationSetName", valid_602051
  var valid_602052 = path.getOrDefault("EventDestinationName")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "EventDestinationName", valid_602052
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602053 = header.getOrDefault("X-Amz-Signature")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Signature", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Content-Sha256", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Date")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Date", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Security-Token")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Security-Token", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Algorithm")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Algorithm", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-SignedHeaders", valid_602059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602060: Call_DeleteConfigurationSetEventDestination_602048;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_602060.validator(path, query, header, formData, body)
  let scheme = call_602060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602060.url(scheme.get, call_602060.host, call_602060.base,
                         call_602060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602060, url, valid)

proc call*(call_602061: Call_DeleteConfigurationSetEventDestination_602048;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_602062 = newJObject()
  add(path_602062, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_602062, "EventDestinationName", newJString(EventDestinationName))
  result = call_602061.call(path_602062, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_602048(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_602049, base: "/",
    url: url_DeleteConfigurationSetEventDestination_602050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_602063 = ref object of OpenApiRestCall_601364
proc url_SendVoiceMessage_602065(protocol: Scheme; host: string; base: string;
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

proc validate_SendVoiceMessage_602064(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602074: Call_SendVoiceMessage_602063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_602074.validator(path, query, header, formData, body)
  let scheme = call_602074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602074.url(scheme.get, call_602074.host, call_602074.base,
                         call_602074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602074, url, valid)

proc call*(call_602075: Call_SendVoiceMessage_602063; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_602076 = newJObject()
  if body != nil:
    body_602076 = body
  result = call_602075.call(nil, nil, nil, nil, body_602076)

var sendVoiceMessage* = Call_SendVoiceMessage_602063(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_602064,
    base: "/", url: url_SendVoiceMessage_602065,
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
