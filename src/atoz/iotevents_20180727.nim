
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDetectorModel_590960 = ref object of OpenApiRestCall_590364
proc url_CreateDetectorModel_590962(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDetectorModel_590961(path: JsonNode; query: JsonNode;
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
  var valid_590963 = header.getOrDefault("X-Amz-Signature")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Signature", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Content-Sha256", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Date")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Date", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Credential")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Credential", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-Security-Token")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-Security-Token", valid_590967
  var valid_590968 = header.getOrDefault("X-Amz-Algorithm")
  valid_590968 = validateParameter(valid_590968, JString, required = false,
                                 default = nil)
  if valid_590968 != nil:
    section.add "X-Amz-Algorithm", valid_590968
  var valid_590969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590969 = validateParameter(valid_590969, JString, required = false,
                                 default = nil)
  if valid_590969 != nil:
    section.add "X-Amz-SignedHeaders", valid_590969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590971: Call_CreateDetectorModel_590960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_590971.validator(path, query, header, formData, body)
  let scheme = call_590971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590971.url(scheme.get, call_590971.host, call_590971.base,
                         call_590971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590971, url, valid)

proc call*(call_590972: Call_CreateDetectorModel_590960; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_590973 = newJObject()
  if body != nil:
    body_590973 = body
  result = call_590972.call(nil, nil, nil, nil, body_590973)

var createDetectorModel* = Call_CreateDetectorModel_590960(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_590961, base: "/",
    url: url_CreateDetectorModel_590962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_590703 = ref object of OpenApiRestCall_590364
proc url_ListDetectorModels_590705(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDetectorModels_590704(path: JsonNode; query: JsonNode;
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
  var valid_590817 = query.getOrDefault("nextToken")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "nextToken", valid_590817
  var valid_590818 = query.getOrDefault("maxResults")
  valid_590818 = validateParameter(valid_590818, JInt, required = false, default = nil)
  if valid_590818 != nil:
    section.add "maxResults", valid_590818
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
  var valid_590819 = header.getOrDefault("X-Amz-Signature")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Signature", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Content-Sha256", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Date")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Date", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Credential")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Credential", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-Security-Token")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-Security-Token", valid_590823
  var valid_590824 = header.getOrDefault("X-Amz-Algorithm")
  valid_590824 = validateParameter(valid_590824, JString, required = false,
                                 default = nil)
  if valid_590824 != nil:
    section.add "X-Amz-Algorithm", valid_590824
  var valid_590825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590825 = validateParameter(valid_590825, JString, required = false,
                                 default = nil)
  if valid_590825 != nil:
    section.add "X-Amz-SignedHeaders", valid_590825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590848: Call_ListDetectorModels_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_590848.validator(path, query, header, formData, body)
  let scheme = call_590848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590848.url(scheme.get, call_590848.host, call_590848.base,
                         call_590848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590848, url, valid)

proc call*(call_590919: Call_ListDetectorModels_590703; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_590920 = newJObject()
  add(query_590920, "nextToken", newJString(nextToken))
  add(query_590920, "maxResults", newJInt(maxResults))
  result = call_590919.call(nil, query_590920, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_590703(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_590704, base: "/",
    url: url_ListDetectorModels_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_590989 = ref object of OpenApiRestCall_590364
proc url_CreateInput_590991(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInput_590990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590992 = header.getOrDefault("X-Amz-Signature")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Signature", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Content-Sha256", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Date")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Date", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Credential")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Credential", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Security-Token")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Security-Token", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Algorithm")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Algorithm", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-SignedHeaders", valid_590998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591000: Call_CreateInput_590989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an input.
  ## 
  let valid = call_591000.validator(path, query, header, formData, body)
  let scheme = call_591000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591000.url(scheme.get, call_591000.host, call_591000.base,
                         call_591000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591000, url, valid)

proc call*(call_591001: Call_CreateInput_590989; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_591002 = newJObject()
  if body != nil:
    body_591002 = body
  result = call_591001.call(nil, nil, nil, nil, body_591002)

var createInput* = Call_CreateInput_590989(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_590990,
                                        base: "/", url: url_CreateInput_590991,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_590974 = ref object of OpenApiRestCall_590364
proc url_ListInputs_590976(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInputs_590975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590977 = query.getOrDefault("nextToken")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "nextToken", valid_590977
  var valid_590978 = query.getOrDefault("maxResults")
  valid_590978 = validateParameter(valid_590978, JInt, required = false, default = nil)
  if valid_590978 != nil:
    section.add "maxResults", valid_590978
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
  var valid_590979 = header.getOrDefault("X-Amz-Signature")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Signature", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Content-Sha256", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Date")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Date", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Credential")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Credential", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-Security-Token")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-Security-Token", valid_590983
  var valid_590984 = header.getOrDefault("X-Amz-Algorithm")
  valid_590984 = validateParameter(valid_590984, JString, required = false,
                                 default = nil)
  if valid_590984 != nil:
    section.add "X-Amz-Algorithm", valid_590984
  var valid_590985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590985 = validateParameter(valid_590985, JString, required = false,
                                 default = nil)
  if valid_590985 != nil:
    section.add "X-Amz-SignedHeaders", valid_590985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590986: Call_ListInputs_590974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_590986.validator(path, query, header, formData, body)
  let scheme = call_590986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590986.url(scheme.get, call_590986.host, call_590986.base,
                         call_590986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590986, url, valid)

proc call*(call_590987: Call_ListInputs_590974; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var query_590988 = newJObject()
  add(query_590988, "nextToken", newJString(nextToken))
  add(query_590988, "maxResults", newJInt(maxResults))
  result = call_590987.call(nil, query_590988, nil, nil, nil)

var listInputs* = Call_ListInputs_590974(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_590975,
                                      base: "/", url: url_ListInputs_590976,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_591033 = ref object of OpenApiRestCall_590364
proc url_UpdateDetectorModel_591035(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDetectorModel_591034(path: JsonNode; query: JsonNode;
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
  var valid_591036 = path.getOrDefault("detectorModelName")
  valid_591036 = validateParameter(valid_591036, JString, required = true,
                                 default = nil)
  if valid_591036 != nil:
    section.add "detectorModelName", valid_591036
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
  var valid_591037 = header.getOrDefault("X-Amz-Signature")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Signature", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Content-Sha256", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Date")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Date", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Credential")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Credential", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Security-Token")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Security-Token", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Algorithm")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Algorithm", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-SignedHeaders", valid_591043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591045: Call_UpdateDetectorModel_591033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_591045.validator(path, query, header, formData, body)
  let scheme = call_591045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591045.url(scheme.get, call_591045.host, call_591045.base,
                         call_591045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591045, url, valid)

proc call*(call_591046: Call_UpdateDetectorModel_591033; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_591047 = newJObject()
  var body_591048 = newJObject()
  add(path_591047, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_591048 = body
  result = call_591046.call(path_591047, nil, nil, nil, body_591048)

var updateDetectorModel* = Call_UpdateDetectorModel_591033(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_591034, base: "/",
    url: url_UpdateDetectorModel_591035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_591003 = ref object of OpenApiRestCall_590364
proc url_DescribeDetectorModel_591005(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeDetectorModel_591004(path: JsonNode; query: JsonNode;
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
  var valid_591020 = path.getOrDefault("detectorModelName")
  valid_591020 = validateParameter(valid_591020, JString, required = true,
                                 default = nil)
  if valid_591020 != nil:
    section.add "detectorModelName", valid_591020
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_591021 = query.getOrDefault("version")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "version", valid_591021
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
  var valid_591022 = header.getOrDefault("X-Amz-Signature")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Signature", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Content-Sha256", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Date")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Date", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Credential")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Credential", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Security-Token")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Security-Token", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Algorithm")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Algorithm", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-SignedHeaders", valid_591028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_DescribeDetectorModel_591003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_DescribeDetectorModel_591003;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_591031 = newJObject()
  var query_591032 = newJObject()
  add(path_591031, "detectorModelName", newJString(detectorModelName))
  add(query_591032, "version", newJString(version))
  result = call_591030.call(path_591031, query_591032, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_591003(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_591004, base: "/",
    url: url_DescribeDetectorModel_591005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_591049 = ref object of OpenApiRestCall_590364
proc url_DeleteDetectorModel_591051(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDetectorModel_591050(path: JsonNode; query: JsonNode;
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
  var valid_591052 = path.getOrDefault("detectorModelName")
  valid_591052 = validateParameter(valid_591052, JString, required = true,
                                 default = nil)
  if valid_591052 != nil:
    section.add "detectorModelName", valid_591052
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
  var valid_591053 = header.getOrDefault("X-Amz-Signature")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Signature", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Content-Sha256", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Date")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Date", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Credential")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Credential", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Security-Token")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Security-Token", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-Algorithm")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Algorithm", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-SignedHeaders", valid_591059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591060: Call_DeleteDetectorModel_591049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_591060.validator(path, query, header, formData, body)
  let scheme = call_591060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591060.url(scheme.get, call_591060.host, call_591060.base,
                         call_591060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591060, url, valid)

proc call*(call_591061: Call_DeleteDetectorModel_591049; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_591062 = newJObject()
  add(path_591062, "detectorModelName", newJString(detectorModelName))
  result = call_591061.call(path_591062, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_591049(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_591050, base: "/",
    url: url_DeleteDetectorModel_591051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_591077 = ref object of OpenApiRestCall_590364
proc url_UpdateInput_591079(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateInput_591078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591080 = path.getOrDefault("inputName")
  valid_591080 = validateParameter(valid_591080, JString, required = true,
                                 default = nil)
  if valid_591080 != nil:
    section.add "inputName", valid_591080
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
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_UpdateInput_591077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_UpdateInput_591077; body: JsonNode; inputName: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  var path_591091 = newJObject()
  var body_591092 = newJObject()
  if body != nil:
    body_591092 = body
  add(path_591091, "inputName", newJString(inputName))
  result = call_591090.call(path_591091, nil, nil, nil, body_591092)

var updateInput* = Call_UpdateInput_591077(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_591078,
                                        base: "/", url: url_UpdateInput_591079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_591063 = ref object of OpenApiRestCall_590364
proc url_DescribeInput_591065(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeInput_591064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591066 = path.getOrDefault("inputName")
  valid_591066 = validateParameter(valid_591066, JString, required = true,
                                 default = nil)
  if valid_591066 != nil:
    section.add "inputName", valid_591066
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
  var valid_591067 = header.getOrDefault("X-Amz-Signature")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Signature", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Content-Sha256", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Date")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Date", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Credential")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Credential", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Security-Token")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Security-Token", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Algorithm")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Algorithm", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-SignedHeaders", valid_591073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_DescribeInput_591063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an input.
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_DescribeInput_591063; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_591076 = newJObject()
  add(path_591076, "inputName", newJString(inputName))
  result = call_591075.call(path_591076, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_591063(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_591064,
    base: "/", url: url_DescribeInput_591065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_591093 = ref object of OpenApiRestCall_590364
proc url_DeleteInput_591095(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteInput_591094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591096 = path.getOrDefault("inputName")
  valid_591096 = validateParameter(valid_591096, JString, required = true,
                                 default = nil)
  if valid_591096 != nil:
    section.add "inputName", valid_591096
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
  var valid_591097 = header.getOrDefault("X-Amz-Signature")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Signature", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Content-Sha256", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Date")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Date", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Credential")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Credential", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Security-Token")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Security-Token", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Algorithm")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Algorithm", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-SignedHeaders", valid_591103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_DeleteInput_591093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_DeleteInput_591093; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_591106 = newJObject()
  add(path_591106, "inputName", newJString(inputName))
  result = call_591105.call(path_591106, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_591093(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_591094,
                                        base: "/", url: url_DeleteInput_591095,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_591119 = ref object of OpenApiRestCall_590364
proc url_PutLoggingOptions_591121(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLoggingOptions_591120(path: JsonNode; query: JsonNode;
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
  var valid_591122 = header.getOrDefault("X-Amz-Signature")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = nil)
  if valid_591122 != nil:
    section.add "X-Amz-Signature", valid_591122
  var valid_591123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-Content-Sha256", valid_591123
  var valid_591124 = header.getOrDefault("X-Amz-Date")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "X-Amz-Date", valid_591124
  var valid_591125 = header.getOrDefault("X-Amz-Credential")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-Credential", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Security-Token")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Security-Token", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Algorithm")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Algorithm", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-SignedHeaders", valid_591128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591130: Call_PutLoggingOptions_591119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_591130.validator(path, query, header, formData, body)
  let scheme = call_591130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591130.url(scheme.get, call_591130.host, call_591130.base,
                         call_591130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591130, url, valid)

proc call*(call_591131: Call_PutLoggingOptions_591119; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_591132 = newJObject()
  if body != nil:
    body_591132 = body
  result = call_591131.call(nil, nil, nil, nil, body_591132)

var putLoggingOptions* = Call_PutLoggingOptions_591119(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_591120, base: "/",
    url: url_PutLoggingOptions_591121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_591107 = ref object of OpenApiRestCall_590364
proc url_DescribeLoggingOptions_591109(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLoggingOptions_591108(path: JsonNode; query: JsonNode;
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
  var valid_591110 = header.getOrDefault("X-Amz-Signature")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Signature", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Content-Sha256", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Date")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Date", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Credential")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Credential", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Security-Token")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Security-Token", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Algorithm")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Algorithm", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-SignedHeaders", valid_591116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591117: Call_DescribeLoggingOptions_591107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_591117.validator(path, query, header, formData, body)
  let scheme = call_591117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591117.url(scheme.get, call_591117.host, call_591117.base,
                         call_591117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591117, url, valid)

proc call*(call_591118: Call_DescribeLoggingOptions_591107): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_591118.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_591107(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_591108, base: "/",
    url: url_DescribeLoggingOptions_591109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_591133 = ref object of OpenApiRestCall_590364
proc url_ListDetectorModelVersions_591135(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListDetectorModelVersions_591134(path: JsonNode; query: JsonNode;
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
  var valid_591136 = path.getOrDefault("detectorModelName")
  valid_591136 = validateParameter(valid_591136, JString, required = true,
                                 default = nil)
  if valid_591136 != nil:
    section.add "detectorModelName", valid_591136
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  section = newJObject()
  var valid_591137 = query.getOrDefault("nextToken")
  valid_591137 = validateParameter(valid_591137, JString, required = false,
                                 default = nil)
  if valid_591137 != nil:
    section.add "nextToken", valid_591137
  var valid_591138 = query.getOrDefault("maxResults")
  valid_591138 = validateParameter(valid_591138, JInt, required = false, default = nil)
  if valid_591138 != nil:
    section.add "maxResults", valid_591138
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
  var valid_591139 = header.getOrDefault("X-Amz-Signature")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "X-Amz-Signature", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Content-Sha256", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Date")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Date", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Credential")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Credential", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Security-Token")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Security-Token", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Algorithm")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Algorithm", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-SignedHeaders", valid_591145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591146: Call_ListDetectorModelVersions_591133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_591146.validator(path, query, header, formData, body)
  let scheme = call_591146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591146.url(scheme.get, call_591146.host, call_591146.base,
                         call_591146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591146, url, valid)

proc call*(call_591147: Call_ListDetectorModelVersions_591133;
          detectorModelName: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  var path_591148 = newJObject()
  var query_591149 = newJObject()
  add(query_591149, "nextToken", newJString(nextToken))
  add(path_591148, "detectorModelName", newJString(detectorModelName))
  add(query_591149, "maxResults", newJInt(maxResults))
  result = call_591147.call(path_591148, query_591149, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_591133(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_591134, base: "/",
    url: url_ListDetectorModelVersions_591135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591164 = ref object of OpenApiRestCall_590364
proc url_TagResource_591166(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591167 = query.getOrDefault("resourceArn")
  valid_591167 = validateParameter(valid_591167, JString, required = true,
                                 default = nil)
  if valid_591167 != nil:
    section.add "resourceArn", valid_591167
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
  var valid_591168 = header.getOrDefault("X-Amz-Signature")
  valid_591168 = validateParameter(valid_591168, JString, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "X-Amz-Signature", valid_591168
  var valid_591169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591169 = validateParameter(valid_591169, JString, required = false,
                                 default = nil)
  if valid_591169 != nil:
    section.add "X-Amz-Content-Sha256", valid_591169
  var valid_591170 = header.getOrDefault("X-Amz-Date")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Date", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Credential")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Credential", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Security-Token")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Security-Token", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Algorithm")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Algorithm", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-SignedHeaders", valid_591174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591176: Call_TagResource_591164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_591176.validator(path, query, header, formData, body)
  let scheme = call_591176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591176.url(scheme.get, call_591176.host, call_591176.base,
                         call_591176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591176, url, valid)

proc call*(call_591177: Call_TagResource_591164; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_591178 = newJObject()
  var body_591179 = newJObject()
  if body != nil:
    body_591179 = body
  add(query_591178, "resourceArn", newJString(resourceArn))
  result = call_591177.call(nil, query_591178, nil, nil, body_591179)

var tagResource* = Call_TagResource_591164(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_591165,
                                        base: "/", url: url_TagResource_591166,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591150 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591152(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591151(path: JsonNode; query: JsonNode;
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
  var valid_591153 = query.getOrDefault("resourceArn")
  valid_591153 = validateParameter(valid_591153, JString, required = true,
                                 default = nil)
  if valid_591153 != nil:
    section.add "resourceArn", valid_591153
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
  var valid_591154 = header.getOrDefault("X-Amz-Signature")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Signature", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Content-Sha256", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Date")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Date", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Credential")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Credential", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Security-Token")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Security-Token", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Algorithm")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Algorithm", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-SignedHeaders", valid_591160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591161: Call_ListTagsForResource_591150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_591161.validator(path, query, header, formData, body)
  let scheme = call_591161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591161.url(scheme.get, call_591161.host, call_591161.base,
                         call_591161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591161, url, valid)

proc call*(call_591162: Call_ListTagsForResource_591150; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_591163 = newJObject()
  add(query_591163, "resourceArn", newJString(resourceArn))
  result = call_591162.call(nil, query_591163, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591150(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_591151, base: "/",
    url: url_ListTagsForResource_591152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591180 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591182(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591183 = query.getOrDefault("tagKeys")
  valid_591183 = validateParameter(valid_591183, JArray, required = true, default = nil)
  if valid_591183 != nil:
    section.add "tagKeys", valid_591183
  var valid_591184 = query.getOrDefault("resourceArn")
  valid_591184 = validateParameter(valid_591184, JString, required = true,
                                 default = nil)
  if valid_591184 != nil:
    section.add "resourceArn", valid_591184
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
  var valid_591185 = header.getOrDefault("X-Amz-Signature")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Signature", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Content-Sha256", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Date")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Date", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Credential")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Credential", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Security-Token")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Security-Token", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Algorithm")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Algorithm", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-SignedHeaders", valid_591191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591192: Call_UntagResource_591180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_591192.validator(path, query, header, formData, body)
  let scheme = call_591192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591192.url(scheme.get, call_591192.host, call_591192.base,
                         call_591192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591192, url, valid)

proc call*(call_591193: Call_UntagResource_591180; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_591194 = newJObject()
  if tagKeys != nil:
    query_591194.add "tagKeys", tagKeys
  add(query_591194, "resourceArn", newJString(resourceArn))
  result = call_591193.call(nil, query_591194, nil, nil, nil)

var untagResource* = Call_UntagResource_591180(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_591181,
    base: "/", url: url_UntagResource_591182, schemes: {Scheme.Https, Scheme.Http})
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
