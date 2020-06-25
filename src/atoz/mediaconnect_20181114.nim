
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS MediaConnect
## version: 2018-11-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## API for AWS Elemental MediaConnect
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediaconnect/
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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mediaconnect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediaconnect.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mediaconnect.us-west-2.amazonaws.com",
                           "eu-west-2": "mediaconnect.eu-west-2.amazonaws.com", "ap-northeast-3": "mediaconnect.ap-northeast-3.amazonaws.com", "eu-central-1": "mediaconnect.eu-central-1.amazonaws.com",
                           "us-east-2": "mediaconnect.us-east-2.amazonaws.com",
                           "us-east-1": "mediaconnect.us-east-1.amazonaws.com", "cn-northwest-1": "mediaconnect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediaconnect.ap-south-1.amazonaws.com", "eu-north-1": "mediaconnect.eu-north-1.amazonaws.com", "ap-northeast-2": "mediaconnect.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mediaconnect.us-west-1.amazonaws.com", "us-gov-east-1": "mediaconnect.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mediaconnect.eu-west-3.amazonaws.com", "cn-north-1": "mediaconnect.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mediaconnect.sa-east-1.amazonaws.com",
                           "eu-west-1": "mediaconnect.eu-west-1.amazonaws.com", "us-gov-west-1": "mediaconnect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediaconnect.ap-southeast-2.amazonaws.com", "ca-central-1": "mediaconnect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mediaconnect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediaconnect.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediaconnect.us-west-2.amazonaws.com",
      "eu-west-2": "mediaconnect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediaconnect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediaconnect.eu-central-1.amazonaws.com",
      "us-east-2": "mediaconnect.us-east-2.amazonaws.com",
      "us-east-1": "mediaconnect.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediaconnect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediaconnect.ap-south-1.amazonaws.com",
      "eu-north-1": "mediaconnect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediaconnect.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediaconnect.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediaconnect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediaconnect.eu-west-3.amazonaws.com",
      "cn-north-1": "mediaconnect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediaconnect.sa-east-1.amazonaws.com",
      "eu-west-1": "mediaconnect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediaconnect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediaconnect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediaconnect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediaconnect"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddFlowOutputs_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddFlowOutputs_21625781(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/outputs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddFlowOutputs_21625780(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to add outputs to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21625895 = path.getOrDefault("flowArn")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "flowArn", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
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

proc call*(call_21625928: Call_AddFlowOutputs_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_21625928.validator(path, query, header, formData, body, _)
  let scheme = call_21625928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625928.makeUrl(scheme.get, call_21625928.host, call_21625928.base,
                               call_21625928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625928, uri, valid, _)

proc call*(call_21625991: Call_AddFlowOutputs_21625779; flowArn: string;
          body: JsonNode): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  ##   body: JObject (required)
  var path_21625993 = newJObject()
  var body_21625995 = newJObject()
  add(path_21625993, "flowArn", newJString(flowArn))
  if body != nil:
    body_21625995 = body
  result = call_21625991.call(path_21625993, nil, nil, nil, body_21625995)

var addFlowOutputs* = Call_AddFlowOutputs_21625779(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_21625780,
    base: "/", makeUrl: url_AddFlowOutputs_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_21626050 = ref object of OpenApiRestCall_21625435
proc url_CreateFlow_21626052(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlow_21626051(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
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
  var valid_21626053 = header.getOrDefault("X-Amz-Date")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Date", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Security-Token", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Algorithm", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Signature")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Signature", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Credential")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Credential", valid_21626059
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

proc call*(call_21626061: Call_CreateFlow_21626050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_CreateFlow_21626050; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_21626063 = newJObject()
  if body != nil:
    body_21626063 = body
  result = call_21626062.call(nil, nil, nil, nil, body_21626063)

var createFlow* = Call_CreateFlow_21626050(name: "createFlow",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/v1/flows",
                                        validator: validate_CreateFlow_21626051,
                                        base: "/", makeUrl: url_CreateFlow_21626052,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_21626032 = ref object of OpenApiRestCall_21625435
proc url_ListFlows_21626034(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlows_21626033(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  ##   nextToken: JString
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626035 = query.getOrDefault("NextToken")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "NextToken", valid_21626035
  var valid_21626036 = query.getOrDefault("maxResults")
  valid_21626036 = validateParameter(valid_21626036, JInt, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "maxResults", valid_21626036
  var valid_21626037 = query.getOrDefault("nextToken")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "nextToken", valid_21626037
  var valid_21626038 = query.getOrDefault("MaxResults")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "MaxResults", valid_21626038
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
  var valid_21626039 = header.getOrDefault("X-Amz-Date")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Date", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Security-Token", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626046: Call_ListFlows_21626032; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_21626046.validator(path, query, header, formData, body, _)
  let scheme = call_21626046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626046.makeUrl(scheme.get, call_21626046.host, call_21626046.base,
                               call_21626046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626046, uri, valid, _)

proc call*(call_21626047: Call_ListFlows_21626032; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFlows
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  ##   nextToken: string
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626048 = newJObject()
  add(query_21626048, "NextToken", newJString(NextToken))
  add(query_21626048, "maxResults", newJInt(maxResults))
  add(query_21626048, "nextToken", newJString(nextToken))
  add(query_21626048, "MaxResults", newJString(MaxResults))
  result = call_21626047.call(nil, query_21626048, nil, nil, nil)

var listFlows* = Call_ListFlows_21626032(name: "listFlows", meth: HttpMethod.HttpGet,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_ListFlows_21626033,
                                      base: "/", makeUrl: url_ListFlows_21626034,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_21626064 = ref object of OpenApiRestCall_21625435
proc url_DescribeFlow_21626066(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFlow_21626065(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626067 = path.getOrDefault("flowArn")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "flowArn", valid_21626067
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
  var valid_21626068 = header.getOrDefault("X-Amz-Date")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Date", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Security-Token", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Algorithm", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Signature")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Signature", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Credential")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Credential", valid_21626074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626075: Call_DescribeFlow_21626064; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_21626075.validator(path, query, header, formData, body, _)
  let scheme = call_21626075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626075.makeUrl(scheme.get, call_21626075.host, call_21626075.base,
                               call_21626075.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626075, uri, valid, _)

proc call*(call_21626076: Call_DescribeFlow_21626064; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_21626077 = newJObject()
  add(path_21626077, "flowArn", newJString(flowArn))
  result = call_21626076.call(path_21626077, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_21626064(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_21626065,
    base: "/", makeUrl: url_DescribeFlow_21626066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_21626078 = ref object of OpenApiRestCall_21625435
proc url_DeleteFlow_21626080(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFlow_21626079(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626081 = path.getOrDefault("flowArn")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "flowArn", valid_21626081
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
  var valid_21626082 = header.getOrDefault("X-Amz-Date")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Date", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Security-Token", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Algorithm", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Signature")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Signature", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Credential")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Credential", valid_21626088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626089: Call_DeleteFlow_21626078; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_21626089.validator(path, query, header, formData, body, _)
  let scheme = call_21626089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626089.makeUrl(scheme.get, call_21626089.host, call_21626089.base,
                               call_21626089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626089, uri, valid, _)

proc call*(call_21626090: Call_DeleteFlow_21626078; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_21626091 = newJObject()
  add(path_21626091, "flowArn", newJString(flowArn))
  result = call_21626090.call(path_21626091, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_21626078(name: "deleteFlow",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/v1/flows/{flowArn}",
                                        validator: validate_DeleteFlow_21626079,
                                        base: "/", makeUrl: url_DeleteFlow_21626080,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_21626092 = ref object of OpenApiRestCall_21625435
proc url_GrantFlowEntitlements_21626094(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/entitlements")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GrantFlowEntitlements_21626093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Grants entitlements to an existing flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to grant entitlements on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626095 = path.getOrDefault("flowArn")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "flowArn", valid_21626095
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
  var valid_21626096 = header.getOrDefault("X-Amz-Date")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Date", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Security-Token", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Algorithm", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Signature")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Signature", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Credential")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Credential", valid_21626102
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

proc call*(call_21626104: Call_GrantFlowEntitlements_21626092;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_21626104.validator(path, query, header, formData, body, _)
  let scheme = call_21626104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626104.makeUrl(scheme.get, call_21626104.host, call_21626104.base,
                               call_21626104.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626104, uri, valid, _)

proc call*(call_21626105: Call_GrantFlowEntitlements_21626092; flowArn: string;
          body: JsonNode): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  ##   body: JObject (required)
  var path_21626106 = newJObject()
  var body_21626107 = newJObject()
  add(path_21626106, "flowArn", newJString(flowArn))
  if body != nil:
    body_21626107 = body
  result = call_21626105.call(path_21626106, nil, nil, nil, body_21626107)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_21626092(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_21626093, base: "/",
    makeUrl: url_GrantFlowEntitlements_21626094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_21626108 = ref object of OpenApiRestCall_21625435
proc url_ListEntitlements_21626110(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntitlements_21626109(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  ##   nextToken: JString
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626111 = query.getOrDefault("NextToken")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "NextToken", valid_21626111
  var valid_21626112 = query.getOrDefault("maxResults")
  valid_21626112 = validateParameter(valid_21626112, JInt, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "maxResults", valid_21626112
  var valid_21626113 = query.getOrDefault("nextToken")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "nextToken", valid_21626113
  var valid_21626114 = query.getOrDefault("MaxResults")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "MaxResults", valid_21626114
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
  var valid_21626115 = header.getOrDefault("X-Amz-Date")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Date", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Security-Token", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Algorithm", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Signature")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Signature", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Credential")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Credential", valid_21626121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626122: Call_ListEntitlements_21626108; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_21626122.validator(path, query, header, formData, body, _)
  let scheme = call_21626122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626122.makeUrl(scheme.get, call_21626122.host, call_21626122.base,
                               call_21626122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626122, uri, valid, _)

proc call*(call_21626123: Call_ListEntitlements_21626108; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntitlements
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  ##   nextToken: string
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626124 = newJObject()
  add(query_21626124, "NextToken", newJString(NextToken))
  add(query_21626124, "maxResults", newJInt(maxResults))
  add(query_21626124, "nextToken", newJString(nextToken))
  add(query_21626124, "MaxResults", newJString(MaxResults))
  result = call_21626123.call(nil, query_21626124, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_21626108(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_21626109,
    base: "/", makeUrl: url_ListEntitlements_21626110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626139 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626141(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626140(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626142 = path.getOrDefault("resourceArn")
  valid_21626142 = validateParameter(valid_21626142, JString, required = true,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "resourceArn", valid_21626142
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
  var valid_21626143 = header.getOrDefault("X-Amz-Date")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Date", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Security-Token", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Algorithm", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Signature")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Signature", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Credential")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Credential", valid_21626149
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

proc call*(call_21626151: Call_TagResource_21626139; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_21626151.validator(path, query, header, formData, body, _)
  let scheme = call_21626151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626151.makeUrl(scheme.get, call_21626151.host, call_21626151.base,
                               call_21626151.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626151, uri, valid, _)

proc call*(call_21626152: Call_TagResource_21626139; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  var path_21626153 = newJObject()
  var body_21626154 = newJObject()
  if body != nil:
    body_21626154 = body
  add(path_21626153, "resourceArn", newJString(resourceArn))
  result = call_21626152.call(path_21626153, nil, nil, nil, body_21626154)

var tagResource* = Call_TagResource_21626139(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626140,
    base: "/", makeUrl: url_TagResource_21626141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626125 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626127(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626128 = path.getOrDefault("resourceArn")
  valid_21626128 = validateParameter(valid_21626128, JString, required = true,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "resourceArn", valid_21626128
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
  var valid_21626129 = header.getOrDefault("X-Amz-Date")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Date", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Security-Token", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Algorithm", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Signature")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Signature", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Credential")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Credential", valid_21626135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626136: Call_ListTagsForResource_21626125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_21626136.validator(path, query, header, formData, body, _)
  let scheme = call_21626136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626136.makeUrl(scheme.get, call_21626136.host, call_21626136.base,
                               call_21626136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626136, uri, valid, _)

proc call*(call_21626137: Call_ListTagsForResource_21626125; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_21626138 = newJObject()
  add(path_21626138, "resourceArn", newJString(resourceArn))
  result = call_21626137.call(path_21626138, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626125(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626126, base: "/",
    makeUrl: url_ListTagsForResource_21626127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_21626155 = ref object of OpenApiRestCall_21625435
proc url_UpdateFlowOutput_21626157(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "outputArn" in path, "`outputArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/outputs/"),
               (kind: VariableSegment, value: "outputArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowOutput_21626156(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing flow output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the output that you want to update.
  ##   outputArn: JString (required)
  ##            : The ARN of the output that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626158 = path.getOrDefault("flowArn")
  valid_21626158 = validateParameter(valid_21626158, JString, required = true,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "flowArn", valid_21626158
  var valid_21626159 = path.getOrDefault("outputArn")
  valid_21626159 = validateParameter(valid_21626159, JString, required = true,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "outputArn", valid_21626159
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
  var valid_21626160 = header.getOrDefault("X-Amz-Date")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Date", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Security-Token", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Algorithm", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Signature")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Signature", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Credential")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Credential", valid_21626166
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

proc call*(call_21626168: Call_UpdateFlowOutput_21626155; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_21626168.validator(path, query, header, formData, body, _)
  let scheme = call_21626168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626168.makeUrl(scheme.get, call_21626168.host, call_21626168.base,
                               call_21626168.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626168, uri, valid, _)

proc call*(call_21626169: Call_UpdateFlowOutput_21626155; flowArn: string;
          outputArn: string; body: JsonNode): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  var path_21626170 = newJObject()
  var body_21626171 = newJObject()
  add(path_21626170, "flowArn", newJString(flowArn))
  add(path_21626170, "outputArn", newJString(outputArn))
  if body != nil:
    body_21626171 = body
  result = call_21626169.call(path_21626170, nil, nil, nil, body_21626171)

var updateFlowOutput* = Call_UpdateFlowOutput_21626155(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_21626156, base: "/",
    makeUrl: url_UpdateFlowOutput_21626157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_21626172 = ref object of OpenApiRestCall_21625435
proc url_RemoveFlowOutput_21626174(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "outputArn" in path, "`outputArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/outputs/"),
               (kind: VariableSegment, value: "outputArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveFlowOutput_21626173(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to remove an output from.
  ##   outputArn: JString (required)
  ##            : The ARN of the output that you want to remove.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626175 = path.getOrDefault("flowArn")
  valid_21626175 = validateParameter(valid_21626175, JString, required = true,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "flowArn", valid_21626175
  var valid_21626176 = path.getOrDefault("outputArn")
  valid_21626176 = validateParameter(valid_21626176, JString, required = true,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "outputArn", valid_21626176
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
  var valid_21626177 = header.getOrDefault("X-Amz-Date")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Date", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Security-Token", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Algorithm", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Signature")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Signature", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Credential")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Credential", valid_21626183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626184: Call_RemoveFlowOutput_21626172; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_21626184.validator(path, query, header, formData, body, _)
  let scheme = call_21626184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626184.makeUrl(scheme.get, call_21626184.host, call_21626184.base,
                               call_21626184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626184, uri, valid, _)

proc call*(call_21626185: Call_RemoveFlowOutput_21626172; flowArn: string;
          outputArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  var path_21626186 = newJObject()
  add(path_21626186, "flowArn", newJString(flowArn))
  add(path_21626186, "outputArn", newJString(outputArn))
  result = call_21626185.call(path_21626186, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_21626172(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_21626173, base: "/",
    makeUrl: url_RemoveFlowOutput_21626174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_21626187 = ref object of OpenApiRestCall_21625435
proc url_UpdateFlowEntitlement_21626189(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "entitlementArn" in path, "`entitlementArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/entitlements/"),
               (kind: VariableSegment, value: "entitlementArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowEntitlement_21626188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  ##   entitlementArn: JString (required)
  ##                 : The ARN of the entitlement that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626190 = path.getOrDefault("flowArn")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "flowArn", valid_21626190
  var valid_21626191 = path.getOrDefault("entitlementArn")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "entitlementArn", valid_21626191
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
  var valid_21626192 = header.getOrDefault("X-Amz-Date")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Date", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Security-Token", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Algorithm", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Signature")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Signature", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Credential")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Credential", valid_21626198
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

proc call*(call_21626200: Call_UpdateFlowEntitlement_21626187;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_UpdateFlowEntitlement_21626187; flowArn: string;
          body: JsonNode; entitlementArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  ##   body: JObject (required)
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  var path_21626202 = newJObject()
  var body_21626203 = newJObject()
  add(path_21626202, "flowArn", newJString(flowArn))
  if body != nil:
    body_21626203 = body
  add(path_21626202, "entitlementArn", newJString(entitlementArn))
  result = call_21626201.call(path_21626202, nil, nil, nil, body_21626203)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_21626187(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_21626188, base: "/",
    makeUrl: url_UpdateFlowEntitlement_21626189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_21626204 = ref object of OpenApiRestCall_21625435
proc url_RevokeFlowEntitlement_21626206(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "entitlementArn" in path, "`entitlementArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/entitlements/"),
               (kind: VariableSegment, value: "entitlementArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RevokeFlowEntitlement_21626205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to revoke an entitlement from.
  ##   entitlementArn: JString (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626207 = path.getOrDefault("flowArn")
  valid_21626207 = validateParameter(valid_21626207, JString, required = true,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "flowArn", valid_21626207
  var valid_21626208 = path.getOrDefault("entitlementArn")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "entitlementArn", valid_21626208
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
  var valid_21626209 = header.getOrDefault("X-Amz-Date")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Date", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Security-Token", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Algorithm", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Signature")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Signature", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Credential")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Credential", valid_21626215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626216: Call_RevokeFlowEntitlement_21626204;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_21626216.validator(path, query, header, formData, body, _)
  let scheme = call_21626216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626216.makeUrl(scheme.get, call_21626216.host, call_21626216.base,
                               call_21626216.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626216, uri, valid, _)

proc call*(call_21626217: Call_RevokeFlowEntitlement_21626204; flowArn: string;
          entitlementArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  var path_21626218 = newJObject()
  add(path_21626218, "flowArn", newJString(flowArn))
  add(path_21626218, "entitlementArn", newJString(entitlementArn))
  result = call_21626217.call(path_21626218, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_21626204(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_21626205, base: "/",
    makeUrl: url_RevokeFlowEntitlement_21626206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_21626219 = ref object of OpenApiRestCall_21625435
proc url_StartFlow_21626221(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/start/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartFlow_21626220(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to start.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626222 = path.getOrDefault("flowArn")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "flowArn", valid_21626222
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
  var valid_21626223 = header.getOrDefault("X-Amz-Date")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Date", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Security-Token", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Algorithm", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Signature")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Signature", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Credential")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Credential", valid_21626229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626230: Call_StartFlow_21626219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_21626230.validator(path, query, header, formData, body, _)
  let scheme = call_21626230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626230.makeUrl(scheme.get, call_21626230.host, call_21626230.base,
                               call_21626230.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626230, uri, valid, _)

proc call*(call_21626231: Call_StartFlow_21626219; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_21626232 = newJObject()
  add(path_21626232, "flowArn", newJString(flowArn))
  result = call_21626231.call(path_21626232, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_21626219(name: "startFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/start/{flowArn}",
                                      validator: validate_StartFlow_21626220,
                                      base: "/", makeUrl: url_StartFlow_21626221,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_21626233 = ref object of OpenApiRestCall_21625435
proc url_StopFlow_21626235(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/stop/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopFlow_21626234(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to stop.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626236 = path.getOrDefault("flowArn")
  valid_21626236 = validateParameter(valid_21626236, JString, required = true,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "flowArn", valid_21626236
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
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Algorithm", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Signature")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Signature", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Credential")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Credential", valid_21626243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626244: Call_StopFlow_21626233; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_21626244.validator(path, query, header, formData, body, _)
  let scheme = call_21626244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626244.makeUrl(scheme.get, call_21626244.host, call_21626244.base,
                               call_21626244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626244, uri, valid, _)

proc call*(call_21626245: Call_StopFlow_21626233; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_21626246 = newJObject()
  add(path_21626246, "flowArn", newJString(flowArn))
  result = call_21626245.call(path_21626246, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_21626233(name: "stopFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/stop/{flowArn}",
                                    validator: validate_StopFlow_21626234,
                                    base: "/", makeUrl: url_StopFlow_21626235,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626247 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626249(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21626248(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626250 = path.getOrDefault("resourceArn")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "resourceArn", valid_21626250
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626251 = query.getOrDefault("tagKeys")
  valid_21626251 = validateParameter(valid_21626251, JArray, required = true,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "tagKeys", valid_21626251
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
  var valid_21626252 = header.getOrDefault("X-Amz-Date")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Date", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Security-Token", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Algorithm", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Signature")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Signature", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Credential")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Credential", valid_21626258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626259: Call_UntagResource_21626247; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_21626259.validator(path, query, header, formData, body, _)
  let scheme = call_21626259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626259.makeUrl(scheme.get, call_21626259.host, call_21626259.base,
                               call_21626259.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626259, uri, valid, _)

proc call*(call_21626260: Call_UntagResource_21626247; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  var path_21626261 = newJObject()
  var query_21626262 = newJObject()
  if tagKeys != nil:
    query_21626262.add "tagKeys", tagKeys
  add(path_21626261, "resourceArn", newJString(resourceArn))
  result = call_21626260.call(path_21626261, query_21626262, nil, nil, nil)

var untagResource* = Call_UntagResource_21626247(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626248,
    base: "/", makeUrl: url_UntagResource_21626249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_21626263 = ref object of OpenApiRestCall_21625435
proc url_UpdateFlowSource_21626265(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "sourceArn" in path, "`sourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/source/"),
               (kind: VariableSegment, value: "sourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowSource_21626264(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the source of a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the source that you want to update.
  ##   sourceArn: JString (required)
  ##            : The ARN of the source that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_21626266 = path.getOrDefault("flowArn")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "flowArn", valid_21626266
  var valid_21626267 = path.getOrDefault("sourceArn")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "sourceArn", valid_21626267
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
  var valid_21626268 = header.getOrDefault("X-Amz-Date")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Date", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Security-Token", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Algorithm", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Signature")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Signature", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Credential")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Credential", valid_21626274
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

proc call*(call_21626276: Call_UpdateFlowSource_21626263; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_21626276.validator(path, query, header, formData, body, _)
  let scheme = call_21626276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626276.makeUrl(scheme.get, call_21626276.host, call_21626276.base,
                               call_21626276.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626276, uri, valid, _)

proc call*(call_21626277: Call_UpdateFlowSource_21626263; flowArn: string;
          body: JsonNode; sourceArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  ##   body: JObject (required)
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  var path_21626278 = newJObject()
  var body_21626279 = newJObject()
  add(path_21626278, "flowArn", newJString(flowArn))
  if body != nil:
    body_21626279 = body
  add(path_21626278, "sourceArn", newJString(sourceArn))
  result = call_21626277.call(path_21626278, nil, nil, nil, body_21626279)

var updateFlowSource* = Call_UpdateFlowSource_21626263(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_21626264, base: "/",
    makeUrl: url_UpdateFlowSource_21626265, schemes: {Scheme.Https, Scheme.Http})
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