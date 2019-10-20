
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

  OpenApiRestCall_592339 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592339](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592339): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_592935 = ref object of OpenApiRestCall_592339
proc url_CreateConfigurationSet_592937(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfigurationSet_592936(path: JsonNode; query: JsonNode;
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
  var valid_592938 = header.getOrDefault("X-Amz-Signature")
  valid_592938 = validateParameter(valid_592938, JString, required = false,
                                 default = nil)
  if valid_592938 != nil:
    section.add "X-Amz-Signature", valid_592938
  var valid_592939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592939 = validateParameter(valid_592939, JString, required = false,
                                 default = nil)
  if valid_592939 != nil:
    section.add "X-Amz-Content-Sha256", valid_592939
  var valid_592940 = header.getOrDefault("X-Amz-Date")
  valid_592940 = validateParameter(valid_592940, JString, required = false,
                                 default = nil)
  if valid_592940 != nil:
    section.add "X-Amz-Date", valid_592940
  var valid_592941 = header.getOrDefault("X-Amz-Credential")
  valid_592941 = validateParameter(valid_592941, JString, required = false,
                                 default = nil)
  if valid_592941 != nil:
    section.add "X-Amz-Credential", valid_592941
  var valid_592942 = header.getOrDefault("X-Amz-Security-Token")
  valid_592942 = validateParameter(valid_592942, JString, required = false,
                                 default = nil)
  if valid_592942 != nil:
    section.add "X-Amz-Security-Token", valid_592942
  var valid_592943 = header.getOrDefault("X-Amz-Algorithm")
  valid_592943 = validateParameter(valid_592943, JString, required = false,
                                 default = nil)
  if valid_592943 != nil:
    section.add "X-Amz-Algorithm", valid_592943
  var valid_592944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592944 = validateParameter(valid_592944, JString, required = false,
                                 default = nil)
  if valid_592944 != nil:
    section.add "X-Amz-SignedHeaders", valid_592944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592946: Call_CreateConfigurationSet_592935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_592946.validator(path, query, header, formData, body)
  let scheme = call_592946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592946.url(scheme.get, call_592946.host, call_592946.base,
                         call_592946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592946, url, valid)

proc call*(call_592947: Call_CreateConfigurationSet_592935; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_592948 = newJObject()
  if body != nil:
    body_592948 = body
  result = call_592947.call(nil, nil, nil, nil, body_592948)

var createConfigurationSet* = Call_CreateConfigurationSet_592935(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_592936, base: "/",
    url: url_CreateConfigurationSet_592937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_592678 = ref object of OpenApiRestCall_592339
proc url_ListConfigurationSets_592680(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurationSets_592679(path: JsonNode; query: JsonNode;
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
  var valid_592792 = query.getOrDefault("NextToken")
  valid_592792 = validateParameter(valid_592792, JString, required = false,
                                 default = nil)
  if valid_592792 != nil:
    section.add "NextToken", valid_592792
  var valid_592793 = query.getOrDefault("PageSize")
  valid_592793 = validateParameter(valid_592793, JString, required = false,
                                 default = nil)
  if valid_592793 != nil:
    section.add "PageSize", valid_592793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592794 = header.getOrDefault("X-Amz-Signature")
  valid_592794 = validateParameter(valid_592794, JString, required = false,
                                 default = nil)
  if valid_592794 != nil:
    section.add "X-Amz-Signature", valid_592794
  var valid_592795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592795 = validateParameter(valid_592795, JString, required = false,
                                 default = nil)
  if valid_592795 != nil:
    section.add "X-Amz-Content-Sha256", valid_592795
  var valid_592796 = header.getOrDefault("X-Amz-Date")
  valid_592796 = validateParameter(valid_592796, JString, required = false,
                                 default = nil)
  if valid_592796 != nil:
    section.add "X-Amz-Date", valid_592796
  var valid_592797 = header.getOrDefault("X-Amz-Credential")
  valid_592797 = validateParameter(valid_592797, JString, required = false,
                                 default = nil)
  if valid_592797 != nil:
    section.add "X-Amz-Credential", valid_592797
  var valid_592798 = header.getOrDefault("X-Amz-Security-Token")
  valid_592798 = validateParameter(valid_592798, JString, required = false,
                                 default = nil)
  if valid_592798 != nil:
    section.add "X-Amz-Security-Token", valid_592798
  var valid_592799 = header.getOrDefault("X-Amz-Algorithm")
  valid_592799 = validateParameter(valid_592799, JString, required = false,
                                 default = nil)
  if valid_592799 != nil:
    section.add "X-Amz-Algorithm", valid_592799
  var valid_592800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592800 = validateParameter(valid_592800, JString, required = false,
                                 default = nil)
  if valid_592800 != nil:
    section.add "X-Amz-SignedHeaders", valid_592800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592823: Call_ListConfigurationSets_592678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_592823.validator(path, query, header, formData, body)
  let scheme = call_592823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592823.url(scheme.get, call_592823.host, call_592823.base,
                         call_592823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592823, url, valid)

proc call*(call_592894: Call_ListConfigurationSets_592678; NextToken: string = "";
          PageSize: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  var query_592895 = newJObject()
  add(query_592895, "NextToken", newJString(NextToken))
  add(query_592895, "PageSize", newJString(PageSize))
  result = call_592894.call(nil, query_592895, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_592678(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_592679, base: "/",
    url: url_ListConfigurationSets_592680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_592977 = ref object of OpenApiRestCall_592339
proc url_CreateConfigurationSetEventDestination_592979(protocol: Scheme;
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

proc validate_CreateConfigurationSetEventDestination_592978(path: JsonNode;
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
  var valid_592980 = path.getOrDefault("ConfigurationSetName")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = nil)
  if valid_592980 != nil:
    section.add "ConfigurationSetName", valid_592980
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
  var valid_592981 = header.getOrDefault("X-Amz-Signature")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Signature", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Content-Sha256", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Date")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Date", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Credential")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Credential", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Security-Token")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Security-Token", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Algorithm")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Algorithm", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-SignedHeaders", valid_592987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592989: Call_CreateConfigurationSetEventDestination_592977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_592989.validator(path, query, header, formData, body)
  let scheme = call_592989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592989.url(scheme.get, call_592989.host, call_592989.base,
                         call_592989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592989, url, valid)

proc call*(call_592990: Call_CreateConfigurationSetEventDestination_592977;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_592991 = newJObject()
  var body_592992 = newJObject()
  add(path_592991, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_592992 = body
  result = call_592990.call(path_592991, nil, nil, nil, body_592992)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_592977(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_592978, base: "/",
    url: url_CreateConfigurationSetEventDestination_592979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_592949 = ref object of OpenApiRestCall_592339
proc url_GetConfigurationSetEventDestinations_592951(protocol: Scheme;
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

proc validate_GetConfigurationSetEventDestinations_592950(path: JsonNode;
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
  var valid_592966 = path.getOrDefault("ConfigurationSetName")
  valid_592966 = validateParameter(valid_592966, JString, required = true,
                                 default = nil)
  if valid_592966 != nil:
    section.add "ConfigurationSetName", valid_592966
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
  var valid_592967 = header.getOrDefault("X-Amz-Signature")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Signature", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Content-Sha256", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Date")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Date", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Credential")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Credential", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Security-Token")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Security-Token", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-Algorithm")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-Algorithm", valid_592972
  var valid_592973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-SignedHeaders", valid_592973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592974: Call_GetConfigurationSetEventDestinations_592949;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_592974.validator(path, query, header, formData, body)
  let scheme = call_592974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592974.url(scheme.get, call_592974.host, call_592974.base,
                         call_592974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592974, url, valid)

proc call*(call_592975: Call_GetConfigurationSetEventDestinations_592949;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_592976 = newJObject()
  add(path_592976, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_592975.call(path_592976, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_592949(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_592950, base: "/",
    url: url_GetConfigurationSetEventDestinations_592951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_592993 = ref object of OpenApiRestCall_592339
proc url_DeleteConfigurationSet_592995(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConfigurationSet_592994(path: JsonNode; query: JsonNode;
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
  var valid_592996 = path.getOrDefault("ConfigurationSetName")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = nil)
  if valid_592996 != nil:
    section.add "ConfigurationSetName", valid_592996
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
  var valid_592997 = header.getOrDefault("X-Amz-Signature")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Signature", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Content-Sha256", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Date")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Date", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Credential")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Credential", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Security-Token")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Security-Token", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Algorithm")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Algorithm", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-SignedHeaders", valid_593003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_DeleteConfigurationSet_592993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_DeleteConfigurationSet_592993;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_593006 = newJObject()
  add(path_593006, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_593005.call(path_593006, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_592993(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_592994, base: "/",
    url: url_DeleteConfigurationSet_592995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_593007 = ref object of OpenApiRestCall_592339
proc url_UpdateConfigurationSetEventDestination_593009(protocol: Scheme;
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

proc validate_UpdateConfigurationSetEventDestination_593008(path: JsonNode;
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
  var valid_593010 = path.getOrDefault("ConfigurationSetName")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = nil)
  if valid_593010 != nil:
    section.add "ConfigurationSetName", valid_593010
  var valid_593011 = path.getOrDefault("EventDestinationName")
  valid_593011 = validateParameter(valid_593011, JString, required = true,
                                 default = nil)
  if valid_593011 != nil:
    section.add "EventDestinationName", valid_593011
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
  var valid_593012 = header.getOrDefault("X-Amz-Signature")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Signature", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Content-Sha256", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Date")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Date", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Credential")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Credential", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Security-Token")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Security-Token", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Algorithm")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Algorithm", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-SignedHeaders", valid_593018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593020: Call_UpdateConfigurationSetEventDestination_593007;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_593020.validator(path, query, header, formData, body)
  let scheme = call_593020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593020.url(scheme.get, call_593020.host, call_593020.base,
                         call_593020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593020, url, valid)

proc call*(call_593021: Call_UpdateConfigurationSetEventDestination_593007;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  ##   body: JObject (required)
  var path_593022 = newJObject()
  var body_593023 = newJObject()
  add(path_593022, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_593022, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_593023 = body
  result = call_593021.call(path_593022, nil, nil, nil, body_593023)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_593007(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_593008, base: "/",
    url: url_UpdateConfigurationSetEventDestination_593009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_593024 = ref object of OpenApiRestCall_592339
proc url_DeleteConfigurationSetEventDestination_593026(protocol: Scheme;
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

proc validate_DeleteConfigurationSetEventDestination_593025(path: JsonNode;
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
  var valid_593027 = path.getOrDefault("ConfigurationSetName")
  valid_593027 = validateParameter(valid_593027, JString, required = true,
                                 default = nil)
  if valid_593027 != nil:
    section.add "ConfigurationSetName", valid_593027
  var valid_593028 = path.getOrDefault("EventDestinationName")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "EventDestinationName", valid_593028
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
  var valid_593029 = header.getOrDefault("X-Amz-Signature")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Signature", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Content-Sha256", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Date")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Date", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Credential")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Credential", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Security-Token")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Security-Token", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Algorithm")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Algorithm", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-SignedHeaders", valid_593035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593036: Call_DeleteConfigurationSetEventDestination_593024;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_593036.validator(path, query, header, formData, body)
  let scheme = call_593036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593036.url(scheme.get, call_593036.host, call_593036.base,
                         call_593036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593036, url, valid)

proc call*(call_593037: Call_DeleteConfigurationSetEventDestination_593024;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_593038 = newJObject()
  add(path_593038, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_593038, "EventDestinationName", newJString(EventDestinationName))
  result = call_593037.call(path_593038, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_593024(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_593025, base: "/",
    url: url_DeleteConfigurationSetEventDestination_593026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_593039 = ref object of OpenApiRestCall_592339
proc url_SendVoiceMessage_593041(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendVoiceMessage_593040(path: JsonNode; query: JsonNode;
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
  var valid_593042 = header.getOrDefault("X-Amz-Signature")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Signature", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Content-Sha256", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Date")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Date", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Credential")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Credential", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Security-Token")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Security-Token", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Algorithm")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Algorithm", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-SignedHeaders", valid_593048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593050: Call_SendVoiceMessage_593039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_593050.validator(path, query, header, formData, body)
  let scheme = call_593050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593050.url(scheme.get, call_593050.host, call_593050.base,
                         call_593050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593050, url, valid)

proc call*(call_593051: Call_SendVoiceMessage_593039; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_593052 = newJObject()
  if body != nil:
    body_593052 = body
  result = call_593051.call(nil, nil, nil, nil, body_593052)

var sendVoiceMessage* = Call_SendVoiceMessage_593039(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_593040,
    base: "/", url: url_SendVoiceMessage_593041,
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
