
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Events
## version: 2018-07-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS IoT Events monitors your equipment or device fleets for failures or changes in operation, and triggers actions when such events occur. AWS IoT Events API commands enable you to create, read, update and delete inputs and detector models, and to list their versions.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotevents/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "iotevents.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotevents.ap-southeast-1.amazonaws.com",
                           "us-west-2": "iotevents.us-west-2.amazonaws.com",
                           "eu-west-2": "iotevents.eu-west-2.amazonaws.com", "ap-northeast-3": "iotevents.ap-northeast-3.amazonaws.com", "eu-central-1": "iotevents.eu-central-1.amazonaws.com",
                           "us-east-2": "iotevents.us-east-2.amazonaws.com",
                           "us-east-1": "iotevents.us-east-1.amazonaws.com", "cn-northwest-1": "iotevents.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "iotevents.ap-south-1.amazonaws.com",
                           "eu-north-1": "iotevents.eu-north-1.amazonaws.com", "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com",
                           "us-west-1": "iotevents.us-west-1.amazonaws.com", "us-gov-east-1": "iotevents.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "iotevents.eu-west-3.amazonaws.com", "cn-north-1": "iotevents.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "iotevents.sa-east-1.amazonaws.com",
                           "eu-west-1": "iotevents.eu-west-1.amazonaws.com", "us-gov-west-1": "iotevents.us-gov-west-1.amazonaws.com", "ap-southeast-2": "iotevents.ap-southeast-2.amazonaws.com", "ca-central-1": "iotevents.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "iotevents.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "iotevents.ap-southeast-1.amazonaws.com",
      "us-west-2": "iotevents.us-west-2.amazonaws.com",
      "eu-west-2": "iotevents.eu-west-2.amazonaws.com",
      "ap-northeast-3": "iotevents.ap-northeast-3.amazonaws.com",
      "eu-central-1": "iotevents.eu-central-1.amazonaws.com",
      "us-east-2": "iotevents.us-east-2.amazonaws.com",
      "us-east-1": "iotevents.us-east-1.amazonaws.com",
      "cn-northwest-1": "iotevents.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "iotevents.ap-south-1.amazonaws.com",
      "eu-north-1": "iotevents.eu-north-1.amazonaws.com",
      "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com",
      "us-west-1": "iotevents.us-west-1.amazonaws.com",
      "us-gov-east-1": "iotevents.us-gov-east-1.amazonaws.com",
      "eu-west-3": "iotevents.eu-west-3.amazonaws.com",
      "cn-north-1": "iotevents.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "iotevents.sa-east-1.amazonaws.com",
      "eu-west-1": "iotevents.eu-west-1.amazonaws.com",
      "us-gov-west-1": "iotevents.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "iotevents.ap-southeast-2.amazonaws.com",
      "ca-central-1": "iotevents.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotevents"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDetectorModel_613253 = ref object of OpenApiRestCall_612658
proc url_CreateDetectorModel_613255(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetectorModel_613254(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a detector model.
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
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_CreateDetectorModel_613253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_CreateDetectorModel_613253; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var createDetectorModel* = Call_CreateDetectorModel_613253(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_613254, base: "/",
    url: url_CreateDetectorModel_613255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_612996 = ref object of OpenApiRestCall_612658
proc url_ListDetectorModels_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectorModels_612997(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("maxResults")
  valid_613111 = validateParameter(valid_613111, JInt, required = false, default = nil)
  if valid_613111 != nil:
    section.add "maxResults", valid_613111
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
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_ListDetectorModels_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_ListDetectorModels_612996; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_613213 = newJObject()
  add(query_613213, "nextToken", newJString(nextToken))
  add(query_613213, "maxResults", newJInt(maxResults))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_612996(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_612997, base: "/",
    url: url_ListDetectorModels_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_613282 = ref object of OpenApiRestCall_612658
proc url_CreateInput_613284(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInput_613283(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an input.
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_CreateInput_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an input.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_CreateInput_613282; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var createInput* = Call_CreateInput_613282(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_613283,
                                        base: "/", url: url_CreateInput_613284,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_613267 = ref object of OpenApiRestCall_612658
proc url_ListInputs_613269(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_613268(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the inputs you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_613270 = query.getOrDefault("nextToken")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "nextToken", valid_613270
  var valid_613271 = query.getOrDefault("maxResults")
  valid_613271 = validateParameter(valid_613271, JInt, required = false, default = nil)
  if valid_613271 != nil:
    section.add "maxResults", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_ListInputs_613267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_ListInputs_613267; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_613281 = newJObject()
  add(query_613281, "nextToken", newJString(nextToken))
  add(query_613281, "maxResults", newJInt(maxResults))
  result = call_613280.call(nil, query_613281, nil, nil, nil)

var listInputs* = Call_ListInputs_613267(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_613268,
                                      base: "/", url: url_ListInputs_613269,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_613326 = ref object of OpenApiRestCall_612658
proc url_UpdateDetectorModel_613328(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDetectorModel_613327(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model that is updated.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_613329 = path.getOrDefault("detectorModelName")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = nil)
  if valid_613329 != nil:
    section.add "detectorModelName", valid_613329
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
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613338: Call_UpdateDetectorModel_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_613338.validator(path, query, header, formData, body)
  let scheme = call_613338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613338.url(scheme.get, call_613338.host, call_613338.base,
                         call_613338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613338, url, valid)

proc call*(call_613339: Call_UpdateDetectorModel_613326; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_613340 = newJObject()
  var body_613341 = newJObject()
  add(path_613340, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_613341 = body
  result = call_613339.call(path_613340, nil, nil, nil, body_613341)

var updateDetectorModel* = Call_UpdateDetectorModel_613326(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_613327, base: "/",
    url: url_UpdateDetectorModel_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_613296 = ref object of OpenApiRestCall_612658
proc url_DescribeDetectorModel_613298(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDetectorModel_613297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_613313 = path.getOrDefault("detectorModelName")
  valid_613313 = validateParameter(valid_613313, JString, required = true,
                                 default = nil)
  if valid_613313 != nil:
    section.add "detectorModelName", valid_613313
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_613314 = query.getOrDefault("version")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "version", valid_613314
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
  var valid_613315 = header.getOrDefault("X-Amz-Signature")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Signature", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Content-Sha256", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Date")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Date", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Credential")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Credential", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Security-Token")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Security-Token", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Algorithm")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Algorithm", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-SignedHeaders", valid_613321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_DescribeDetectorModel_613296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_DescribeDetectorModel_613296;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_613324 = newJObject()
  var query_613325 = newJObject()
  add(path_613324, "detectorModelName", newJString(detectorModelName))
  add(query_613325, "version", newJString(version))
  result = call_613323.call(path_613324, query_613325, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_613296(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_613297, base: "/",
    url: url_DescribeDetectorModel_613298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_613342 = ref object of OpenApiRestCall_612658
proc url_DeleteDetectorModel_613344(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDetectorModel_613343(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model to be deleted.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_613345 = path.getOrDefault("detectorModelName")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = nil)
  if valid_613345 != nil:
    section.add "detectorModelName", valid_613345
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
  var valid_613346 = header.getOrDefault("X-Amz-Signature")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Signature", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Content-Sha256", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Date")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Date", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Credential")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Credential", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Security-Token")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Security-Token", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Algorithm")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Algorithm", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-SignedHeaders", valid_613352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_DeleteDetectorModel_613342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_DeleteDetectorModel_613342; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_613355 = newJObject()
  add(path_613355, "detectorModelName", newJString(detectorModelName))
  result = call_613354.call(path_613355, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_613342(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_613343, base: "/",
    url: url_DeleteDetectorModel_613344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_613370 = ref object of OpenApiRestCall_612658
proc url_UpdateInput_613372(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_613371(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_613373 = path.getOrDefault("inputName")
  valid_613373 = validateParameter(valid_613373, JString, required = true,
                                 default = nil)
  if valid_613373 != nil:
    section.add "inputName", valid_613373
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
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_UpdateInput_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_UpdateInput_613370; body: JsonNode; inputName: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  var path_613384 = newJObject()
  var body_613385 = newJObject()
  if body != nil:
    body_613385 = body
  add(path_613384, "inputName", newJString(inputName))
  result = call_613383.call(path_613384, nil, nil, nil, body_613385)

var updateInput* = Call_UpdateInput_613370(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_613371,
                                        base: "/", url: url_UpdateInput_613372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_613356 = ref object of OpenApiRestCall_612658
proc url_DescribeInput_613358(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_613357(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_613359 = path.getOrDefault("inputName")
  valid_613359 = validateParameter(valid_613359, JString, required = true,
                                 default = nil)
  if valid_613359 != nil:
    section.add "inputName", valid_613359
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
  var valid_613360 = header.getOrDefault("X-Amz-Signature")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Signature", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Content-Sha256", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Date")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Date", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Credential")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Credential", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Security-Token")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Security-Token", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Algorithm")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Algorithm", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-SignedHeaders", valid_613366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DescribeInput_613356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an input.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DescribeInput_613356; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_613369 = newJObject()
  add(path_613369, "inputName", newJString(inputName))
  result = call_613368.call(path_613369, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_613356(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_613357,
    base: "/", url: url_DescribeInput_613358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_613386 = ref object of OpenApiRestCall_612658
proc url_DeleteInput_613388(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_613387(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_613389 = path.getOrDefault("inputName")
  valid_613389 = validateParameter(valid_613389, JString, required = true,
                                 default = nil)
  if valid_613389 != nil:
    section.add "inputName", valid_613389
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
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_DeleteInput_613386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_DeleteInput_613386; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_613399 = newJObject()
  add(path_613399, "inputName", newJString(inputName))
  result = call_613398.call(path_613399, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_613386(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_613387,
                                        base: "/", url: url_DeleteInput_613388,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_613412 = ref object of OpenApiRestCall_612658
proc url_PutLoggingOptions_613414(protocol: Scheme; host: string; base: string;
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

proc validate_PutLoggingOptions_613413(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
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
  var valid_613415 = header.getOrDefault("X-Amz-Signature")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Signature", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Content-Sha256", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Date")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Date", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Credential")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Credential", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Security-Token")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Security-Token", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Algorithm")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Algorithm", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-SignedHeaders", valid_613421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613423: Call_PutLoggingOptions_613412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_613423.validator(path, query, header, formData, body)
  let scheme = call_613423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613423.url(scheme.get, call_613423.host, call_613423.base,
                         call_613423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613423, url, valid)

proc call*(call_613424: Call_PutLoggingOptions_613412; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_613425 = newJObject()
  if body != nil:
    body_613425 = body
  result = call_613424.call(nil, nil, nil, nil, body_613425)

var putLoggingOptions* = Call_PutLoggingOptions_613412(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_613413, base: "/",
    url: url_PutLoggingOptions_613414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_613400 = ref object of OpenApiRestCall_612658
proc url_DescribeLoggingOptions_613402(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLoggingOptions_613401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current settings of the AWS IoT Events logging options.
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
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613410: Call_DescribeLoggingOptions_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_613410.validator(path, query, header, formData, body)
  let scheme = call_613410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613410.url(scheme.get, call_613410.host, call_613410.base,
                         call_613410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613410, url, valid)

proc call*(call_613411: Call_DescribeLoggingOptions_613400): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_613411.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_613400(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_613401, base: "/",
    url: url_DescribeLoggingOptions_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_613426 = ref object of OpenApiRestCall_612658
proc url_ListDetectorModelVersions_613428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDetectorModelVersions_613427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model whose versions are returned.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_613429 = path.getOrDefault("detectorModelName")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "detectorModelName", valid_613429
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_613430 = query.getOrDefault("nextToken")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "nextToken", valid_613430
  var valid_613431 = query.getOrDefault("maxResults")
  valid_613431 = validateParameter(valid_613431, JInt, required = false, default = nil)
  if valid_613431 != nil:
    section.add "maxResults", valid_613431
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
  var valid_613432 = header.getOrDefault("X-Amz-Signature")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Signature", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Content-Sha256", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Date")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Date", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Credential")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Credential", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Security-Token")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Security-Token", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Algorithm")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Algorithm", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-SignedHeaders", valid_613438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613439: Call_ListDetectorModelVersions_613426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_613439.validator(path, query, header, formData, body)
  let scheme = call_613439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613439.url(scheme.get, call_613439.host, call_613439.base,
                         call_613439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613439, url, valid)

proc call*(call_613440: Call_ListDetectorModelVersions_613426;
          detectorModelName: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var path_613441 = newJObject()
  var query_613442 = newJObject()
  add(query_613442, "nextToken", newJString(nextToken))
  add(path_613441, "detectorModelName", newJString(detectorModelName))
  add(query_613442, "maxResults", newJInt(maxResults))
  result = call_613440.call(path_613441, query_613442, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_613426(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_613427, base: "/",
    url: url_ListDetectorModelVersions_613428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613457 = ref object of OpenApiRestCall_612658
proc url_TagResource_613459(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613458(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_613460 = query.getOrDefault("resourceArn")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "resourceArn", valid_613460
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
  var valid_613461 = header.getOrDefault("X-Amz-Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Signature", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Content-Sha256", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Date")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Date", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Credential")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Credential", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Security-Token")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Security-Token", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Algorithm")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Algorithm", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-SignedHeaders", valid_613467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613469: Call_TagResource_613457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_613469.validator(path, query, header, formData, body)
  let scheme = call_613469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613469.url(scheme.get, call_613469.host, call_613469.base,
                         call_613469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613469, url, valid)

proc call*(call_613470: Call_TagResource_613457; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_613471 = newJObject()
  var body_613472 = newJObject()
  if body != nil:
    body_613472 = body
  add(query_613471, "resourceArn", newJString(resourceArn))
  result = call_613470.call(nil, query_613471, nil, nil, body_613472)

var tagResource* = Call_TagResource_613457(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_613458,
                                        base: "/", url: url_TagResource_613459,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613443 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613445(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613444(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_613446 = query.getOrDefault("resourceArn")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "resourceArn", valid_613446
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
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613454: Call_ListTagsForResource_613443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_613454.validator(path, query, header, formData, body)
  let scheme = call_613454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613454.url(scheme.get, call_613454.host, call_613454.base,
                         call_613454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613454, url, valid)

proc call*(call_613455: Call_ListTagsForResource_613443; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_613456 = newJObject()
  add(query_613456, "resourceArn", newJString(resourceArn))
  result = call_613455.call(nil, query_613456, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613443(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_613444, base: "/",
    url: url_ListTagsForResource_613445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613473 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613475(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613474(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the given tags (metadata) from the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613476 = query.getOrDefault("tagKeys")
  valid_613476 = validateParameter(valid_613476, JArray, required = true, default = nil)
  if valid_613476 != nil:
    section.add "tagKeys", valid_613476
  var valid_613477 = query.getOrDefault("resourceArn")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "resourceArn", valid_613477
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
  var valid_613478 = header.getOrDefault("X-Amz-Signature")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Signature", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Content-Sha256", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Date")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Date", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Credential")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Credential", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Security-Token")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Security-Token", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Algorithm")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Algorithm", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-SignedHeaders", valid_613484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_UntagResource_613473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_UntagResource_613473; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_613487 = newJObject()
  if tagKeys != nil:
    query_613487.add "tagKeys", tagKeys
  add(query_613487, "resourceArn", newJString(resourceArn))
  result = call_613486.call(nil, query_613487, nil, nil, nil)

var untagResource* = Call_UntagResource_613473(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_613474,
    base: "/", url: url_UntagResource_613475, schemes: {Scheme.Https, Scheme.Http})
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
