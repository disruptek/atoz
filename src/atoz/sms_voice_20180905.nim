
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

  OpenApiRestCall_599343 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599343](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599343): Option[Scheme] {.used.} =
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
  Call_CreateConfigurationSet_599937 = ref object of OpenApiRestCall_599343
proc url_CreateConfigurationSet_599939(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_599938(path: JsonNode; query: JsonNode;
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
  var valid_599940 = header.getOrDefault("X-Amz-Date")
  valid_599940 = validateParameter(valid_599940, JString, required = false,
                                 default = nil)
  if valid_599940 != nil:
    section.add "X-Amz-Date", valid_599940
  var valid_599941 = header.getOrDefault("X-Amz-Security-Token")
  valid_599941 = validateParameter(valid_599941, JString, required = false,
                                 default = nil)
  if valid_599941 != nil:
    section.add "X-Amz-Security-Token", valid_599941
  var valid_599942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599942 = validateParameter(valid_599942, JString, required = false,
                                 default = nil)
  if valid_599942 != nil:
    section.add "X-Amz-Content-Sha256", valid_599942
  var valid_599943 = header.getOrDefault("X-Amz-Algorithm")
  valid_599943 = validateParameter(valid_599943, JString, required = false,
                                 default = nil)
  if valid_599943 != nil:
    section.add "X-Amz-Algorithm", valid_599943
  var valid_599944 = header.getOrDefault("X-Amz-Signature")
  valid_599944 = validateParameter(valid_599944, JString, required = false,
                                 default = nil)
  if valid_599944 != nil:
    section.add "X-Amz-Signature", valid_599944
  var valid_599945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599945 = validateParameter(valid_599945, JString, required = false,
                                 default = nil)
  if valid_599945 != nil:
    section.add "X-Amz-SignedHeaders", valid_599945
  var valid_599946 = header.getOrDefault("X-Amz-Credential")
  valid_599946 = validateParameter(valid_599946, JString, required = false,
                                 default = nil)
  if valid_599946 != nil:
    section.add "X-Amz-Credential", valid_599946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599948: Call_CreateConfigurationSet_599937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_599948.validator(path, query, header, formData, body)
  let scheme = call_599948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599948.url(scheme.get, call_599948.host, call_599948.base,
                         call_599948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599948, url, valid)

proc call*(call_599949: Call_CreateConfigurationSet_599937; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_599950 = newJObject()
  if body != nil:
    body_599950 = body
  result = call_599949.call(nil, nil, nil, nil, body_599950)

var createConfigurationSet* = Call_CreateConfigurationSet_599937(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_599938, base: "/",
    url: url_CreateConfigurationSet_599939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_599680 = ref object of OpenApiRestCall_599343
proc url_ListConfigurationSets_599682(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_599681(path: JsonNode; query: JsonNode;
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
  var valid_599794 = query.getOrDefault("PageSize")
  valid_599794 = validateParameter(valid_599794, JString, required = false,
                                 default = nil)
  if valid_599794 != nil:
    section.add "PageSize", valid_599794
  var valid_599795 = query.getOrDefault("NextToken")
  valid_599795 = validateParameter(valid_599795, JString, required = false,
                                 default = nil)
  if valid_599795 != nil:
    section.add "NextToken", valid_599795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599796 = header.getOrDefault("X-Amz-Date")
  valid_599796 = validateParameter(valid_599796, JString, required = false,
                                 default = nil)
  if valid_599796 != nil:
    section.add "X-Amz-Date", valid_599796
  var valid_599797 = header.getOrDefault("X-Amz-Security-Token")
  valid_599797 = validateParameter(valid_599797, JString, required = false,
                                 default = nil)
  if valid_599797 != nil:
    section.add "X-Amz-Security-Token", valid_599797
  var valid_599798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599798 = validateParameter(valid_599798, JString, required = false,
                                 default = nil)
  if valid_599798 != nil:
    section.add "X-Amz-Content-Sha256", valid_599798
  var valid_599799 = header.getOrDefault("X-Amz-Algorithm")
  valid_599799 = validateParameter(valid_599799, JString, required = false,
                                 default = nil)
  if valid_599799 != nil:
    section.add "X-Amz-Algorithm", valid_599799
  var valid_599800 = header.getOrDefault("X-Amz-Signature")
  valid_599800 = validateParameter(valid_599800, JString, required = false,
                                 default = nil)
  if valid_599800 != nil:
    section.add "X-Amz-Signature", valid_599800
  var valid_599801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599801 = validateParameter(valid_599801, JString, required = false,
                                 default = nil)
  if valid_599801 != nil:
    section.add "X-Amz-SignedHeaders", valid_599801
  var valid_599802 = header.getOrDefault("X-Amz-Credential")
  valid_599802 = validateParameter(valid_599802, JString, required = false,
                                 default = nil)
  if valid_599802 != nil:
    section.add "X-Amz-Credential", valid_599802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599825: Call_ListConfigurationSets_599680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_599825.validator(path, query, header, formData, body)
  let scheme = call_599825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599825.url(scheme.get, call_599825.host, call_599825.base,
                         call_599825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599825, url, valid)

proc call*(call_599896: Call_ListConfigurationSets_599680; PageSize: string = "";
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  var query_599897 = newJObject()
  add(query_599897, "PageSize", newJString(PageSize))
  add(query_599897, "NextToken", newJString(NextToken))
  result = call_599896.call(nil, query_599897, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_599680(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_599681, base: "/",
    url: url_ListConfigurationSets_599682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_599979 = ref object of OpenApiRestCall_599343
proc url_CreateConfigurationSetEventDestination_599981(protocol: Scheme;
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

proc validate_CreateConfigurationSetEventDestination_599980(path: JsonNode;
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
  var valid_599982 = path.getOrDefault("ConfigurationSetName")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = nil)
  if valid_599982 != nil:
    section.add "ConfigurationSetName", valid_599982
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Content-Sha256", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Algorithm")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Algorithm", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Signature")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Signature", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-SignedHeaders", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Credential")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Credential", valid_599989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599991: Call_CreateConfigurationSetEventDestination_599979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_599991.validator(path, query, header, formData, body)
  let scheme = call_599991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599991.url(scheme.get, call_599991.host, call_599991.base,
                         call_599991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599991, url, valid)

proc call*(call_599992: Call_CreateConfigurationSetEventDestination_599979;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_599993 = newJObject()
  var body_599994 = newJObject()
  add(path_599993, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_599994 = body
  result = call_599992.call(path_599993, nil, nil, nil, body_599994)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_599979(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_599980, base: "/",
    url: url_CreateConfigurationSetEventDestination_599981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_599951 = ref object of OpenApiRestCall_599343
proc url_GetConfigurationSetEventDestinations_599953(protocol: Scheme;
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

proc validate_GetConfigurationSetEventDestinations_599952(path: JsonNode;
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
  var valid_599968 = path.getOrDefault("ConfigurationSetName")
  valid_599968 = validateParameter(valid_599968, JString, required = true,
                                 default = nil)
  if valid_599968 != nil:
    section.add "ConfigurationSetName", valid_599968
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599969 = header.getOrDefault("X-Amz-Date")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Date", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Security-Token")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Security-Token", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Content-Sha256", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Algorithm")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Algorithm", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Signature")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Signature", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-SignedHeaders", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Credential")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Credential", valid_599975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599976: Call_GetConfigurationSetEventDestinations_599951;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_599976.validator(path, query, header, formData, body)
  let scheme = call_599976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599976.url(scheme.get, call_599976.host, call_599976.base,
                         call_599976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599976, url, valid)

proc call*(call_599977: Call_GetConfigurationSetEventDestinations_599951;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_599978 = newJObject()
  add(path_599978, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_599977.call(path_599978, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_599951(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_599952, base: "/",
    url: url_GetConfigurationSetEventDestinations_599953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_599995 = ref object of OpenApiRestCall_599343
proc url_DeleteConfigurationSet_599997(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConfigurationSet_599996(path: JsonNode; query: JsonNode;
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
  var valid_599998 = path.getOrDefault("ConfigurationSetName")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = nil)
  if valid_599998 != nil:
    section.add "ConfigurationSetName", valid_599998
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599999 = header.getOrDefault("X-Amz-Date")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Date", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Security-Token")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Security-Token", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Content-Sha256", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Algorithm")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Algorithm", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Signature")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Signature", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-SignedHeaders", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_DeleteConfigurationSet_599995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_DeleteConfigurationSet_599995;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_600008 = newJObject()
  add(path_600008, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_600007.call(path_600008, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_599995(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_599996, base: "/",
    url: url_DeleteConfigurationSet_599997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_600009 = ref object of OpenApiRestCall_599343
proc url_UpdateConfigurationSetEventDestination_600011(protocol: Scheme;
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

proc validate_UpdateConfigurationSetEventDestination_600010(path: JsonNode;
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
  var valid_600012 = path.getOrDefault("ConfigurationSetName")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = nil)
  if valid_600012 != nil:
    section.add "ConfigurationSetName", valid_600012
  var valid_600013 = path.getOrDefault("EventDestinationName")
  valid_600013 = validateParameter(valid_600013, JString, required = true,
                                 default = nil)
  if valid_600013 != nil:
    section.add "EventDestinationName", valid_600013
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600014 = header.getOrDefault("X-Amz-Date")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Date", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Security-Token")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Security-Token", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Content-Sha256", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Algorithm")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Algorithm", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Signature")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Signature", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-SignedHeaders", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Credential")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Credential", valid_600020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600022: Call_UpdateConfigurationSetEventDestination_600009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_600022.validator(path, query, header, formData, body)
  let scheme = call_600022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600022.url(scheme.get, call_600022.host, call_600022.base,
                         call_600022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600022, url, valid)

proc call*(call_600023: Call_UpdateConfigurationSetEventDestination_600009;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_600024 = newJObject()
  var body_600025 = newJObject()
  add(path_600024, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_600025 = body
  add(path_600024, "EventDestinationName", newJString(EventDestinationName))
  result = call_600023.call(path_600024, nil, nil, nil, body_600025)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_600009(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_600010, base: "/",
    url: url_UpdateConfigurationSetEventDestination_600011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_600026 = ref object of OpenApiRestCall_599343
proc url_DeleteConfigurationSetEventDestination_600028(protocol: Scheme;
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

proc validate_DeleteConfigurationSetEventDestination_600027(path: JsonNode;
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
  var valid_600029 = path.getOrDefault("ConfigurationSetName")
  valid_600029 = validateParameter(valid_600029, JString, required = true,
                                 default = nil)
  if valid_600029 != nil:
    section.add "ConfigurationSetName", valid_600029
  var valid_600030 = path.getOrDefault("EventDestinationName")
  valid_600030 = validateParameter(valid_600030, JString, required = true,
                                 default = nil)
  if valid_600030 != nil:
    section.add "EventDestinationName", valid_600030
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600038: Call_DeleteConfigurationSetEventDestination_600026;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_600038.validator(path, query, header, formData, body)
  let scheme = call_600038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600038.url(scheme.get, call_600038.host, call_600038.base,
                         call_600038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600038, url, valid)

proc call*(call_600039: Call_DeleteConfigurationSetEventDestination_600026;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_600040 = newJObject()
  add(path_600040, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_600040, "EventDestinationName", newJString(EventDestinationName))
  result = call_600039.call(path_600040, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_600026(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_600027, base: "/",
    url: url_DeleteConfigurationSetEventDestination_600028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_600041 = ref object of OpenApiRestCall_599343
proc url_SendVoiceMessage_600043(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendVoiceMessage_600042(path: JsonNode; query: JsonNode;
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
  var valid_600044 = header.getOrDefault("X-Amz-Date")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Date", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Security-Token")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Security-Token", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Content-Sha256", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Algorithm")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Algorithm", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Signature")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Signature", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-SignedHeaders", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Credential")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Credential", valid_600050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600052: Call_SendVoiceMessage_600041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_600052.validator(path, query, header, formData, body)
  let scheme = call_600052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600052.url(scheme.get, call_600052.host, call_600052.base,
                         call_600052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600052, url, valid)

proc call*(call_600053: Call_SendVoiceMessage_600041; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_600054 = newJObject()
  if body != nil:
    body_600054 = body
  result = call_600053.call(nil, nil, nil, nil, body_600054)

var sendVoiceMessage* = Call_SendVoiceMessage_600041(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_600042,
    base: "/", url: url_SendVoiceMessage_600043,
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
