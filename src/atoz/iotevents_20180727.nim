
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateDetectorModel_601025 = ref object of OpenApiRestCall_600426
proc url_CreateDetectorModel_601027(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDetectorModel_601026(path: JsonNode; query: JsonNode;
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
  var valid_601028 = header.getOrDefault("X-Amz-Date")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Date", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Security-Token")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Security-Token", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_CreateDetectorModel_601025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector model.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_CreateDetectorModel_601025; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var createDetectorModel* = Call_CreateDetectorModel_601025(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_601026, base: "/",
    url: url_CreateDetectorModel_601027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_600768 = ref object of OpenApiRestCall_600426
proc url_ListDetectorModels_600770(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDetectorModels_600769(path: JsonNode; query: JsonNode;
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
  var valid_600882 = query.getOrDefault("maxResults")
  valid_600882 = validateParameter(valid_600882, JInt, required = false, default = nil)
  if valid_600882 != nil:
    section.add "maxResults", valid_600882
  var valid_600883 = query.getOrDefault("nextToken")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "nextToken", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_ListDetectorModels_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_ListDetectorModels_600768; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_600985 = newJObject()
  add(query_600985, "maxResults", newJInt(maxResults))
  add(query_600985, "nextToken", newJString(nextToken))
  result = call_600984.call(nil, query_600985, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_600768(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_600769, base: "/",
    url: url_ListDetectorModels_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_601054 = ref object of OpenApiRestCall_600426
proc url_CreateInput_601056(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInput_601055(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_CreateInput_601054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an input.
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"))
  result = hook(call_601065, url, valid)

proc call*(call_601066: Call_CreateInput_601054; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_601067 = newJObject()
  if body != nil:
    body_601067 = body
  result = call_601066.call(nil, nil, nil, nil, body_601067)

var createInput* = Call_CreateInput_601054(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs",
                                        validator: validate_CreateInput_601055,
                                        base: "/", url: url_CreateInput_601056,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_601039 = ref object of OpenApiRestCall_600426
proc url_ListInputs_601041(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInputs_601040(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601042 = query.getOrDefault("maxResults")
  valid_601042 = validateParameter(valid_601042, JInt, required = false, default = nil)
  if valid_601042 != nil:
    section.add "maxResults", valid_601042
  var valid_601043 = query.getOrDefault("nextToken")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "nextToken", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_ListInputs_601039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the inputs you have created.
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_ListInputs_601039; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  var query_601053 = newJObject()
  add(query_601053, "maxResults", newJInt(maxResults))
  add(query_601053, "nextToken", newJString(nextToken))
  result = call_601052.call(nil, query_601053, nil, nil, nil)

var listInputs* = Call_ListInputs_601039(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "iotevents.amazonaws.com",
                                      route: "/inputs",
                                      validator: validate_ListInputs_601040,
                                      base: "/", url: url_ListInputs_601041,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_601098 = ref object of OpenApiRestCall_600426
proc url_UpdateDetectorModel_601100(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDetectorModel_601099(path: JsonNode; query: JsonNode;
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
  var valid_601101 = path.getOrDefault("detectorModelName")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "detectorModelName", valid_601101
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
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_UpdateDetectorModel_601098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_UpdateDetectorModel_601098; detectorModelName: string;
          body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model that is updated.
  ##   body: JObject (required)
  var path_601112 = newJObject()
  var body_601113 = newJObject()
  add(path_601112, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_601113 = body
  result = call_601111.call(path_601112, nil, nil, nil, body_601113)

var updateDetectorModel* = Call_UpdateDetectorModel_601098(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_601099, base: "/",
    url: url_UpdateDetectorModel_601100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_601068 = ref object of OpenApiRestCall_600426
proc url_DescribeDetectorModel_601070(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDetectorModel_601069(path: JsonNode; query: JsonNode;
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
  var valid_601085 = path.getOrDefault("detectorModelName")
  valid_601085 = validateParameter(valid_601085, JString, required = true,
                                 default = nil)
  if valid_601085 != nil:
    section.add "detectorModelName", valid_601085
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
  ##          : The version of the detector model.
  section = newJObject()
  var valid_601086 = query.getOrDefault("version")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "version", valid_601086
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DescribeDetectorModel_601068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DescribeDetectorModel_601068;
          detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>"version"</code> parameter is not specified, information about the latest version is returned.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model.
  ##   version: string
  ##          : The version of the detector model.
  var path_601096 = newJObject()
  var query_601097 = newJObject()
  add(path_601096, "detectorModelName", newJString(detectorModelName))
  add(query_601097, "version", newJString(version))
  result = call_601095.call(path_601096, query_601097, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_601068(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_601069, base: "/",
    url: url_DescribeDetectorModel_601070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_601114 = ref object of OpenApiRestCall_600426
proc url_DeleteDetectorModel_601116(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
        "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
               (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDetectorModel_601115(path: JsonNode; query: JsonNode;
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
  var valid_601117 = path.getOrDefault("detectorModelName")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = nil)
  if valid_601117 != nil:
    section.add "detectorModelName", valid_601117
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
  var valid_601118 = header.getOrDefault("X-Amz-Date")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Date", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Security-Token")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Security-Token", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Content-Sha256", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Algorithm")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Algorithm", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Signature")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Signature", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-SignedHeaders", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Credential")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Credential", valid_601124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601125: Call_DeleteDetectorModel_601114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ## 
  let valid = call_601125.validator(path, query, header, formData, body)
  let scheme = call_601125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601125.url(scheme.get, call_601125.host, call_601125.base,
                         call_601125.route, valid.getOrDefault("path"))
  result = hook(call_601125, url, valid)

proc call*(call_601126: Call_DeleteDetectorModel_601114; detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model to be deleted.
  var path_601127 = newJObject()
  add(path_601127, "detectorModelName", newJString(detectorModelName))
  result = call_601126.call(path_601127, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_601114(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_601115, base: "/",
    url: url_DeleteDetectorModel_601116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_601142 = ref object of OpenApiRestCall_600426
proc url_UpdateInput_601144(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateInput_601143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601145 = path.getOrDefault("inputName")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = nil)
  if valid_601145 != nil:
    section.add "inputName", valid_601145
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
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_UpdateInput_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_UpdateInput_601142; inputName: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputName: string (required)
  ##            : The name of the input you want to update.
  ##   body: JObject (required)
  var path_601156 = newJObject()
  var body_601157 = newJObject()
  add(path_601156, "inputName", newJString(inputName))
  if body != nil:
    body_601157 = body
  result = call_601155.call(path_601156, nil, nil, nil, body_601157)

var updateInput* = Call_UpdateInput_601142(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_UpdateInput_601143,
                                        base: "/", url: url_UpdateInput_601144,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_601128 = ref object of OpenApiRestCall_600426
proc url_DescribeInput_601130(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeInput_601129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601131 = path.getOrDefault("inputName")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = nil)
  if valid_601131 != nil:
    section.add "inputName", valid_601131
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
  var valid_601132 = header.getOrDefault("X-Amz-Date")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Date", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Security-Token")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Security-Token", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Content-Sha256", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Algorithm")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Algorithm", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Signature")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Signature", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-SignedHeaders", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Credential")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Credential", valid_601138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DescribeInput_601128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an input.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DescribeInput_601128; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
  ##            : The name of the input.
  var path_601141 = newJObject()
  add(path_601141, "inputName", newJString(inputName))
  result = call_601140.call(path_601141, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_601128(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_601129,
    base: "/", url: url_DescribeInput_601130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_601158 = ref object of OpenApiRestCall_600426
proc url_DeleteInput_601160(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
               (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteInput_601159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601161 = path.getOrDefault("inputName")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "inputName", valid_601161
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
  var valid_601162 = header.getOrDefault("X-Amz-Date")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Date", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Security-Token")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Security-Token", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Content-Sha256", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Algorithm")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Algorithm", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Signature")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Signature", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-SignedHeaders", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Credential")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Credential", valid_601168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeleteInput_601158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an input.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeleteInput_601158; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
  ##            : The name of the input to delete.
  var path_601171 = newJObject()
  add(path_601171, "inputName", newJString(inputName))
  result = call_601170.call(path_601171, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_601158(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "iotevents.amazonaws.com",
                                        route: "/inputs/{inputName}",
                                        validator: validate_DeleteInput_601159,
                                        base: "/", url: url_DeleteInput_601160,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_601184 = ref object of OpenApiRestCall_600426
proc url_PutLoggingOptions_601186(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutLoggingOptions_601185(path: JsonNode; query: JsonNode;
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
  var valid_601187 = header.getOrDefault("X-Amz-Date")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Date", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Security-Token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Security-Token", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601195: Call_PutLoggingOptions_601184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ## 
  let valid = call_601195.validator(path, query, header, formData, body)
  let scheme = call_601195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601195.url(scheme.get, call_601195.host, call_601195.base,
                         call_601195.route, valid.getOrDefault("path"))
  result = hook(call_601195, url, valid)

proc call*(call_601196: Call_PutLoggingOptions_601184; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>"loggingOptions"</code> field, it takes up to one minute for the change to take effect. Also, if you change the policy attached to the role you specified in the <code>"roleArn"</code> field (for example, to correct an invalid policy) it takes up to five minutes for that change to take effect.</p>
  ##   body: JObject (required)
  var body_601197 = newJObject()
  if body != nil:
    body_601197 = body
  result = call_601196.call(nil, nil, nil, nil, body_601197)

var putLoggingOptions* = Call_PutLoggingOptions_601184(name: "putLoggingOptions",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_601185, base: "/",
    url: url_PutLoggingOptions_601186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_601172 = ref object of OpenApiRestCall_600426
proc url_DescribeLoggingOptions_601174(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLoggingOptions_601173(path: JsonNode; query: JsonNode;
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
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Content-Sha256", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Algorithm")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Algorithm", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Signature")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Signature", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-SignedHeaders", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Credential")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Credential", valid_601181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601182: Call_DescribeLoggingOptions_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
  ## 
  let valid = call_601182.validator(path, query, header, formData, body)
  let scheme = call_601182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601182.url(scheme.get, call_601182.host, call_601182.base,
                         call_601182.route, valid.getOrDefault("path"))
  result = hook(call_601182, url, valid)

proc call*(call_601183: Call_DescribeLoggingOptions_601172): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_601183.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_601172(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_601173, base: "/",
    url: url_DescribeLoggingOptions_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_601198 = ref object of OpenApiRestCall_600426
proc url_ListDetectorModelVersions_601200(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDetectorModelVersions_601199(path: JsonNode; query: JsonNode;
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
  var valid_601201 = path.getOrDefault("detectorModelName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "detectorModelName", valid_601201
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return at one time.
  ##   nextToken: JString
  ##            : The token for the next set of results.
  section = newJObject()
  var valid_601202 = query.getOrDefault("maxResults")
  valid_601202 = validateParameter(valid_601202, JInt, required = false, default = nil)
  if valid_601202 != nil:
    section.add "maxResults", valid_601202
  var valid_601203 = query.getOrDefault("nextToken")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "nextToken", valid_601203
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
  var valid_601204 = header.getOrDefault("X-Amz-Date")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Date", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Security-Token")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Security-Token", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Content-Sha256", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Algorithm")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Algorithm", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Signature")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Signature", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-SignedHeaders", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Credential")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Credential", valid_601210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601211: Call_ListDetectorModelVersions_601198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ## 
  let valid = call_601211.validator(path, query, header, formData, body)
  let scheme = call_601211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601211.url(scheme.get, call_601211.host, call_601211.base,
                         call_601211.route, valid.getOrDefault("path"))
  result = hook(call_601211, url, valid)

proc call*(call_601212: Call_ListDetectorModelVersions_601198;
          detectorModelName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   maxResults: int
  ##             : The maximum number of results to return at one time.
  ##   nextToken: string
  ##            : The token for the next set of results.
  ##   detectorModelName: string (required)
  ##                    : The name of the detector model whose versions are returned.
  var path_601213 = newJObject()
  var query_601214 = newJObject()
  add(query_601214, "maxResults", newJInt(maxResults))
  add(query_601214, "nextToken", newJString(nextToken))
  add(path_601213, "detectorModelName", newJString(detectorModelName))
  result = call_601212.call(path_601213, query_601214, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_601198(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_601199, base: "/",
    url: url_ListDetectorModelVersions_601200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601229 = ref object of OpenApiRestCall_600426
proc url_TagResource_601231(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601230(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601232 = query.getOrDefault("resourceArn")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "resourceArn", valid_601232
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
  var valid_601233 = header.getOrDefault("X-Amz-Date")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Date", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Security-Token")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Security-Token", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Content-Sha256", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Algorithm")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Algorithm", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Signature")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Signature", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-SignedHeaders", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Credential")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Credential", valid_601239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_TagResource_601229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_TagResource_601229; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var query_601243 = newJObject()
  var body_601244 = newJObject()
  add(query_601243, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_601244 = body
  result = call_601242.call(nil, query_601243, nil, nil, body_601244)

var tagResource* = Call_TagResource_601229(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotevents.amazonaws.com",
                                        route: "/tags#resourceArn",
                                        validator: validate_TagResource_601230,
                                        base: "/", url: url_TagResource_601231,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601215 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601217(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601216(path: JsonNode; query: JsonNode;
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
  var valid_601218 = query.getOrDefault("resourceArn")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "resourceArn", valid_601218
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
  var valid_601219 = header.getOrDefault("X-Amz-Date")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Date", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Security-Token")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Security-Token", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Content-Sha256", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Algorithm")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Algorithm", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Signature")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Signature", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-SignedHeaders", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Credential")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Credential", valid_601225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_ListTagsForResource_601215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
  ## 
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"))
  result = hook(call_601226, url, valid)

proc call*(call_601227: Call_ListTagsForResource_601215; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var query_601228 = newJObject()
  add(query_601228, "resourceArn", newJString(resourceArn))
  result = call_601227.call(nil, query_601228, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601215(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_601216, base: "/",
    url: url_ListTagsForResource_601217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601245 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601247(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601246(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601248 = query.getOrDefault("resourceArn")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = nil)
  if valid_601248 != nil:
    section.add "resourceArn", valid_601248
  var valid_601249 = query.getOrDefault("tagKeys")
  valid_601249 = validateParameter(valid_601249, JArray, required = true, default = nil)
  if valid_601249 != nil:
    section.add "tagKeys", valid_601249
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
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Content-Sha256", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Algorithm")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Algorithm", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Signature")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Signature", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-SignedHeaders", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Credential")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Credential", valid_601256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601257: Call_UntagResource_601245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the given tags (metadata) from the resource.
  ## 
  let valid = call_601257.validator(path, query, header, formData, body)
  let scheme = call_601257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601257.url(scheme.get, call_601257.host, call_601257.base,
                         call_601257.route, valid.getOrDefault("path"))
  result = hook(call_601257, url, valid)

proc call*(call_601258: Call_UntagResource_601245; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   tagKeys: JArray (required)
  ##          : A list of the keys of the tags to be removed from the resource.
  var query_601259 = newJObject()
  add(query_601259, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_601259.add "tagKeys", tagKeys
  result = call_601258.call(nil, query_601259, nil, nil, nil)

var untagResource* = Call_UntagResource_601245(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_601246,
    base: "/", url: url_UntagResource_601247, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
