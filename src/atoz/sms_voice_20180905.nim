
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625409 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625409](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625409): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateConfigurationSet_21625993 = ref object of OpenApiRestCall_21625409
proc url_CreateConfigurationSet_21625995(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_21625994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625996 = header.getOrDefault("X-Amz-Date")
  valid_21625996 = validateParameter(valid_21625996, JString, required = false,
                                   default = nil)
  if valid_21625996 != nil:
    section.add "X-Amz-Date", valid_21625996
  var valid_21625997 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625997 = validateParameter(valid_21625997, JString, required = false,
                                   default = nil)
  if valid_21625997 != nil:
    section.add "X-Amz-Security-Token", valid_21625997
  var valid_21625998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625998 = validateParameter(valid_21625998, JString, required = false,
                                   default = nil)
  if valid_21625998 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625998
  var valid_21625999 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625999 = validateParameter(valid_21625999, JString, required = false,
                                   default = nil)
  if valid_21625999 != nil:
    section.add "X-Amz-Algorithm", valid_21625999
  var valid_21626000 = header.getOrDefault("X-Amz-Signature")
  valid_21626000 = validateParameter(valid_21626000, JString, required = false,
                                   default = nil)
  if valid_21626000 != nil:
    section.add "X-Amz-Signature", valid_21626000
  var valid_21626001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626001 = validateParameter(valid_21626001, JString, required = false,
                                   default = nil)
  if valid_21626001 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626001
  var valid_21626002 = header.getOrDefault("X-Amz-Credential")
  valid_21626002 = validateParameter(valid_21626002, JString, required = false,
                                   default = nil)
  if valid_21626002 != nil:
    section.add "X-Amz-Credential", valid_21626002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626004: Call_CreateConfigurationSet_21625993;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ## 
  let valid = call_21626004.validator(path, query, header, formData, body, _)
  let scheme = call_21626004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626004.makeUrl(scheme.get, call_21626004.host, call_21626004.base,
                               call_21626004.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626004, uri, valid, _)

proc call*(call_21626005: Call_CreateConfigurationSet_21625993; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   body: JObject (required)
  var body_21626006 = newJObject()
  if body != nil:
    body_21626006 = body
  result = call_21626005.call(nil, nil, nil, nil, body_21626006)

var createConfigurationSet* = Call_CreateConfigurationSet_21625993(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_21625994, base: "/",
    makeUrl: url_CreateConfigurationSet_21625995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_21625753 = ref object of OpenApiRestCall_21625409
proc url_ListConfigurationSets_21625755(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_21625754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625856 = query.getOrDefault("PageSize")
  valid_21625856 = validateParameter(valid_21625856, JString, required = false,
                                   default = nil)
  if valid_21625856 != nil:
    section.add "PageSize", valid_21625856
  var valid_21625857 = query.getOrDefault("NextToken")
  valid_21625857 = validateParameter(valid_21625857, JString, required = false,
                                   default = nil)
  if valid_21625857 != nil:
    section.add "NextToken", valid_21625857
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
  var valid_21625858 = header.getOrDefault("X-Amz-Date")
  valid_21625858 = validateParameter(valid_21625858, JString, required = false,
                                   default = nil)
  if valid_21625858 != nil:
    section.add "X-Amz-Date", valid_21625858
  var valid_21625859 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625859 = validateParameter(valid_21625859, JString, required = false,
                                   default = nil)
  if valid_21625859 != nil:
    section.add "X-Amz-Security-Token", valid_21625859
  var valid_21625860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625860 = validateParameter(valid_21625860, JString, required = false,
                                   default = nil)
  if valid_21625860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625860
  var valid_21625861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625861 = validateParameter(valid_21625861, JString, required = false,
                                   default = nil)
  if valid_21625861 != nil:
    section.add "X-Amz-Algorithm", valid_21625861
  var valid_21625862 = header.getOrDefault("X-Amz-Signature")
  valid_21625862 = validateParameter(valid_21625862, JString, required = false,
                                   default = nil)
  if valid_21625862 != nil:
    section.add "X-Amz-Signature", valid_21625862
  var valid_21625863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625863 = validateParameter(valid_21625863, JString, required = false,
                                   default = nil)
  if valid_21625863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625863
  var valid_21625864 = header.getOrDefault("X-Amz-Credential")
  valid_21625864 = validateParameter(valid_21625864, JString, required = false,
                                   default = nil)
  if valid_21625864 != nil:
    section.add "X-Amz-Credential", valid_21625864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625889: Call_ListConfigurationSets_21625753;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ## 
  let valid = call_21625889.validator(path, query, header, formData, body, _)
  let scheme = call_21625889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625889.makeUrl(scheme.get, call_21625889.host, call_21625889.base,
                               call_21625889.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625889, uri, valid, _)

proc call*(call_21625952: Call_ListConfigurationSets_21625753;
          PageSize: string = ""; NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   PageSize: string
  ##           : Used to specify the number of items that should be returned in the response.
  ##   NextToken: string
  ##            : A token returned from a previous call to the API that indicates the position in the list of results.
  var query_21625954 = newJObject()
  add(query_21625954, "PageSize", newJString(PageSize))
  add(query_21625954, "NextToken", newJString(NextToken))
  result = call_21625952.call(nil, query_21625954, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_21625753(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_21625754, base: "/",
    makeUrl: url_ListConfigurationSets_21625755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_21626034 = ref object of OpenApiRestCall_21625409
proc url_CreateConfigurationSetEventDestination_21626036(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_21626035(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new event destination in a configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626037 = path.getOrDefault("ConfigurationSetName")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "ConfigurationSetName", valid_21626037
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
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626046: Call_CreateConfigurationSetEventDestination_21626034;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new event destination in a configuration set.
  ## 
  let valid = call_21626046.validator(path, query, header, formData, body, _)
  let scheme = call_21626046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626046.makeUrl(scheme.get, call_21626046.host, call_21626046.base,
                               call_21626046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626046, uri, valid, _)

proc call*(call_21626047: Call_CreateConfigurationSetEventDestination_21626034;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  var path_21626048 = newJObject()
  var body_21626049 = newJObject()
  add(path_21626048, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626049 = body
  result = call_21626047.call(path_21626048, nil, nil, nil, body_21626049)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_21626034(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_21626035,
    base: "/", makeUrl: url_CreateConfigurationSetEventDestination_21626036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_21626007 = ref object of OpenApiRestCall_21625409
proc url_GetConfigurationSetEventDestinations_21626009(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_21626008(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626023 = path.getOrDefault("ConfigurationSetName")
  valid_21626023 = validateParameter(valid_21626023, JString, required = true,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "ConfigurationSetName", valid_21626023
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
  var valid_21626024 = header.getOrDefault("X-Amz-Date")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Date", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Security-Token", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626031: Call_GetConfigurationSetEventDestinations_21626007;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ## 
  let valid = call_21626031.validator(path, query, header, formData, body, _)
  let scheme = call_21626031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626031.makeUrl(scheme.get, call_21626031.host, call_21626031.base,
                               call_21626031.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626031, uri, valid, _)

proc call*(call_21626032: Call_GetConfigurationSetEventDestinations_21626007;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_21626033 = newJObject()
  add(path_21626033, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_21626032.call(path_21626033, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_21626007(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_21626008, base: "/",
    makeUrl: url_GetConfigurationSetEventDestinations_21626009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_21626050 = ref object of OpenApiRestCall_21625409
proc url_DeleteConfigurationSet_21626052(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_21626051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626053 = path.getOrDefault("ConfigurationSetName")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "ConfigurationSetName", valid_21626053
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
  var valid_21626054 = header.getOrDefault("X-Amz-Date")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Date", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Security-Token", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626061: Call_DeleteConfigurationSet_21626050;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing configuration set.
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_DeleteConfigurationSet_21626050;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  var path_21626063 = newJObject()
  add(path_21626063, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_21626062.call(path_21626063, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_21626050(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_21626051, base: "/",
    makeUrl: url_DeleteConfigurationSet_21626052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_21626064 = ref object of OpenApiRestCall_21625409
proc url_UpdateConfigurationSetEventDestination_21626066(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_21626065(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626067 = path.getOrDefault("ConfigurationSetName")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "ConfigurationSetName", valid_21626067
  var valid_21626068 = path.getOrDefault("EventDestinationName")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "EventDestinationName", valid_21626068
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
  var valid_21626069 = header.getOrDefault("X-Amz-Date")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Date", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Security-Token", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626077: Call_UpdateConfigurationSetEventDestination_21626064;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_UpdateConfigurationSetEventDestination_21626064;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_21626079 = newJObject()
  var body_21626080 = newJObject()
  add(path_21626079, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626080 = body
  add(path_21626079, "EventDestinationName", newJString(EventDestinationName))
  result = call_21626078.call(path_21626079, nil, nil, nil, body_21626080)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_21626064(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_21626065,
    base: "/", makeUrl: url_UpdateConfigurationSetEventDestination_21626066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_21626081 = ref object of OpenApiRestCall_21625409
proc url_DeleteConfigurationSetEventDestination_21626083(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_21626082(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626084 = path.getOrDefault("ConfigurationSetName")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "ConfigurationSetName", valid_21626084
  var valid_21626085 = path.getOrDefault("EventDestinationName")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "EventDestinationName", valid_21626085
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
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626093: Call_DeleteConfigurationSetEventDestination_21626081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an event destination in a configuration set.
  ## 
  let valid = call_21626093.validator(path, query, header, formData, body, _)
  let scheme = call_21626093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626093.makeUrl(scheme.get, call_21626093.host, call_21626093.base,
                               call_21626093.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626093, uri, valid, _)

proc call*(call_21626094: Call_DeleteConfigurationSetEventDestination_21626081;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : ConfigurationSetName
  ##   EventDestinationName: string (required)
  ##                       : EventDestinationName
  var path_21626095 = newJObject()
  add(path_21626095, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_21626095, "EventDestinationName", newJString(EventDestinationName))
  result = call_21626094.call(path_21626095, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_21626081(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_21626082,
    base: "/", makeUrl: url_DeleteConfigurationSetEventDestination_21626083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_21626096 = ref object of OpenApiRestCall_21625409
proc url_SendVoiceMessage_21626098(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendVoiceMessage_21626097(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626099 = header.getOrDefault("X-Amz-Date")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Date", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Security-Token", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Algorithm", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Signature")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Signature", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Credential")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Credential", valid_21626105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_SendVoiceMessage_21626096; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_SendVoiceMessage_21626096; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: JObject (required)
  var body_21626109 = newJObject()
  if body != nil:
    body_21626109 = body
  result = call_21626108.call(nil, nil, nil, nil, body_21626109)

var sendVoiceMessage* = Call_SendVoiceMessage_21626096(name: "sendVoiceMessage",
    meth: HttpMethod.HttpPost, host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_21626097,
    base: "/", makeUrl: url_SendVoiceMessage_21626098,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}