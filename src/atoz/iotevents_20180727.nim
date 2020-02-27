
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: AWS IoT Events
## version: 2018-07-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS IoT Events monitors your equipment or device fleets for failures or changes in operation, and triggers actions when such events occur. You can use AWS IoT Events API commands to create, read, update, and delete inputs and detector models, and to list their versions.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotevents/
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "iotevents.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotevents.ap-southeast-1.amazonaws.com",
                           "us-west-2": "iotevents.us-west-2.amazonaws.com",
                           "eu-west-2": "iotevents.eu-west-2.amazonaws.com", "ap-northeast-3": "iotevents.ap-northeast-3.amazonaws.com", "eu-central-1": "iotevents.eu-central-1.amazonaws.com",
                           "us-east-2": "iotevents.us-east-2.amazonaws.com",
                           "us-east-1": "iotevents.us-east-1.amazonaws.com", "cn-northwest-1": "iotevents.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "iotevents.ap-south-1.amazonaws.com",
                           "eu-north-1": "iotevents.eu-north-1.amazonaws.com",
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
      "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com",
      "ap-south-1": "iotevents.ap-south-1.amazonaws.com",
      "eu-north-1": "iotevents.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateDetectorModel_617465 = ref object of OpenApiRestCall_616866
proc url_CreateDetectorModel_617467(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorModel_617466(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Creates a detector model.
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
  var valid_617468 = header.getOrDefault("X-Amz-Date")
  valid_617468 = validateParameter(valid_617468, JString, required = false,
                                 default = nil)
  if valid_617468 != nil:
    section.add "X-Amz-Date", valid_617468
  var valid_617469 = header.getOrDefault("X-Amz-Security-Token")
  valid_617469 = validateParameter(valid_617469, JString, required = false,
                                 default = nil)
  if valid_617469 != nil:
    section.add "X-Amz-Security-Token", valid_617469
  var valid_617470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617470 = validateParameter(valid_617470, JString, required = false,
                                 default = nil)
  if valid_617470 != nil:
    section.add "X-Amz-Content-Sha256", valid_617470
  var valid_617471 = header.getOrDefault("X-Amz-Algorithm")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-Algorithm", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Signature")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Signature", valid_617472
  var valid_617473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617473 = validateParameter(valid_617473, JString, required = false,
                                 default = nil)
  if valid_617473 != nil:
    section.add "X-Amz-SignedHeaders", valid_617473
  var valid_617474 = header.getOrDefault("X-Amz-Credential")
  valid_617474 = validateParameter(valid_617474, JString, required = false,
                                 default = nil)
  if valid_617474 != nil:
    section.add "X-Amz-Credential", valid_617474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617476: Call_CreateDetectorModel_617465; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_617476.validator(path, query, header, formData, body, _)
  let scheme = call_617476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617476.url(scheme.get, call_617476.host, call_617476.base,
                         call_617476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617476, url, valid, _)

proc call*(call_617477: Call_CreateDetectorModel_617465; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_617478 = newJObject()
  if body != nil:
    body_617478 = body
  result = call_617477.call(nil, nil, nil, nil, body_617478)

var createDetectorModel* = Call_CreateDetectorModel_617465(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_617466, base: "/",
    url: url_CreateDetectorModel_617467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_617205 = ref object of OpenApiRestCall_616866
proc url_ListDetectorModels_617207(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectorModels_617206(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_617319 = query.getOrDefault("maxResults")
  valid_617319 = validateParameter(valid_617319, JInt, required = false, default = nil)
  if valid_617319 != nil:
    section.add "maxResults", valid_617319
  var valid_617320 = query.getOrDefault("nextToken")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "nextToken", valid_617320
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
  var valid_617321 = header.getOrDefault("X-Amz-Date")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Date", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Security-Token")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Security-Token", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Content-Sha256", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-Algorithm")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-Algorithm", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-Signature")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Signature", valid_617325
  var valid_617326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617326 = validateParameter(valid_617326, JString, required = false,
                                 default = nil)
  if valid_617326 != nil:
    section.add "X-Amz-SignedHeaders", valid_617326
  var valid_617327 = header.getOrDefault("X-Amz-Credential")
  valid_617327 = validateParameter(valid_617327, JString, required = false,
                                 default = nil)
  if valid_617327 != nil:
    section.add "X-Amz-Credential", valid_617327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617351: Call_ListDetectorModels_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_617351.validator(path, query, header, formData, body, _)
  let scheme = call_617351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617351.url(scheme.get, call_617351.host, call_617351.base,
                         call_617351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617351, url, valid, _)

proc call*(call_617422: Call_ListDetectorModels_617205; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_617423 = newJObject()
  add(query_617423, "maxResults", newJInt(maxResults))
  add(query_617423, "nextToken", newJString(nextToken))
  result = call_617422.call(nil, query_617423, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_617205(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_617206, base: "/",
    url: url_ListDetectorModels_617207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_617494 = ref object of OpenApiRestCall_616866
proc url_CreateInput_617496(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_617495(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates an input.
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
  var valid_617497 = header.getOrDefault("X-Amz-Date")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Date", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Security-Token")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Security-Token", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Content-Sha256", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-Algorithm")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-Algorithm", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Signature")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "X-Amz-Signature", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-SignedHeaders", valid_617502
  var valid_617503 = header.getOrDefault("X-Amz-Credential")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-Credential", valid_617503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617505: Call_CreateInput_617494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an input.
  ## 
  let valid = call_617505.validator(path, query, header, formData, body, _)
  let scheme = call_617505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617505.url(scheme.get, call_617505.host, call_617505.base,
                         call_617505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617505, url, valid, _)

proc call*(call_617506: Call_CreateInput_617494; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_617507 = newJObject()
  if body != nil:
    body_617507 = body
  result = call_617506.call(nil, nil, nil, nil, body_617507)

var createInput* = Call_CreateInput_617494(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_617495,
                                        base: "/", url: url_CreateInput_617496,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_617479 = ref object of OpenApiRestCall_616866
proc url_ListInputs_617481(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_617480(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Lists the inputs you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_617482 = query.getOrDefault("maxResults")
  valid_617482 = validateParameter(valid_617482, JInt, required = false, default = nil)
  if valid_617482 != nil:
    section.add "maxResults", valid_617482
  var valid_617483 = query.getOrDefault("nextToken")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "nextToken", valid_617483
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
  var valid_617484 = header.getOrDefault("X-Amz-Date")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Date", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-Security-Token")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-Security-Token", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "X-Amz-Content-Sha256", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Algorithm")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Algorithm", valid_617487
  var valid_617488 = header.getOrDefault("X-Amz-Signature")
  valid_617488 = validateParameter(valid_617488, JString, required = false,
                                 default = nil)
  if valid_617488 != nil:
    section.add "X-Amz-Signature", valid_617488
  var valid_617489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617489 = validateParameter(valid_617489, JString, required = false,
                                 default = nil)
  if valid_617489 != nil:
    section.add "X-Amz-SignedHeaders", valid_617489
  var valid_617490 = header.getOrDefault("X-Amz-Credential")
  valid_617490 = validateParameter(valid_617490, JString, required = false,
                                 default = nil)
  if valid_617490 != nil:
    section.add "X-Amz-Credential", valid_617490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617491: Call_ListInputs_617479; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_617491.validator(path, query, header, formData, body, _)
  let scheme = call_617491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617491.url(scheme.get, call_617491.host, call_617491.base,
                         call_617491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617491, url, valid, _)

proc call*(call_617492: Call_ListInputs_617479; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_617493 = newJObject()
  add(query_617493, "maxResults", newJInt(maxResults))
  add(query_617493, "nextToken", newJString(nextToken))
  result = call_617492.call(nil, query_617493, nil, nil, nil)

var listInputs* = Call_ListInputs_617479(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_617480,
                                      base: "/", url: url_ListInputs_617481,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_617538 = ref object of OpenApiRestCall_616866
proc url_UpdateDetectorModel_617540(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDetectorModel_617539(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617541 = path.getOrDefault("detectorModelName")
  valid_617541 = validateParameter(valid_617541, JString, required = true,
                                 default = nil)
  if valid_617541 != nil:
    section.add "detectorModelName", valid_617541
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
  var valid_617542 = header.getOrDefault("X-Amz-Date")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Date", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Security-Token")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Security-Token", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Content-Sha256", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-Algorithm")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-Algorithm", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Signature")
  valid_617546 = validateParameter(valid_617546, JString, required = false,
                                 default = nil)
  if valid_617546 != nil:
    section.add "X-Amz-Signature", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-SignedHeaders", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-Credential")
  valid_617548 = validateParameter(valid_617548, JString, required = false,
                                 default = nil)
  if valid_617548 != nil:
    section.add "X-Amz-Credential", valid_617548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617550: Call_UpdateDetectorModel_617538; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_617550.validator(path, query, header, formData, body, _)
  let scheme = call_617550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617550.url(scheme.get, call_617550.host, call_617550.base,
                         call_617550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617550, url, valid, _)

proc call*(call_617551: Call_UpdateDetectorModel_617538; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_617552 = newJObject()
  var body_617553 = newJObject()
  add(path_617552, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_617553 = body
  result = call_617551.call(path_617552, nil, nil, nil, body_617553)

var updateDetectorModel* = Call_UpdateDetectorModel_617538(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_617539, base: "/",
    url: url_UpdateDetectorModel_617540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_617508 = ref object of OpenApiRestCall_616866
proc url_DescribeDetectorModel_617510(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDetectorModel_617509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
  ##                    : The name of the detector model.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorModelName` field"
  var valid_617525 = path.getOrDefault("detectorModelName")
  valid_617525 = validateParameter(valid_617525, JString, required = true,
                                 default = nil)
  if valid_617525 != nil:
    section.add "detectorModelName", valid_617525
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_617526 = query.getOrDefault("version")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "version", valid_617526
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
  var valid_617527 = header.getOrDefault("X-Amz-Date")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Date", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Security-Token")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Security-Token", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Content-Sha256", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-Algorithm")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-Algorithm", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Signature")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-Signature", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-SignedHeaders", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Credential")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-Credential", valid_617533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617534: Call_DescribeDetectorModel_617508; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_DescribeDetectorModel_617508;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_617536 = newJObject()
  var query_617537 = newJObject()
  add(path_617536, "detectorModelName", newJString(detectorModelName))
  add(query_617537, "version", newJString(version))
  result = call_617535.call(path_617536, query_617537, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_617508(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_617509, base: "/",
    url: url_DescribeDetectorModel_617510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_617554 = ref object of OpenApiRestCall_616866
proc url_DeleteDetectorModel_617556(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDetectorModel_617555(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617557 = path.getOrDefault("detectorModelName")
  valid_617557 = validateParameter(valid_617557, JString, required = true,
                                 default = nil)
  if valid_617557 != nil:
    section.add "detectorModelName", valid_617557
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
  var valid_617558 = header.getOrDefault("X-Amz-Date")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Date", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Security-Token")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Security-Token", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-Content-Sha256", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Algorithm")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "X-Amz-Algorithm", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Signature")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-Signature", valid_617562
  var valid_617563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617563 = validateParameter(valid_617563, JString, required = false,
                                 default = nil)
  if valid_617563 != nil:
    section.add "X-Amz-SignedHeaders", valid_617563
  var valid_617564 = header.getOrDefault("X-Amz-Credential")
  valid_617564 = validateParameter(valid_617564, JString, required = false,
                                 default = nil)
  if valid_617564 != nil:
    section.add "X-Amz-Credential", valid_617564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617565: Call_DeleteDetectorModel_617554; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_617565.validator(path, query, header, formData, body, _)
  let scheme = call_617565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617565.url(scheme.get, call_617565.host, call_617565.base,
                         call_617565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617565, url, valid, _)

proc call*(call_617566: Call_DeleteDetectorModel_617554; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_617567 = newJObject()
  add(path_617567, "detectorModelName", newJString(detectorModelName))
  result = call_617566.call(path_617567, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_617554(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_617555, base: "/",
    url: url_DeleteDetectorModel_617556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_617582 = ref object of OpenApiRestCall_616866
proc url_UpdateInput_617584(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_617583(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Updates an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_617585 = path.getOrDefault("inputName")
  valid_617585 = validateParameter(valid_617585, JString, required = true,
                                 default = nil)
  if valid_617585 != nil:
    section.add "inputName", valid_617585
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
  var valid_617586 = header.getOrDefault("X-Amz-Date")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Date", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Security-Token")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Security-Token", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Content-Sha256", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-Algorithm")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Algorithm", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-Signature")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Signature", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "X-Amz-SignedHeaders", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Credential")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Credential", valid_617592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617594: Call_UpdateInput_617582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an input.
  ## 
  let valid = call_617594.validator(path, query, header, formData, body, _)
  let scheme = call_617594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617594.url(scheme.get, call_617594.host, call_617594.base,
                         call_617594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617594, url, valid, _)

proc call*(call_617595: Call_UpdateInput_617582; inputName: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  ##   body: JObject (required)
  var path_617596 = newJObject()
  var body_617597 = newJObject()
  add(path_617596, "inputName", newJString(inputName))
  if body != nil:
    body_617597 = body
  result = call_617595.call(path_617596, nil, nil, nil, body_617597)

var updateInput* = Call_UpdateInput_617582(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_617583,
                                        base: "/", url: url_UpdateInput_617584,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_617568 = ref object of OpenApiRestCall_616866
proc url_DescribeInput_617570(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_617569(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Describes an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_617571 = path.getOrDefault("inputName")
  valid_617571 = validateParameter(valid_617571, JString, required = true,
                                 default = nil)
  if valid_617571 != nil:
    section.add "inputName", valid_617571
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
  var valid_617572 = header.getOrDefault("X-Amz-Date")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Date", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Security-Token")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Security-Token", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Content-Sha256", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Algorithm")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Algorithm", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Signature")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-Signature", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-SignedHeaders", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Credential")
  valid_617578 = validateParameter(valid_617578, JString, required = false,
                                 default = nil)
  if valid_617578 != nil:
    section.add "X-Amz-Credential", valid_617578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617579: Call_DescribeInput_617568; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an input.
  ## 
  let valid = call_617579.validator(path, query, header, formData, body, _)
  let scheme = call_617579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617579.url(scheme.get, call_617579.host, call_617579.base,
                         call_617579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617579, url, valid, _)

proc call*(call_617580: Call_DescribeInput_617568; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_617581 = newJObject()
  add(path_617581, "inputName", newJString(inputName))
  result = call_617580.call(path_617581, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_617568(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_617569,
    base: "/", url: url_DescribeInput_617570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_617598 = ref object of OpenApiRestCall_616866
proc url_DeleteInput_617600(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_617599(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Deletes an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
  ##            : The name of the input to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputName` field"
  var valid_617601 = path.getOrDefault("inputName")
  valid_617601 = validateParameter(valid_617601, JString, required = true,
                                 default = nil)
  if valid_617601 != nil:
    section.add "inputName", valid_617601
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
  var valid_617602 = header.getOrDefault("X-Amz-Date")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Date", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-Security-Token")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-Security-Token", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Content-Sha256", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-Algorithm")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-Algorithm", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Signature")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "X-Amz-Signature", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-SignedHeaders", valid_617607
  var valid_617608 = header.getOrDefault("X-Amz-Credential")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "X-Amz-Credential", valid_617608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617609: Call_DeleteInput_617598; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_617609.validator(path, query, header, formData, body, _)
  let scheme = call_617609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617609.url(scheme.get, call_617609.host, call_617609.base,
                         call_617609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617609, url, valid, _)

proc call*(call_617610: Call_DeleteInput_617598; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_617611 = newJObject()
  add(path_617611, "inputName", newJString(inputName))
  result = call_617610.call(path_617611, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_617598(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_617599,
                                        base: "/", url: url_DeleteInput_617600,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_617624 = ref object of OpenApiRestCall_616866
proc url_PutLoggingOptions_617626(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_617625(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
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
  var valid_617627 = header.getOrDefault("X-Amz-Date")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-Date", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Security-Token")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Security-Token", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617629 = validateParameter(valid_617629, JString, required = false,
                                 default = nil)
  if valid_617629 != nil:
    section.add "X-Amz-Content-Sha256", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-Algorithm")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Algorithm", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-Signature")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-Signature", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-SignedHeaders", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-Credential")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-Credential", valid_617633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617635: Call_PutLoggingOptions_617624; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_617635.validator(path, query, header, formData, body, _)
  let scheme = call_617635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617635.url(scheme.get, call_617635.host, call_617635.base,
                         call_617635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617635, url, valid, _)

proc call*(call_617636: Call_PutLoggingOptions_617624; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_617637 = newJObject()
  if body != nil:
    body_617637 = body
  result = call_617636.call(nil, nil, nil, nil, body_617637)

var putLoggingOptions* = Call_PutLoggingOptions_617624(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_617625, base: "/",
    url: url_PutLoggingOptions_617626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_617612 = ref object of OpenApiRestCall_616866
proc url_DescribeLoggingOptions_617614(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_617613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieves the current settings of the AWS IoT Events logging options.
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
  var valid_617615 = header.getOrDefault("X-Amz-Date")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "X-Amz-Date", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Security-Token")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Security-Token", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Content-Sha256", valid_617617
  var valid_617618 = header.getOrDefault("X-Amz-Algorithm")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "X-Amz-Algorithm", valid_617618
  var valid_617619 = header.getOrDefault("X-Amz-Signature")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-Signature", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-SignedHeaders", valid_617620
  var valid_617621 = header.getOrDefault("X-Amz-Credential")
  valid_617621 = validateParameter(valid_617621, JString, required = false,
                                 default = nil)
  if valid_617621 != nil:
    section.add "X-Amz-Credential", valid_617621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617622: Call_DescribeLoggingOptions_617612; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_617622.validator(path, query, header, formData, body, _)
  let scheme = call_617622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617622.url(scheme.get, call_617622.host, call_617622.base,
                         call_617622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617622, url, valid, _)

proc call*(call_617623: Call_DescribeLoggingOptions_617612): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_617623.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_617612(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_617613, base: "/",
    url: url_DescribeLoggingOptions_617614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_617638 = ref object of OpenApiRestCall_616866
proc url_ListDetectorModelVersions_617640(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDetectorModelVersions_617639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617641 = path.getOrDefault("detectorModelName")
  valid_617641 = validateParameter(valid_617641, JString, required = true,
                                 default = nil)
  if valid_617641 != nil:
    section.add "detectorModelName", valid_617641
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_617642 = query.getOrDefault("maxResults")
  valid_617642 = validateParameter(valid_617642, JInt, required = false, default = nil)
  if valid_617642 != nil:
    section.add "maxResults", valid_617642
  var valid_617643 = query.getOrDefault("nextToken")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "nextToken", valid_617643
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
  var valid_617644 = header.getOrDefault("X-Amz-Date")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-Date", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Security-Token")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Security-Token", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-Content-Sha256", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Algorithm")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Algorithm", valid_617647
  var valid_617648 = header.getOrDefault("X-Amz-Signature")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "X-Amz-Signature", valid_617648
  var valid_617649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-SignedHeaders", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-Credential")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-Credential", valid_617650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617651: Call_ListDetectorModelVersions_617638;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_617651.validator(path, query, header, formData, body, _)
  let scheme = call_617651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617651.url(scheme.get, call_617651.host, call_617651.base,
                         call_617651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617651, url, valid, _)

proc call*(call_617652: Call_ListDetectorModelVersions_617638;
          detectorModelName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  var path_617653 = newJObject()
  var query_617654 = newJObject()
  add(query_617654, "maxResults", newJInt(maxResults))
  add(query_617654, "nextToken", newJString(nextToken))
  add(path_617653, "detectorModelName", newJString(detectorModelName))
  result = call_617652.call(path_617653, query_617654, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_617638(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_617639, base: "/",
    url: url_ListDetectorModelVersions_617640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617669 = ref object of OpenApiRestCall_616866
proc url_TagResource_617671(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617670(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617672 = query.getOrDefault("resourceArn")
  valid_617672 = validateParameter(valid_617672, JString, required = true,
                                 default = nil)
  if valid_617672 != nil:
    section.add "resourceArn", valid_617672
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
  var valid_617673 = header.getOrDefault("X-Amz-Date")
  valid_617673 = validateParameter(valid_617673, JString, required = false,
                                 default = nil)
  if valid_617673 != nil:
    section.add "X-Amz-Date", valid_617673
  var valid_617674 = header.getOrDefault("X-Amz-Security-Token")
  valid_617674 = validateParameter(valid_617674, JString, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "X-Amz-Security-Token", valid_617674
  var valid_617675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Content-Sha256", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Algorithm")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-Algorithm", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Signature")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Signature", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-SignedHeaders", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Credential")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Credential", valid_617679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617681: Call_TagResource_617669; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_617681.validator(path, query, header, formData, body, _)
  let scheme = call_617681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617681.url(scheme.get, call_617681.host, call_617681.base,
                         call_617681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617681, url, valid, _)

proc call*(call_617682: Call_TagResource_617669; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var query_617683 = newJObject()
  var body_617684 = newJObject()
  add(query_617683, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_617684 = body
  result = call_617682.call(nil, query_617683, nil, nil, body_617684)

var tagResource* = Call_TagResource_617669(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_617670,
                                        base: "/", url: url_TagResource_617671,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617655 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617657(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617656(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617658 = query.getOrDefault("resourceArn")
  valid_617658 = validateParameter(valid_617658, JString, required = true,
                                 default = nil)
  if valid_617658 != nil:
    section.add "resourceArn", valid_617658
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
  var valid_617659 = header.getOrDefault("X-Amz-Date")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "X-Amz-Date", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-Security-Token")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Security-Token", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Content-Sha256", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Algorithm")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Algorithm", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Signature")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Signature", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-SignedHeaders", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-Credential")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-Credential", valid_617665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617666: Call_ListTagsForResource_617655; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_617666.validator(path, query, header, formData, body, _)
  let scheme = call_617666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617666.url(scheme.get, call_617666.host, call_617666.base,
                         call_617666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617666, url, valid, _)

proc call*(call_617667: Call_ListTagsForResource_617655; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_617668 = newJObject()
  add(query_617668, "resourceArn", newJString(resourceArn))
  result = call_617667.call(nil, query_617668, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_617655(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_617656, base: "/",
    url: url_ListTagsForResource_617657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617685 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617687(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617686(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617688 = query.getOrDefault("tagKeys")
  valid_617688 = validateParameter(valid_617688, JArray, required = true, default = nil)
  if valid_617688 != nil:
    section.add "tagKeys", valid_617688
  var valid_617689 = query.getOrDefault("resourceArn")
  valid_617689 = validateParameter(valid_617689, JString, required = true,
                                 default = nil)
  if valid_617689 != nil:
    section.add "resourceArn", valid_617689
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
  var valid_617690 = header.getOrDefault("X-Amz-Date")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Date", valid_617690
  var valid_617691 = header.getOrDefault("X-Amz-Security-Token")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-Security-Token", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Content-Sha256", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Algorithm")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Algorithm", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Signature")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Signature", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-SignedHeaders", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Credential")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-Credential", valid_617696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617697: Call_UntagResource_617685; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_617697.validator(path, query, header, formData, body, _)
  let scheme = call_617697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617697.url(scheme.get, call_617697.host, call_617697.base,
                         call_617697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617697, url, valid, _)

proc call*(call_617698: Call_UntagResource_617685; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_617699 = newJObject()
  if tagKeys != nil:
    query_617699.add "tagKeys", tagKeys
  add(query_617699, "resourceArn", newJString(resourceArn))
  result = call_617698.call(nil, query_617699, nil, nil, nil)

var untagResource* = Call_UntagResource_617685(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_617686,
    base: "/", url: url_UntagResource_617687, schemes: {Scheme.Https, Scheme.Http})
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
