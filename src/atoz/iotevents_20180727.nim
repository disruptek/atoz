
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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  Call_CreateDetectorModel_607184 = ref object of OpenApiRestCall_606589
proc url_CreateDetectorModel_607186(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetectorModel_607185(path: JsonNode; query: JsonNode;
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
  var valid_607187 = header.getOrDefault("X-Amz-Signature")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Signature", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Content-Sha256", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Date")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Date", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Credential")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Credential", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Security-Token")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Security-Token", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Algorithm")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Algorithm", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-SignedHeaders", valid_607193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607195: Call_CreateDetectorModel_607184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_607195.validator(path, query, header, formData, body)
  let scheme = call_607195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607195.url(scheme.get, call_607195.host, call_607195.base,
                         call_607195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607195, url, valid)

proc call*(call_607196: Call_CreateDetectorModel_607184; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_607197 = newJObject()
  if body != nil:
    body_607197 = body
  result = call_607196.call(nil, nil, nil, nil, body_607197)

var createDetectorModel* = Call_CreateDetectorModel_607184(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_607185, base: "/",
    url: url_CreateDetectorModel_607186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_606927 = ref object of OpenApiRestCall_606589
proc url_ListDetectorModels_606929(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectorModels_606928(path: JsonNode; query: JsonNode;
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
  var valid_607041 = query.getOrDefault("nextToken")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "nextToken", valid_607041
  var valid_607042 = query.getOrDefault("maxResults")
  valid_607042 = validateParameter(valid_607042, JInt, required = false, default = nil)
  if valid_607042 != nil:
    section.add "maxResults", valid_607042
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
  var valid_607043 = header.getOrDefault("X-Amz-Signature")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Signature", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Content-Sha256", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Date")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Date", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Credential")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Credential", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Security-Token")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Security-Token", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Algorithm")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Algorithm", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-SignedHeaders", valid_607049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607072: Call_ListDetectorModels_606927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_607072.validator(path, query, header, formData, body)
  let scheme = call_607072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607072.url(scheme.get, call_607072.host, call_607072.base,
                         call_607072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607072, url, valid)

proc call*(call_607143: Call_ListDetectorModels_606927; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_607144 = newJObject()
  add(query_607144, "nextToken", newJString(nextToken))
  add(query_607144, "maxResults", newJInt(maxResults))
  result = call_607143.call(nil, query_607144, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_606927(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_606928, base: "/",
    url: url_ListDetectorModels_606929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_607213 = ref object of OpenApiRestCall_606589
proc url_CreateInput_607215(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInput_607214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607216 = header.getOrDefault("X-Amz-Signature")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Signature", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Content-Sha256", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Date")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Date", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Credential")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Credential", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Security-Token")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Security-Token", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Algorithm")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Algorithm", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-SignedHeaders", valid_607222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607224: Call_CreateInput_607213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an input.
  ## 
  let valid = call_607224.validator(path, query, header, formData, body)
  let scheme = call_607224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607224.url(scheme.get, call_607224.host, call_607224.base,
                         call_607224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607224, url, valid)

proc call*(call_607225: Call_CreateInput_607213; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_607226 = newJObject()
  if body != nil:
    body_607226 = body
  result = call_607225.call(nil, nil, nil, nil, body_607226)

var createInput* = Call_CreateInput_607213(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_607214,
                                        base: "/", url: url_CreateInput_607215,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_607198 = ref object of OpenApiRestCall_606589
proc url_ListInputs_607200(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListInputs_607199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607201 = query.getOrDefault("nextToken")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "nextToken", valid_607201
  var valid_607202 = query.getOrDefault("maxResults")
  valid_607202 = validateParameter(valid_607202, JInt, required = false, default = nil)
  if valid_607202 != nil:
    section.add "maxResults", valid_607202
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
  var valid_607203 = header.getOrDefault("X-Amz-Signature")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Signature", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Content-Sha256", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Date")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Date", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Credential")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Credential", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Security-Token")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Security-Token", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Algorithm")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Algorithm", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-SignedHeaders", valid_607209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607210: Call_ListInputs_607198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_607210.validator(path, query, header, formData, body)
  let scheme = call_607210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607210.url(scheme.get, call_607210.host, call_607210.base,
                         call_607210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607210, url, valid)

proc call*(call_607211: Call_ListInputs_607198; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_607212 = newJObject()
  add(query_607212, "nextToken", newJString(nextToken))
  add(query_607212, "maxResults", newJInt(maxResults))
  result = call_607211.call(nil, query_607212, nil, nil, nil)

var listInputs* = Call_ListInputs_607198(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_607199,
                                      base: "/", url: url_ListInputs_607200,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_607257 = ref object of OpenApiRestCall_606589
proc url_UpdateDetectorModel_607259(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetectorModel_607258(path: JsonNode; query: JsonNode;
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
  var valid_607260 = path.getOrDefault("detectorModelName")
  valid_607260 = validateParameter(valid_607260, JString, required = true,
                                 default = nil)
  if valid_607260 != nil:
    section.add "detectorModelName", valid_607260
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
  var valid_607261 = header.getOrDefault("X-Amz-Signature")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Signature", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Content-Sha256", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Date")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Date", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Credential")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Credential", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Security-Token")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Security-Token", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Algorithm")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Algorithm", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-SignedHeaders", valid_607267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607269: Call_UpdateDetectorModel_607257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_607269.validator(path, query, header, formData, body)
  let scheme = call_607269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607269.url(scheme.get, call_607269.host, call_607269.base,
                         call_607269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607269, url, valid)

proc call*(call_607270: Call_UpdateDetectorModel_607257; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_607271 = newJObject()
  var body_607272 = newJObject()
  add(path_607271, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_607272 = body
  result = call_607270.call(path_607271, nil, nil, nil, body_607272)

var updateDetectorModel* = Call_UpdateDetectorModel_607257(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_607258, base: "/",
    url: url_UpdateDetectorModel_607259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_607227 = ref object of OpenApiRestCall_606589
proc url_DescribeDetectorModel_607229(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetectorModel_607228(path: JsonNode; query: JsonNode;
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
  var valid_607244 = path.getOrDefault("detectorModelName")
  valid_607244 = validateParameter(valid_607244, JString, required = true,
                                 default = nil)
  if valid_607244 != nil:
    section.add "detectorModelName", valid_607244
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_607245 = query.getOrDefault("version")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "version", valid_607245
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
  var valid_607246 = header.getOrDefault("X-Amz-Signature")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Signature", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Content-Sha256", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Date")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Date", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Credential")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Credential", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Security-Token")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Security-Token", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Algorithm")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Algorithm", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-SignedHeaders", valid_607252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_DescribeDetectorModel_607227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_DescribeDetectorModel_607227;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_607255 = newJObject()
  var query_607256 = newJObject()
  add(path_607255, "detectorModelName", newJString(detectorModelName))
  add(query_607256, "version", newJString(version))
  result = call_607254.call(path_607255, query_607256, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_607227(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_607228, base: "/",
    url: url_DescribeDetectorModel_607229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_607273 = ref object of OpenApiRestCall_606589
proc url_DeleteDetectorModel_607275(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetectorModel_607274(path: JsonNode; query: JsonNode;
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
  var valid_607276 = path.getOrDefault("detectorModelName")
  valid_607276 = validateParameter(valid_607276, JString, required = true,
                                 default = nil)
  if valid_607276 != nil:
    section.add "detectorModelName", valid_607276
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
  var valid_607277 = header.getOrDefault("X-Amz-Signature")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Signature", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Content-Sha256", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Date")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Date", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Credential")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Credential", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Security-Token")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Security-Token", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Algorithm")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Algorithm", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-SignedHeaders", valid_607283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607284: Call_DeleteDetectorModel_607273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_607284.validator(path, query, header, formData, body)
  let scheme = call_607284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607284.url(scheme.get, call_607284.host, call_607284.base,
                         call_607284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607284, url, valid)

proc call*(call_607285: Call_DeleteDetectorModel_607273; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_607286 = newJObject()
  add(path_607286, "detectorModelName", newJString(detectorModelName))
  result = call_607285.call(path_607286, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_607273(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_607274, base: "/",
    url: url_DeleteDetectorModel_607275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_607301 = ref object of OpenApiRestCall_606589
proc url_UpdateInput_607303(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInput_607302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607304 = path.getOrDefault("inputName")
  valid_607304 = validateParameter(valid_607304, JString, required = true,
                                 default = nil)
  if valid_607304 != nil:
    section.add "inputName", valid_607304
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
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607313: Call_UpdateInput_607301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_607313.validator(path, query, header, formData, body)
  let scheme = call_607313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607313.url(scheme.get, call_607313.host, call_607313.base,
                         call_607313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607313, url, valid)

proc call*(call_607314: Call_UpdateInput_607301; body: JsonNode; inputName: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  var path_607315 = newJObject()
  var body_607316 = newJObject()
  if body != nil:
    body_607316 = body
  add(path_607315, "inputName", newJString(inputName))
  result = call_607314.call(path_607315, nil, nil, nil, body_607316)

var updateInput* = Call_UpdateInput_607301(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_607302,
                                        base: "/", url: url_UpdateInput_607303,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_607287 = ref object of OpenApiRestCall_606589
proc url_DescribeInput_607289(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInput_607288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607290 = path.getOrDefault("inputName")
  valid_607290 = validateParameter(valid_607290, JString, required = true,
                                 default = nil)
  if valid_607290 != nil:
    section.add "inputName", valid_607290
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
  var valid_607291 = header.getOrDefault("X-Amz-Signature")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Signature", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Content-Sha256", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Date")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Date", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Credential")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Credential", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Security-Token")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Security-Token", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Algorithm")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Algorithm", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-SignedHeaders", valid_607297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607298: Call_DescribeInput_607287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an input.
  ## 
  let valid = call_607298.validator(path, query, header, formData, body)
  let scheme = call_607298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607298.url(scheme.get, call_607298.host, call_607298.base,
                         call_607298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607298, url, valid)

proc call*(call_607299: Call_DescribeInput_607287; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_607300 = newJObject()
  add(path_607300, "inputName", newJString(inputName))
  result = call_607299.call(path_607300, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_607287(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_607288,
    base: "/", url: url_DescribeInput_607289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_607317 = ref object of OpenApiRestCall_606589
proc url_DeleteInput_607319(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInput_607318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607320 = path.getOrDefault("inputName")
  valid_607320 = validateParameter(valid_607320, JString, required = true,
                                 default = nil)
  if valid_607320 != nil:
    section.add "inputName", valid_607320
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
  var valid_607321 = header.getOrDefault("X-Amz-Signature")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Signature", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Content-Sha256", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Date")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Date", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Credential")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Credential", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Security-Token")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Security-Token", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Algorithm")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Algorithm", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-SignedHeaders", valid_607327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_DeleteInput_607317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_DeleteInput_607317; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_607330 = newJObject()
  add(path_607330, "inputName", newJString(inputName))
  result = call_607329.call(path_607330, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_607317(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_607318,
                                        base: "/", url: url_DeleteInput_607319,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_607343 = ref object of OpenApiRestCall_606589
proc url_PutLoggingOptions_607345(protocol: Scheme; host: string; base: string;
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

proc validate_PutLoggingOptions_607344(path: JsonNode; query: JsonNode;
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
  var valid_607346 = header.getOrDefault("X-Amz-Signature")
  valid_607346 = validateParameter(valid_607346, JString, required = false,
                                 default = nil)
  if valid_607346 != nil:
    section.add "X-Amz-Signature", valid_607346
  var valid_607347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607347 = validateParameter(valid_607347, JString, required = false,
                                 default = nil)
  if valid_607347 != nil:
    section.add "X-Amz-Content-Sha256", valid_607347
  var valid_607348 = header.getOrDefault("X-Amz-Date")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Date", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Credential")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Credential", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Security-Token")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Security-Token", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Algorithm")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Algorithm", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-SignedHeaders", valid_607352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607354: Call_PutLoggingOptions_607343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_607354.validator(path, query, header, formData, body)
  let scheme = call_607354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607354.url(scheme.get, call_607354.host, call_607354.base,
                         call_607354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607354, url, valid)

proc call*(call_607355: Call_PutLoggingOptions_607343; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_607356 = newJObject()
  if body != nil:
    body_607356 = body
  result = call_607355.call(nil, nil, nil, nil, body_607356)

var putLoggingOptions* = Call_PutLoggingOptions_607343(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_607344, base: "/",
    url: url_PutLoggingOptions_607345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_607331 = ref object of OpenApiRestCall_606589
proc url_DescribeLoggingOptions_607333(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLoggingOptions_607332(path: JsonNode; query: JsonNode;
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
  var valid_607334 = header.getOrDefault("X-Amz-Signature")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Signature", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Content-Sha256", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Date")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Date", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Credential")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Credential", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Security-Token")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Security-Token", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Algorithm")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Algorithm", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-SignedHeaders", valid_607340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607341: Call_DescribeLoggingOptions_607331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_607341.validator(path, query, header, formData, body)
  let scheme = call_607341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607341.url(scheme.get, call_607341.host, call_607341.base,
                         call_607341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607341, url, valid)

proc call*(call_607342: Call_DescribeLoggingOptions_607331): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_607342.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_607331(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_607332, base: "/",
    url: url_DescribeLoggingOptions_607333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_607357 = ref object of OpenApiRestCall_606589
proc url_ListDetectorModelVersions_607359(protocol: Scheme; host: string;
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

proc validate_ListDetectorModelVersions_607358(path: JsonNode; query: JsonNode;
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
  var valid_607360 = path.getOrDefault("detectorModelName")
  valid_607360 = validateParameter(valid_607360, JString, required = true,
                                 default = nil)
  if valid_607360 != nil:
    section.add "detectorModelName", valid_607360
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_607361 = query.getOrDefault("nextToken")
  valid_607361 = validateParameter(valid_607361, JString, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "nextToken", valid_607361
  var valid_607362 = query.getOrDefault("maxResults")
  valid_607362 = validateParameter(valid_607362, JInt, required = false, default = nil)
  if valid_607362 != nil:
    section.add "maxResults", valid_607362
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
  var valid_607363 = header.getOrDefault("X-Amz-Signature")
  valid_607363 = validateParameter(valid_607363, JString, required = false,
                                 default = nil)
  if valid_607363 != nil:
    section.add "X-Amz-Signature", valid_607363
  var valid_607364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "X-Amz-Content-Sha256", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Date")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Date", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Credential")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Credential", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Security-Token")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Security-Token", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Algorithm")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Algorithm", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-SignedHeaders", valid_607369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607370: Call_ListDetectorModelVersions_607357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_607370.validator(path, query, header, formData, body)
  let scheme = call_607370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607370.url(scheme.get, call_607370.host, call_607370.base,
                         call_607370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607370, url, valid)

proc call*(call_607371: Call_ListDetectorModelVersions_607357;
          detectorModelName: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var path_607372 = newJObject()
  var query_607373 = newJObject()
  add(query_607373, "nextToken", newJString(nextToken))
  add(path_607372, "detectorModelName", newJString(detectorModelName))
  add(query_607373, "maxResults", newJInt(maxResults))
  result = call_607371.call(path_607372, query_607373, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_607357(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_607358, base: "/",
    url: url_ListDetectorModelVersions_607359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607388 = ref object of OpenApiRestCall_606589
proc url_TagResource_607390(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607391 = query.getOrDefault("resourceArn")
  valid_607391 = validateParameter(valid_607391, JString, required = true,
                                 default = nil)
  if valid_607391 != nil:
    section.add "resourceArn", valid_607391
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
  var valid_607392 = header.getOrDefault("X-Amz-Signature")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Signature", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Content-Sha256", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Date")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Date", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-Credential")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Credential", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Security-Token")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Security-Token", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Algorithm")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Algorithm", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-SignedHeaders", valid_607398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607400: Call_TagResource_607388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_607400.validator(path, query, header, formData, body)
  let scheme = call_607400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607400.url(scheme.get, call_607400.host, call_607400.base,
                         call_607400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607400, url, valid)

proc call*(call_607401: Call_TagResource_607388; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_607402 = newJObject()
  var body_607403 = newJObject()
  if body != nil:
    body_607403 = body
  add(query_607402, "resourceArn", newJString(resourceArn))
  result = call_607401.call(nil, query_607402, nil, nil, body_607403)

var tagResource* = Call_TagResource_607388(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_607389,
                                        base: "/", url: url_TagResource_607390,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607374 = ref object of OpenApiRestCall_606589
proc url_ListTagsForResource_607376(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_607375(path: JsonNode; query: JsonNode;
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
  var valid_607377 = query.getOrDefault("resourceArn")
  valid_607377 = validateParameter(valid_607377, JString, required = true,
                                 default = nil)
  if valid_607377 != nil:
    section.add "resourceArn", valid_607377
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
  var valid_607378 = header.getOrDefault("X-Amz-Signature")
  valid_607378 = validateParameter(valid_607378, JString, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "X-Amz-Signature", valid_607378
  var valid_607379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "X-Amz-Content-Sha256", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Date")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Date", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Credential")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Credential", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Security-Token")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Security-Token", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Algorithm")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Algorithm", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-SignedHeaders", valid_607384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607385: Call_ListTagsForResource_607374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_607385.validator(path, query, header, formData, body)
  let scheme = call_607385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607385.url(scheme.get, call_607385.host, call_607385.base,
                         call_607385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607385, url, valid)

proc call*(call_607386: Call_ListTagsForResource_607374; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_607387 = newJObject()
  add(query_607387, "resourceArn", newJString(resourceArn))
  result = call_607386.call(nil, query_607387, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_607374(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_607375, base: "/",
    url: url_ListTagsForResource_607376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607404 = ref object of OpenApiRestCall_606589
proc url_UntagResource_607406(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607407 = query.getOrDefault("tagKeys")
  valid_607407 = validateParameter(valid_607407, JArray, required = true, default = nil)
  if valid_607407 != nil:
    section.add "tagKeys", valid_607407
  var valid_607408 = query.getOrDefault("resourceArn")
  valid_607408 = validateParameter(valid_607408, JString, required = true,
                                 default = nil)
  if valid_607408 != nil:
    section.add "resourceArn", valid_607408
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
  var valid_607409 = header.getOrDefault("X-Amz-Signature")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-Signature", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-Content-Sha256", valid_607410
  var valid_607411 = header.getOrDefault("X-Amz-Date")
  valid_607411 = validateParameter(valid_607411, JString, required = false,
                                 default = nil)
  if valid_607411 != nil:
    section.add "X-Amz-Date", valid_607411
  var valid_607412 = header.getOrDefault("X-Amz-Credential")
  valid_607412 = validateParameter(valid_607412, JString, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "X-Amz-Credential", valid_607412
  var valid_607413 = header.getOrDefault("X-Amz-Security-Token")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "X-Amz-Security-Token", valid_607413
  var valid_607414 = header.getOrDefault("X-Amz-Algorithm")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Algorithm", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-SignedHeaders", valid_607415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607416: Call_UntagResource_607404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_607416.validator(path, query, header, formData, body)
  let scheme = call_607416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607416.url(scheme.get, call_607416.host, call_607416.base,
                         call_607416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607416, url, valid)

proc call*(call_607417: Call_UntagResource_607404; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_607418 = newJObject()
  if tagKeys != nil:
    query_607418.add "tagKeys", tagKeys
  add(query_607418, "resourceArn", newJString(resourceArn))
  result = call_607417.call(nil, query_607418, nil, nil, nil)

var untagResource* = Call_UntagResource_607404(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_607405,
    base: "/", url: url_UntagResource_607406, schemes: {Scheme.Https, Scheme.Http})
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
