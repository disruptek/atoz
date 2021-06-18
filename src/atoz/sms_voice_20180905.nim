
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656029 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656029](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656029): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "sms-voice.pinpoint.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sms-voice.pinpoint.ap-southeast-1.amazonaws.com", "us-west-2": "sms-voice.pinpoint.us-west-2.amazonaws.com", "eu-west-2": "sms-voice.pinpoint.eu-west-2.amazonaws.com", "ap-northeast-3": "sms-voice.pinpoint.ap-northeast-3.amazonaws.com", "eu-central-1": "sms-voice.pinpoint.eu-central-1.amazonaws.com", "us-east-2": "sms-voice.pinpoint.us-east-2.amazonaws.com", "us-east-1": "sms-voice.pinpoint.us-east-1.amazonaws.com", "cn-northwest-1": "sms-voice.pinpoint.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "sms-voice.pinpoint.ap-south-1.amazonaws.com", "eu-north-1": "sms-voice.pinpoint.eu-north-1.amazonaws.com", "ap-northeast-2": "sms-voice.pinpoint.ap-northeast-2.amazonaws.com", "us-west-1": "sms-voice.pinpoint.us-west-1.amazonaws.com", "us-gov-east-1": "sms-voice.pinpoint.us-gov-east-1.amazonaws.com", "eu-west-3": "sms-voice.pinpoint.eu-west-3.amazonaws.com", "cn-north-1": "sms-voice.pinpoint.cn-north-1.amazonaws.com.cn", "sa-east-1": "sms-voice.pinpoint.sa-east-1.amazonaws.com", "eu-west-1": "sms-voice.pinpoint.eu-west-1.amazonaws.com", "us-gov-west-1": "sms-voice.pinpoint.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sms-voice.pinpoint.ap-southeast-2.amazonaws.com", "ca-central-1": "sms-voice.pinpoint.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateConfigurationSet_402656462 = ref object of OpenApiRestCall_402656029
proc url_CreateConfigurationSet_402656464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_402656463(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656465 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656465 = validateParameter(valid_402656465, JString,
                                      required = false, default = nil)
  if valid_402656465 != nil:
    section.add "X-Amz-Security-Token", valid_402656465
  var valid_402656466 = header.getOrDefault("X-Amz-Signature")
  valid_402656466 = validateParameter(valid_402656466, JString,
                                      required = false, default = nil)
  if valid_402656466 != nil:
    section.add "X-Amz-Signature", valid_402656466
  var valid_402656467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656467 = validateParameter(valid_402656467, JString,
                                      required = false, default = nil)
  if valid_402656467 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656467
  var valid_402656468 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656468 = validateParameter(valid_402656468, JString,
                                      required = false, default = nil)
  if valid_402656468 != nil:
    section.add "X-Amz-Algorithm", valid_402656468
  var valid_402656469 = header.getOrDefault("X-Amz-Date")
  valid_402656469 = validateParameter(valid_402656469, JString,
                                      required = false, default = nil)
  if valid_402656469 != nil:
    section.add "X-Amz-Date", valid_402656469
  var valid_402656470 = header.getOrDefault("X-Amz-Credential")
  valid_402656470 = validateParameter(valid_402656470, JString,
                                      required = false, default = nil)
  if valid_402656470 != nil:
    section.add "X-Amz-Credential", valid_402656470
  var valid_402656471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656471 = validateParameter(valid_402656471, JString,
                                      required = false, default = nil)
  if valid_402656471 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656471
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

proc call*(call_402656473: Call_CreateConfigurationSet_402656462;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
                                                                                         ## 
  let valid = call_402656473.validator(path, query, header, formData, body, _)
  let scheme = call_402656473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656473.makeUrl(scheme.get, call_402656473.host, call_402656473.base,
                                   call_402656473.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656473, uri, valid, _)

proc call*(call_402656474: Call_CreateConfigurationSet_402656462; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
  ##   
                                                                                                                              ## body: JObject (required)
  var body_402656475 = newJObject()
  if body != nil:
    body_402656475 = body
  result = call_402656474.call(nil, nil, nil, nil, body_402656475)

var createConfigurationSet* = Call_CreateConfigurationSet_402656462(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_CreateConfigurationSet_402656463, base: "/",
    makeUrl: url_CreateConfigurationSet_402656464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_402656279 = ref object of OpenApiRestCall_402656029
proc url_ListConfigurationSets_402656281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_402656280(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                             ## NextToken: JString
                                                                                                                             ##            
                                                                                                                             ## : 
                                                                                                                             ## A 
                                                                                                                             ## token 
                                                                                                                             ## returned 
                                                                                                                             ## from 
                                                                                                                             ## a 
                                                                                                                             ## previous 
                                                                                                                             ## call 
                                                                                                                             ## to 
                                                                                                                             ## the 
                                                                                                                             ## API 
                                                                                                                             ## that 
                                                                                                                             ## indicates 
                                                                                                                             ## the 
                                                                                                                             ## position 
                                                                                                                             ## in 
                                                                                                                             ## the 
                                                                                                                             ## list 
                                                                                                                             ## of 
                                                                                                                             ## results.
  section = newJObject()
  var valid_402656360 = query.getOrDefault("PageSize")
  valid_402656360 = validateParameter(valid_402656360, JString,
                                      required = false, default = nil)
  if valid_402656360 != nil:
    section.add "PageSize", valid_402656360
  var valid_402656361 = query.getOrDefault("NextToken")
  valid_402656361 = validateParameter(valid_402656361, JString,
                                      required = false, default = nil)
  if valid_402656361 != nil:
    section.add "NextToken", valid_402656361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656362 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656362 = validateParameter(valid_402656362, JString,
                                      required = false, default = nil)
  if valid_402656362 != nil:
    section.add "X-Amz-Security-Token", valid_402656362
  var valid_402656363 = header.getOrDefault("X-Amz-Signature")
  valid_402656363 = validateParameter(valid_402656363, JString,
                                      required = false, default = nil)
  if valid_402656363 != nil:
    section.add "X-Amz-Signature", valid_402656363
  var valid_402656364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656364 = validateParameter(valid_402656364, JString,
                                      required = false, default = nil)
  if valid_402656364 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656364
  var valid_402656365 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656365 = validateParameter(valid_402656365, JString,
                                      required = false, default = nil)
  if valid_402656365 != nil:
    section.add "X-Amz-Algorithm", valid_402656365
  var valid_402656366 = header.getOrDefault("X-Amz-Date")
  valid_402656366 = validateParameter(valid_402656366, JString,
                                      required = false, default = nil)
  if valid_402656366 != nil:
    section.add "X-Amz-Date", valid_402656366
  var valid_402656367 = header.getOrDefault("X-Amz-Credential")
  valid_402656367 = validateParameter(valid_402656367, JString,
                                      required = false, default = nil)
  if valid_402656367 != nil:
    section.add "X-Amz-Credential", valid_402656367
  var valid_402656368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656368 = validateParameter(valid_402656368, JString,
                                      required = false, default = nil)
  if valid_402656368 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656382: Call_ListConfigurationSets_402656279;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
                                                                                         ## 
  let valid = call_402656382.validator(path, query, header, formData, body, _)
  let scheme = call_402656382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656382.makeUrl(scheme.get, call_402656382.host, call_402656382.base,
                                   call_402656382.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656382, uri, valid, _)

proc call*(call_402656431: Call_ListConfigurationSets_402656279;
           PageSize: string = ""; NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
  ##   
                                                                                                           ## PageSize: string
                                                                                                           ##           
                                                                                                           ## : 
                                                                                                           ## Used 
                                                                                                           ## to 
                                                                                                           ## specify 
                                                                                                           ## the 
                                                                                                           ## number 
                                                                                                           ## of 
                                                                                                           ## items 
                                                                                                           ## that 
                                                                                                           ## should 
                                                                                                           ## be 
                                                                                                           ## returned 
                                                                                                           ## in 
                                                                                                           ## the 
                                                                                                           ## response.
  ##   
                                                                                                                       ## NextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## A 
                                                                                                                       ## token 
                                                                                                                       ## returned 
                                                                                                                       ## from 
                                                                                                                       ## a 
                                                                                                                       ## previous 
                                                                                                                       ## call 
                                                                                                                       ## to 
                                                                                                                       ## the 
                                                                                                                       ## API 
                                                                                                                       ## that 
                                                                                                                       ## indicates 
                                                                                                                       ## the 
                                                                                                                       ## position 
                                                                                                                       ## in 
                                                                                                                       ## the 
                                                                                                                       ## list 
                                                                                                                       ## of 
                                                                                                                       ## results.
  var query_402656432 = newJObject()
  add(query_402656432, "PageSize", newJString(PageSize))
  add(query_402656432, "NextToken", newJString(NextToken))
  result = call_402656431.call(nil, query_402656432, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_402656279(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets",
    validator: validate_ListConfigurationSets_402656280, base: "/",
    makeUrl: url_ListConfigurationSets_402656281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_402656501 = ref object of OpenApiRestCall_402656029
proc url_CreateConfigurationSetEventDestination_402656503(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/sms-voice/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_402656502(path: JsonNode;
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
  var valid_402656504 = path.getOrDefault("ConfigurationSetName")
  valid_402656504 = validateParameter(valid_402656504, JString, required = true,
                                      default = nil)
  if valid_402656504 != nil:
    section.add "ConfigurationSetName", valid_402656504
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656505 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Security-Token", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Signature")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Signature", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Algorithm", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Date")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Date", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Credential")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Credential", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656511
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

proc call*(call_402656513: Call_CreateConfigurationSetEventDestination_402656501;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new event destination in a configuration set.
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_CreateConfigurationSetEventDestination_402656501;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## Create a new event destination in a configuration set.
  ##   ConfigurationSetName: string (required)
                                                           ##                       : ConfigurationSetName
  ##   
                                                                                                          ## body: JObject (required)
  var path_402656515 = newJObject()
  var body_402656516 = newJObject()
  add(path_402656515, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656516 = body
  result = call_402656514.call(path_402656515, nil, nil, nil, body_402656516)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_402656501(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_402656502,
    base: "/", makeUrl: url_CreateConfigurationSetEventDestination_402656503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_402656476 = ref object of OpenApiRestCall_402656029
proc url_GetConfigurationSetEventDestinations_402656478(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/sms-voice/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_402656477(path: JsonNode;
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
  var valid_402656490 = path.getOrDefault("ConfigurationSetName")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "ConfigurationSetName", valid_402656490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_GetConfigurationSetEventDestinations_402656476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_GetConfigurationSetEventDestinations_402656476;
           ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
  ##   
                                                                                                                                                                                       ## ConfigurationSetName: string (required)
                                                                                                                                                                                       ##                       
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## ConfigurationSetName
  var path_402656500 = newJObject()
  add(path_402656500, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656499.call(path_402656500, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_402656476(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_402656477,
    base: "/", makeUrl: url_GetConfigurationSetEventDestinations_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_402656517 = ref object of OpenApiRestCall_402656029
proc url_DeleteConfigurationSet_402656519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/sms-voice/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_402656518(path: JsonNode; query: JsonNode;
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
  var valid_402656520 = path.getOrDefault("ConfigurationSetName")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = nil)
  if valid_402656520 != nil:
    section.add "ConfigurationSetName", valid_402656520
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656521 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Security-Token", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Signature")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Signature", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Algorithm", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Date")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Date", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Credential")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Credential", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656528: Call_DeleteConfigurationSet_402656517;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing configuration set.
                                                                                         ## 
  let valid = call_402656528.validator(path, query, header, formData, body, _)
  let scheme = call_402656528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656528.makeUrl(scheme.get, call_402656528.host, call_402656528.base,
                                   call_402656528.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656528, uri, valid, _)

proc call*(call_402656529: Call_DeleteConfigurationSet_402656517;
           ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## Deletes an existing configuration set.
  ##   ConfigurationSetName: string (required)
                                           ##                       : ConfigurationSetName
  var path_402656530 = newJObject()
  add(path_402656530, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656529.call(path_402656530, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_402656517(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_402656518, base: "/",
    makeUrl: url_DeleteConfigurationSet_402656519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_402656531 = ref object of OpenApiRestCall_402656029
proc url_UpdateConfigurationSetEventDestination_402656533(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment,
                  value: "/v1/sms-voice/configuration-sets/"),
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

proc validate_UpdateConfigurationSetEventDestination_402656532(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EventDestinationName: JString (required)
                                 ##                       : EventDestinationName
  ##   
                                                                                ## ConfigurationSetName: JString (required)
                                                                                ##                       
                                                                                ## : 
                                                                                ## ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `EventDestinationName` field"
  var valid_402656534 = path.getOrDefault("EventDestinationName")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "EventDestinationName", valid_402656534
  var valid_402656535 = path.getOrDefault("ConfigurationSetName")
  valid_402656535 = validateParameter(valid_402656535, JString, required = true,
                                      default = nil)
  if valid_402656535 != nil:
    section.add "ConfigurationSetName", valid_402656535
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
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

proc call*(call_402656544: Call_UpdateConfigurationSetEventDestination_402656531;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_UpdateConfigurationSetEventDestination_402656531;
           EventDestinationName: string; ConfigurationSetName: string;
           body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
  ##   
                                                                                                                                                                                                                                            ## EventDestinationName: string (required)
                                                                                                                                                                                                                                            ##                       
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## EventDestinationName
  ##   
                                                                                                                                                                                                                                                                   ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                   ##                       
                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                   ## ConfigurationSetName
  ##   
                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var path_402656546 = newJObject()
  var body_402656547 = newJObject()
  add(path_402656546, "EventDestinationName", newJString(EventDestinationName))
  add(path_402656546, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656547 = body
  result = call_402656545.call(path_402656546, nil, nil, nil, body_402656547)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_402656531(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_402656532,
    base: "/", makeUrl: url_UpdateConfigurationSetEventDestination_402656533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_402656548 = ref object of OpenApiRestCall_402656029
proc url_DeleteConfigurationSetEventDestination_402656550(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment,
                  value: "/v1/sms-voice/configuration-sets/"),
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

proc validate_DeleteConfigurationSetEventDestination_402656549(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an event destination in a configuration set.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EventDestinationName: JString (required)
                                 ##                       : EventDestinationName
  ##   
                                                                                ## ConfigurationSetName: JString (required)
                                                                                ##                       
                                                                                ## : 
                                                                                ## ConfigurationSetName
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `EventDestinationName` field"
  var valid_402656551 = path.getOrDefault("EventDestinationName")
  valid_402656551 = validateParameter(valid_402656551, JString, required = true,
                                      default = nil)
  if valid_402656551 != nil:
    section.add "EventDestinationName", valid_402656551
  var valid_402656552 = path.getOrDefault("ConfigurationSetName")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true,
                                      default = nil)
  if valid_402656552 != nil:
    section.add "ConfigurationSetName", valid_402656552
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656560: Call_DeleteConfigurationSetEventDestination_402656548;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an event destination in a configuration set.
                                                                                         ## 
  let valid = call_402656560.validator(path, query, header, formData, body, _)
  let scheme = call_402656560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656560.makeUrl(scheme.get, call_402656560.host, call_402656560.base,
                                   call_402656560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656560, uri, valid, _)

proc call*(call_402656561: Call_DeleteConfigurationSetEventDestination_402656548;
           EventDestinationName: string; ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## Deletes an event destination in a configuration set.
  ##   EventDestinationName: string (required)
                                                         ##                       : EventDestinationName
  ##   
                                                                                                        ## ConfigurationSetName: string (required)
                                                                                                        ##                       
                                                                                                        ## : 
                                                                                                        ## ConfigurationSetName
  var path_402656562 = newJObject()
  add(path_402656562, "EventDestinationName", newJString(EventDestinationName))
  add(path_402656562, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656561.call(path_402656562, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_402656548(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "sms-voice.pinpoint.amazonaws.com", route: "/v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_402656549,
    base: "/", makeUrl: url_DeleteConfigurationSetEventDestination_402656550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendVoiceMessage_402656563 = ref object of OpenApiRestCall_402656029
proc url_SendVoiceMessage_402656565(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendVoiceMessage_402656564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656566 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Security-Token", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Signature")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Signature", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Algorithm", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Date")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Date", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Credential")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Credential", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656572
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

proc call*(call_402656574: Call_SendVoiceMessage_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new voice message and send it to a recipient's phone number.
                                                                                         ## 
  let valid = call_402656574.validator(path, query, header, formData, body, _)
  let scheme = call_402656574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656574.makeUrl(scheme.get, call_402656574.host, call_402656574.base,
                                   call_402656574.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656574, uri, valid, _)

proc call*(call_402656575: Call_SendVoiceMessage_402656563; body: JsonNode): Recallable =
  ## sendVoiceMessage
  ## Create a new voice message and send it to a recipient's phone number.
  ##   body: 
                                                                          ## JObject (required)
  var body_402656576 = newJObject()
  if body != nil:
    body_402656576 = body
  result = call_402656575.call(nil, nil, nil, nil, body_402656576)

var sendVoiceMessage* = Call_SendVoiceMessage_402656563(
    name: "sendVoiceMessage", meth: HttpMethod.HttpPost,
    host: "sms-voice.pinpoint.amazonaws.com",
    route: "/v1/sms-voice/voice/message", validator: validate_SendVoiceMessage_402656564,
    base: "/", makeUrl: url_SendVoiceMessage_402656565,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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