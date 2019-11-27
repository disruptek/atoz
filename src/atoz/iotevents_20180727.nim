
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateDetectorModel_599962 = ref object of OpenApiRestCall_599368
proc url_CreateDetectorModel_599964(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorModel_599963(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599965 = header.getOrDefault("X-Amz-Date")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Date", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Security-Token")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Security-Token", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Content-Sha256", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Algorithm")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Algorithm", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Signature")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Signature", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-SignedHeaders", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Credential")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Credential", valid_599971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_CreateDetectorModel_599962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_CreateDetectorModel_599962; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_599975 = newJObject()
  if body != nil:
    body_599975 = body
  result = call_599974.call(nil, nil, nil, nil, body_599975)

var createDetectorModel* = Call_CreateDetectorModel_599962(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_599963, base: "/",
    url: url_CreateDetectorModel_599964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_599705 = ref object of OpenApiRestCall_599368
proc url_ListDetectorModels_599707(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectorModels_599706(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_599819 = query.getOrDefault("maxResults")
  valid_599819 = validateParameter(valid_599819, JInt, required = false, default = nil)
  if valid_599819 != nil:
    section.add "maxResults", valid_599819
  var valid_599820 = query.getOrDefault("nextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "nextToken", valid_599820
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
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Content-Sha256", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Algorithm")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Algorithm", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Signature")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Signature", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-SignedHeaders", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Credential")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Credential", valid_599827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599850: Call_ListDetectorModels_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_599850.validator(path, query, header, formData, body)
  let scheme = call_599850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599850.url(scheme.get, call_599850.host, call_599850.base,
                         call_599850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599850, url, valid)

proc call*(call_599921: Call_ListDetectorModels_599705; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_599922 = newJObject()
  add(query_599922, "maxResults", newJInt(maxResults))
  add(query_599922, "nextToken", newJString(nextToken))
  result = call_599921.call(nil, query_599922, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_599705(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_599706, base: "/",
    url: url_ListDetectorModels_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_599991 = ref object of OpenApiRestCall_599368
proc url_CreateInput_599993(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_599992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599994 = header.getOrDefault("X-Amz-Date")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Date", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Security-Token")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Security-Token", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_CreateInput_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an input.
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_CreateInput_599991; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_600004 = newJObject()
  if body != nil:
    body_600004 = body
  result = call_600003.call(nil, nil, nil, nil, body_600004)

var createInput* = Call_CreateInput_599991(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_599992,
                                        base: "/", url: url_CreateInput_599993,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_599976 = ref object of OpenApiRestCall_599368
proc url_ListInputs_599978(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_599977(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599979 = query.getOrDefault("maxResults")
  valid_599979 = validateParameter(valid_599979, JInt, required = false, default = nil)
  if valid_599979 != nil:
    section.add "maxResults", valid_599979
  var valid_599980 = query.getOrDefault("nextToken")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "nextToken", valid_599980
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
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Content-Sha256", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Algorithm")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Algorithm", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Signature")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Signature", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-SignedHeaders", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599988: Call_ListInputs_599976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_599988.validator(path, query, header, formData, body)
  let scheme = call_599988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599988.url(scheme.get, call_599988.host, call_599988.base,
                         call_599988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599988, url, valid)

proc call*(call_599989: Call_ListInputs_599976; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_599990 = newJObject()
  add(query_599990, "maxResults", newJInt(maxResults))
  add(query_599990, "nextToken", newJString(nextToken))
  result = call_599989.call(nil, query_599990, nil, nil, nil)

var listInputs* = Call_ListInputs_599976(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_599977,
                                      base: "/", url: url_ListInputs_599978,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_600035 = ref object of OpenApiRestCall_599368
proc url_UpdateDetectorModel_600037(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetectorModel_600036(path: JsonNode; query: JsonNode;
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
  var valid_600038 = path.getOrDefault("detectorModelName")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = nil)
  if valid_600038 != nil:
    section.add "detectorModelName", valid_600038
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
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_UpdateDetectorModel_600035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_UpdateDetectorModel_600035; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_600049 = newJObject()
  var body_600050 = newJObject()
  add(path_600049, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_600050 = body
  result = call_600048.call(path_600049, nil, nil, nil, body_600050)

var updateDetectorModel* = Call_UpdateDetectorModel_600035(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_600036, base: "/",
    url: url_UpdateDetectorModel_600037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_600005 = ref object of OpenApiRestCall_599368
proc url_DescribeDetectorModel_600007(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetectorModel_600006(path: JsonNode; query: JsonNode;
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
  var valid_600022 = path.getOrDefault("detectorModelName")
  valid_600022 = validateParameter(valid_600022, JString, required = true,
                                 default = nil)
  if valid_600022 != nil:
    section.add "detectorModelName", valid_600022
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_600023 = query.getOrDefault("version")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "version", valid_600023
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
  var valid_600024 = header.getOrDefault("X-Amz-Date")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Date", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Security-Token")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Security-Token", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DescribeDetectorModel_600005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DescribeDetectorModel_600005;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_600033 = newJObject()
  var query_600034 = newJObject()
  add(path_600033, "detectorModelName", newJString(detectorModelName))
  add(query_600034, "version", newJString(version))
  result = call_600032.call(path_600033, query_600034, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_600005(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_600006, base: "/",
    url: url_DescribeDetectorModel_600007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_600051 = ref object of OpenApiRestCall_599368
proc url_DeleteDetectorModel_600053(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetectorModel_600052(path: JsonNode; query: JsonNode;
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
  var valid_600054 = path.getOrDefault("detectorModelName")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = nil)
  if valid_600054 != nil:
    section.add "detectorModelName", valid_600054
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
  var valid_600055 = header.getOrDefault("X-Amz-Date")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Date", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Security-Token")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Security-Token", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Content-Sha256", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Algorithm")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Algorithm", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Signature")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Signature", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-SignedHeaders", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Credential")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Credential", valid_600061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_DeleteDetectorModel_600051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_DeleteDetectorModel_600051; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_600064 = newJObject()
  add(path_600064, "detectorModelName", newJString(detectorModelName))
  result = call_600063.call(path_600064, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_600051(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_600052, base: "/",
    url: url_DeleteDetectorModel_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_600079 = ref object of OpenApiRestCall_599368
proc url_UpdateInput_600081(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInput_600080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600082 = path.getOrDefault("inputName")
  valid_600082 = validateParameter(valid_600082, JString, required = true,
                                 default = nil)
  if valid_600082 != nil:
    section.add "inputName", valid_600082
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_UpdateInput_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_UpdateInput_600079; inputName: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  ##   body: JObject (required)
  var path_600093 = newJObject()
  var body_600094 = newJObject()
  add(path_600093, "inputName", newJString(inputName))
  if body != nil:
    body_600094 = body
  result = call_600092.call(path_600093, nil, nil, nil, body_600094)

var updateInput* = Call_UpdateInput_600079(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_600080,
                                        base: "/", url: url_UpdateInput_600081,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_600065 = ref object of OpenApiRestCall_599368
proc url_DescribeInput_600067(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInput_600066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600068 = path.getOrDefault("inputName")
  valid_600068 = validateParameter(valid_600068, JString, required = true,
                                 default = nil)
  if valid_600068 != nil:
    section.add "inputName", valid_600068
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
  var valid_600069 = header.getOrDefault("X-Amz-Date")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Date", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Security-Token")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Security-Token", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Content-Sha256", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Algorithm")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Algorithm", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Signature")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Signature", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-SignedHeaders", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Credential")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Credential", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DescribeInput_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an input.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DescribeInput_600065; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_600078 = newJObject()
  add(path_600078, "inputName", newJString(inputName))
  result = call_600077.call(path_600078, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_600065(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_600066,
    base: "/", url: url_DescribeInput_600067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_600095 = ref object of OpenApiRestCall_599368
proc url_DeleteInput_600097(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInput_600096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600098 = path.getOrDefault("inputName")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = nil)
  if valid_600098 != nil:
    section.add "inputName", valid_600098
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
  var valid_600099 = header.getOrDefault("X-Amz-Date")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Date", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Security-Token")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Security-Token", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DeleteInput_600095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DeleteInput_600095; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_600108 = newJObject()
  add(path_600108, "inputName", newJString(inputName))
  result = call_600107.call(path_600108, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_600095(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_600096,
                                        base: "/", url: url_DeleteInput_600097,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_600121 = ref object of OpenApiRestCall_599368
proc url_PutLoggingOptions_600123(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_600122(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600124 = header.getOrDefault("X-Amz-Date")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Date", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Security-Token")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Security-Token", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Content-Sha256", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Algorithm")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Algorithm", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Signature")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Signature", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-SignedHeaders", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Credential")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Credential", valid_600130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600132: Call_PutLoggingOptions_600121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_600132.validator(path, query, header, formData, body)
  let scheme = call_600132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600132.url(scheme.get, call_600132.host, call_600132.base,
                         call_600132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600132, url, valid)

proc call*(call_600133: Call_PutLoggingOptions_600121; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_600134 = newJObject()
  if body != nil:
    body_600134 = body
  result = call_600133.call(nil, nil, nil, nil, body_600134)

var putLoggingOptions* = Call_PutLoggingOptions_600121(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_600122, base: "/",
    url: url_PutLoggingOptions_600123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_600109 = ref object of OpenApiRestCall_599368
proc url_DescribeLoggingOptions_600111(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_600110(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600119: Call_DescribeLoggingOptions_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_600119.validator(path, query, header, formData, body)
  let scheme = call_600119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600119.url(scheme.get, call_600119.host, call_600119.base,
                         call_600119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600119, url, valid)

proc call*(call_600120: Call_DescribeLoggingOptions_600109): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_600120.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_600109(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_600110, base: "/",
    url: url_DescribeLoggingOptions_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_600135 = ref object of OpenApiRestCall_599368
proc url_ListDetectorModelVersions_600137(protocol: Scheme; host: string;
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

proc validate_ListDetectorModelVersions_600136(path: JsonNode; query: JsonNode;
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
  var valid_600138 = path.getOrDefault("detectorModelName")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "detectorModelName", valid_600138
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_600139 = query.getOrDefault("maxResults")
  valid_600139 = validateParameter(valid_600139, JInt, required = false, default = nil)
  if valid_600139 != nil:
    section.add "maxResults", valid_600139
  var valid_600140 = query.getOrDefault("nextToken")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "nextToken", valid_600140
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
  var valid_600141 = header.getOrDefault("X-Amz-Date")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Date", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Security-Token")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Security-Token", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Content-Sha256", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Algorithm")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Algorithm", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Signature")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Signature", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-SignedHeaders", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Credential")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Credential", valid_600147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600148: Call_ListDetectorModelVersions_600135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_600148.validator(path, query, header, formData, body)
  let scheme = call_600148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600148.url(scheme.get, call_600148.host, call_600148.base,
                         call_600148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600148, url, valid)

proc call*(call_600149: Call_ListDetectorModelVersions_600135;
          detectorModelName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  var path_600150 = newJObject()
  var query_600151 = newJObject()
  add(query_600151, "maxResults", newJInt(maxResults))
  add(query_600151, "nextToken", newJString(nextToken))
  add(path_600150, "detectorModelName", newJString(detectorModelName))
  result = call_600149.call(path_600150, query_600151, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_600135(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_600136, base: "/",
    url: url_ListDetectorModelVersions_600137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600166 = ref object of OpenApiRestCall_599368
proc url_TagResource_600168(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600167(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600169 = query.getOrDefault("resourceArn")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "resourceArn", valid_600169
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
  var valid_600170 = header.getOrDefault("X-Amz-Date")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Date", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Security-Token")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Security-Token", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Content-Sha256", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Algorithm")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Algorithm", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Signature")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Signature", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-SignedHeaders", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Credential")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Credential", valid_600176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600178: Call_TagResource_600166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_600178.validator(path, query, header, formData, body)
  let scheme = call_600178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600178.url(scheme.get, call_600178.host, call_600178.base,
                         call_600178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600178, url, valid)

proc call*(call_600179: Call_TagResource_600166; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var query_600180 = newJObject()
  var body_600181 = newJObject()
  add(query_600180, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_600181 = body
  result = call_600179.call(nil, query_600180, nil, nil, body_600181)

var tagResource* = Call_TagResource_600166(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_600167,
                                        base: "/", url: url_TagResource_600168,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600152 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600154(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600153(path: JsonNode; query: JsonNode;
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
  var valid_600155 = query.getOrDefault("resourceArn")
  valid_600155 = validateParameter(valid_600155, JString, required = true,
                                 default = nil)
  if valid_600155 != nil:
    section.add "resourceArn", valid_600155
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
  var valid_600156 = header.getOrDefault("X-Amz-Date")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Date", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Security-Token")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Security-Token", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Content-Sha256", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Algorithm")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Algorithm", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Signature")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Signature", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-SignedHeaders", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Credential")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Credential", valid_600162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600163: Call_ListTagsForResource_600152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_600163.validator(path, query, header, formData, body)
  let scheme = call_600163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600163.url(scheme.get, call_600163.host, call_600163.base,
                         call_600163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600163, url, valid)

proc call*(call_600164: Call_ListTagsForResource_600152; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_600165 = newJObject()
  add(query_600165, "resourceArn", newJString(resourceArn))
  result = call_600164.call(nil, query_600165, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600152(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_600153, base: "/",
    url: url_ListTagsForResource_600154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600182 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600184(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600183(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the given tags (metadata) from the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_600185 = query.getOrDefault("resourceArn")
  valid_600185 = validateParameter(valid_600185, JString, required = true,
                                 default = nil)
  if valid_600185 != nil:
    section.add "resourceArn", valid_600185
  var valid_600186 = query.getOrDefault("tagKeys")
  valid_600186 = validateParameter(valid_600186, JArray, required = true, default = nil)
  if valid_600186 != nil:
    section.add "tagKeys", valid_600186
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Content-Sha256", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Algorithm")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Algorithm", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Signature")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Signature", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-SignedHeaders", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Credential")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Credential", valid_600193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_UntagResource_600182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_UntagResource_600182; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  var query_600196 = newJObject()
  add(query_600196, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_600196.add "tagKeys", tagKeys
  result = call_600195.call(nil, query_600196, nil, nil, nil)

var untagResource* = Call_UntagResource_600182(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_600183,
    base: "/", url: url_UntagResource_600184, schemes: {Scheme.Https, Scheme.Http})
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
