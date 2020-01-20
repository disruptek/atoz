
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFlowOutputs_605927 = ref object of OpenApiRestCall_605589
proc url_AddFlowOutputs_605929(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddFlowOutputs_605928(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to add outputs to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606055 = path.getOrDefault("flowArn")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "flowArn", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_AddFlowOutputs_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_AddFlowOutputs_605927; body: JsonNode; flowArn: string): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  var path_606158 = newJObject()
  var body_606160 = newJObject()
  if body != nil:
    body_606160 = body
  add(path_606158, "flowArn", newJString(flowArn))
  result = call_606157.call(path_606158, nil, nil, nil, body_606160)

var addFlowOutputs* = Call_AddFlowOutputs_605927(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_605928,
    base: "/", url: url_AddFlowOutputs_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_606216 = ref object of OpenApiRestCall_605589
proc url_CreateFlow_606218(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateFlow_606217(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606227: Call_CreateFlow_606216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_606227.validator(path, query, header, formData, body)
  let scheme = call_606227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606227.url(scheme.get, call_606227.host, call_606227.base,
                         call_606227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606227, url, valid)

proc call*(call_606228: Call_CreateFlow_606216; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_606229 = newJObject()
  if body != nil:
    body_606229 = body
  result = call_606228.call(nil, nil, nil, nil, body_606229)

var createFlow* = Call_CreateFlow_606216(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_606217,
                                      base: "/", url: url_CreateFlow_606218,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_606199 = ref object of OpenApiRestCall_605589
proc url_ListFlows_606201(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListFlows_606200(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  section = newJObject()
  var valid_606202 = query.getOrDefault("nextToken")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "nextToken", valid_606202
  var valid_606203 = query.getOrDefault("MaxResults")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "MaxResults", valid_606203
  var valid_606204 = query.getOrDefault("NextToken")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "NextToken", valid_606204
  var valid_606205 = query.getOrDefault("maxResults")
  valid_606205 = validateParameter(valid_606205, JInt, required = false, default = nil)
  if valid_606205 != nil:
    section.add "maxResults", valid_606205
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
  var valid_606206 = header.getOrDefault("X-Amz-Signature")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Signature", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Content-Sha256", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Date")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Date", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Credential")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Credential", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Security-Token")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Security-Token", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Algorithm")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Algorithm", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-SignedHeaders", valid_606212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606213: Call_ListFlows_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_606213.validator(path, query, header, formData, body)
  let scheme = call_606213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606213.url(scheme.get, call_606213.host, call_606213.base,
                         call_606213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606213, url, valid)

proc call*(call_606214: Call_ListFlows_606199; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFlows
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ##   nextToken: string
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  var query_606215 = newJObject()
  add(query_606215, "nextToken", newJString(nextToken))
  add(query_606215, "MaxResults", newJString(MaxResults))
  add(query_606215, "NextToken", newJString(NextToken))
  add(query_606215, "maxResults", newJInt(maxResults))
  result = call_606214.call(nil, query_606215, nil, nil, nil)

var listFlows* = Call_ListFlows_606199(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_606200,
                                    base: "/", url: url_ListFlows_606201,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_606230 = ref object of OpenApiRestCall_605589
proc url_DescribeFlow_606232(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFlow_606231(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606233 = path.getOrDefault("flowArn")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "flowArn", valid_606233
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
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_DescribeFlow_606230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_DescribeFlow_606230; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_606243 = newJObject()
  add(path_606243, "flowArn", newJString(flowArn))
  result = call_606242.call(path_606243, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_606230(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_606231,
    base: "/", url: url_DescribeFlow_606232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_606244 = ref object of OpenApiRestCall_605589
proc url_DeleteFlow_606246(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFlow_606245(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606247 = path.getOrDefault("flowArn")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "flowArn", valid_606247
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
  var valid_606248 = header.getOrDefault("X-Amz-Signature")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Signature", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Content-Sha256", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Date")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Date", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Credential")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Credential", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Security-Token")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Security-Token", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Algorithm")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Algorithm", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-SignedHeaders", valid_606254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_DeleteFlow_606244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_DeleteFlow_606244; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_606257 = newJObject()
  add(path_606257, "flowArn", newJString(flowArn))
  result = call_606256.call(path_606257, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_606244(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_606245,
                                      base: "/", url: url_DeleteFlow_606246,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_606258 = ref object of OpenApiRestCall_605589
proc url_GrantFlowEntitlements_606260(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GrantFlowEntitlements_606259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Grants entitlements to an existing flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The flow that you want to grant entitlements on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606261 = path.getOrDefault("flowArn")
  valid_606261 = validateParameter(valid_606261, JString, required = true,
                                 default = nil)
  if valid_606261 != nil:
    section.add "flowArn", valid_606261
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
  var valid_606262 = header.getOrDefault("X-Amz-Signature")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Signature", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Content-Sha256", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Date")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Date", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Credential")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Credential", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Security-Token")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Security-Token", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Algorithm")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Algorithm", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-SignedHeaders", valid_606268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606270: Call_GrantFlowEntitlements_606258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_606270.validator(path, query, header, formData, body)
  let scheme = call_606270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606270.url(scheme.get, call_606270.host, call_606270.base,
                         call_606270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606270, url, valid)

proc call*(call_606271: Call_GrantFlowEntitlements_606258; body: JsonNode;
          flowArn: string): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  var path_606272 = newJObject()
  var body_606273 = newJObject()
  if body != nil:
    body_606273 = body
  add(path_606272, "flowArn", newJString(flowArn))
  result = call_606271.call(path_606272, nil, nil, nil, body_606273)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_606258(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_606259, base: "/",
    url: url_GrantFlowEntitlements_606260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_606274 = ref object of OpenApiRestCall_605589
proc url_ListEntitlements_606276(protocol: Scheme; host: string; base: string;
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

proc validate_ListEntitlements_606275(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  section = newJObject()
  var valid_606277 = query.getOrDefault("nextToken")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "nextToken", valid_606277
  var valid_606278 = query.getOrDefault("MaxResults")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "MaxResults", valid_606278
  var valid_606279 = query.getOrDefault("NextToken")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "NextToken", valid_606279
  var valid_606280 = query.getOrDefault("maxResults")
  valid_606280 = validateParameter(valid_606280, JInt, required = false, default = nil)
  if valid_606280 != nil:
    section.add "maxResults", valid_606280
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
  var valid_606281 = header.getOrDefault("X-Amz-Signature")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Signature", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Content-Sha256", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Date")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Date", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Credential")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Credential", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Security-Token")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Security-Token", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Algorithm")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Algorithm", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-SignedHeaders", valid_606287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606288: Call_ListEntitlements_606274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_606288.validator(path, query, header, formData, body)
  let scheme = call_606288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606288.url(scheme.get, call_606288.host, call_606288.base,
                         call_606288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606288, url, valid)

proc call*(call_606289: Call_ListEntitlements_606274; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listEntitlements
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ##   nextToken: string
  ##            : The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  var query_606290 = newJObject()
  add(query_606290, "nextToken", newJString(nextToken))
  add(query_606290, "MaxResults", newJString(MaxResults))
  add(query_606290, "NextToken", newJString(NextToken))
  add(query_606290, "maxResults", newJInt(maxResults))
  result = call_606289.call(nil, query_606290, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_606274(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_606275,
    base: "/", url: url_ListEntitlements_606276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606305 = ref object of OpenApiRestCall_605589
proc url_TagResource_606307(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606306(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606308 = path.getOrDefault("resourceArn")
  valid_606308 = validateParameter(valid_606308, JString, required = true,
                                 default = nil)
  if valid_606308 != nil:
    section.add "resourceArn", valid_606308
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
  var valid_606309 = header.getOrDefault("X-Amz-Signature")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Signature", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Content-Sha256", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Date")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Date", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Credential")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Credential", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Security-Token")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Security-Token", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Algorithm")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Algorithm", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-SignedHeaders", valid_606315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606317: Call_TagResource_606305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_606317.validator(path, query, header, formData, body)
  let scheme = call_606317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606317.url(scheme.get, call_606317.host, call_606317.base,
                         call_606317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606317, url, valid)

proc call*(call_606318: Call_TagResource_606305; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  ##   body: JObject (required)
  var path_606319 = newJObject()
  var body_606320 = newJObject()
  add(path_606319, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606320 = body
  result = call_606318.call(path_606319, nil, nil, nil, body_606320)

var tagResource* = Call_TagResource_606305(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606306,
                                        base: "/", url: url_TagResource_606307,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606291 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606293(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606292(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606294 = path.getOrDefault("resourceArn")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = nil)
  if valid_606294 != nil:
    section.add "resourceArn", valid_606294
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
  var valid_606295 = header.getOrDefault("X-Amz-Signature")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Signature", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Content-Sha256", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Date")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Date", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Credential")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Credential", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Security-Token")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Security-Token", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Algorithm")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Algorithm", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-SignedHeaders", valid_606301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606302: Call_ListTagsForResource_606291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_606302.validator(path, query, header, formData, body)
  let scheme = call_606302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606302.url(scheme.get, call_606302.host, call_606302.base,
                         call_606302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606302, url, valid)

proc call*(call_606303: Call_ListTagsForResource_606291; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_606304 = newJObject()
  add(path_606304, "resourceArn", newJString(resourceArn))
  result = call_606303.call(path_606304, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606291(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606292, base: "/",
    url: url_ListTagsForResource_606293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_606321 = ref object of OpenApiRestCall_605589
proc url_UpdateFlowOutput_606323(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowOutput_606322(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates an existing flow output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   outputArn: JString (required)
  ##            : The ARN of the output that you want to update.
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the output that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `outputArn` field"
  var valid_606324 = path.getOrDefault("outputArn")
  valid_606324 = validateParameter(valid_606324, JString, required = true,
                                 default = nil)
  if valid_606324 != nil:
    section.add "outputArn", valid_606324
  var valid_606325 = path.getOrDefault("flowArn")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "flowArn", valid_606325
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
  var valid_606326 = header.getOrDefault("X-Amz-Signature")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Signature", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Content-Sha256", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Date")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Date", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Credential")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Credential", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Security-Token")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Security-Token", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Algorithm")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Algorithm", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-SignedHeaders", valid_606332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_UpdateFlowOutput_606321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_UpdateFlowOutput_606321; outputArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  var path_606336 = newJObject()
  var body_606337 = newJObject()
  add(path_606336, "outputArn", newJString(outputArn))
  if body != nil:
    body_606337 = body
  add(path_606336, "flowArn", newJString(flowArn))
  result = call_606335.call(path_606336, nil, nil, nil, body_606337)

var updateFlowOutput* = Call_UpdateFlowOutput_606321(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_606322, base: "/",
    url: url_UpdateFlowOutput_606323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_606338 = ref object of OpenApiRestCall_605589
proc url_RemoveFlowOutput_606340(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveFlowOutput_606339(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   outputArn: JString (required)
  ##            : The ARN of the output that you want to remove.
  ##   flowArn: JString (required)
  ##          : The flow that you want to remove an output from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `outputArn` field"
  var valid_606341 = path.getOrDefault("outputArn")
  valid_606341 = validateParameter(valid_606341, JString, required = true,
                                 default = nil)
  if valid_606341 != nil:
    section.add "outputArn", valid_606341
  var valid_606342 = path.getOrDefault("flowArn")
  valid_606342 = validateParameter(valid_606342, JString, required = true,
                                 default = nil)
  if valid_606342 != nil:
    section.add "flowArn", valid_606342
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
  var valid_606343 = header.getOrDefault("X-Amz-Signature")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Signature", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Content-Sha256", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Date")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Date", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Credential")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Credential", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Security-Token")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Security-Token", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Algorithm")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Algorithm", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-SignedHeaders", valid_606349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_RemoveFlowOutput_606338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_RemoveFlowOutput_606338; outputArn: string;
          flowArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  var path_606352 = newJObject()
  add(path_606352, "outputArn", newJString(outputArn))
  add(path_606352, "flowArn", newJString(flowArn))
  result = call_606351.call(path_606352, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_606338(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_606339, base: "/",
    url: url_RemoveFlowOutput_606340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_606353 = ref object of OpenApiRestCall_605589
proc url_UpdateFlowEntitlement_606355(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowEntitlement_606354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   entitlementArn: JString (required)
  ##                 : The ARN of the entitlement that you want to update.
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `entitlementArn` field"
  var valid_606356 = path.getOrDefault("entitlementArn")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = nil)
  if valid_606356 != nil:
    section.add "entitlementArn", valid_606356
  var valid_606357 = path.getOrDefault("flowArn")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "flowArn", valid_606357
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
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606366: Call_UpdateFlowEntitlement_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_606366.validator(path, query, header, formData, body)
  let scheme = call_606366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606366.url(scheme.get, call_606366.host, call_606366.base,
                         call_606366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606366, url, valid)

proc call*(call_606367: Call_UpdateFlowEntitlement_606353; entitlementArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  var path_606368 = newJObject()
  var body_606369 = newJObject()
  add(path_606368, "entitlementArn", newJString(entitlementArn))
  if body != nil:
    body_606369 = body
  add(path_606368, "flowArn", newJString(flowArn))
  result = call_606367.call(path_606368, nil, nil, nil, body_606369)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_606353(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_606354, base: "/",
    url: url_UpdateFlowEntitlement_606355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_606370 = ref object of OpenApiRestCall_605589
proc url_RevokeFlowEntitlement_606372(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RevokeFlowEntitlement_606371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   entitlementArn: JString (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  ##   flowArn: JString (required)
  ##          : The flow that you want to revoke an entitlement from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `entitlementArn` field"
  var valid_606373 = path.getOrDefault("entitlementArn")
  valid_606373 = validateParameter(valid_606373, JString, required = true,
                                 default = nil)
  if valid_606373 != nil:
    section.add "entitlementArn", valid_606373
  var valid_606374 = path.getOrDefault("flowArn")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "flowArn", valid_606374
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
  var valid_606375 = header.getOrDefault("X-Amz-Signature")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Signature", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Content-Sha256", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Date")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Date", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Credential")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Credential", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Security-Token")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Security-Token", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Algorithm")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Algorithm", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-SignedHeaders", valid_606381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606382: Call_RevokeFlowEntitlement_606370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_606382.validator(path, query, header, formData, body)
  let scheme = call_606382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606382.url(scheme.get, call_606382.host, call_606382.base,
                         call_606382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606382, url, valid)

proc call*(call_606383: Call_RevokeFlowEntitlement_606370; entitlementArn: string;
          flowArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  var path_606384 = newJObject()
  add(path_606384, "entitlementArn", newJString(entitlementArn))
  add(path_606384, "flowArn", newJString(flowArn))
  result = call_606383.call(path_606384, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_606370(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_606371, base: "/",
    url: url_RevokeFlowEntitlement_606372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_606385 = ref object of OpenApiRestCall_605589
proc url_StartFlow_606387(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartFlow_606386(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to start.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606388 = path.getOrDefault("flowArn")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "flowArn", valid_606388
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
  var valid_606389 = header.getOrDefault("X-Amz-Signature")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Signature", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Content-Sha256", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Date")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Date", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Credential")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Credential", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Security-Token")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Security-Token", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Algorithm")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Algorithm", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-SignedHeaders", valid_606395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_StartFlow_606385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_StartFlow_606385; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_606398 = newJObject()
  add(path_606398, "flowArn", newJString(flowArn))
  result = call_606397.call(path_606398, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_606385(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_606386,
                                    base: "/", url: url_StartFlow_606387,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_606399 = ref object of OpenApiRestCall_605589
proc url_StopFlow_606401(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopFlow_606400(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
  ##          : The ARN of the flow that you want to stop.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `flowArn` field"
  var valid_606402 = path.getOrDefault("flowArn")
  valid_606402 = validateParameter(valid_606402, JString, required = true,
                                 default = nil)
  if valid_606402 != nil:
    section.add "flowArn", valid_606402
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
  var valid_606403 = header.getOrDefault("X-Amz-Signature")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Signature", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Content-Sha256", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Date")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Date", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Credential")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Credential", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Security-Token")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Security-Token", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Algorithm")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Algorithm", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-SignedHeaders", valid_606409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606410: Call_StopFlow_606399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_606410.validator(path, query, header, formData, body)
  let scheme = call_606410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606410.url(scheme.get, call_606410.host, call_606410.base,
                         call_606410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606410, url, valid)

proc call*(call_606411: Call_StopFlow_606399; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_606412 = newJObject()
  add(path_606412, "flowArn", newJString(flowArn))
  result = call_606411.call(path_606412, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_606399(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_606400, base: "/",
                                  url: url_StopFlow_606401,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606413 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606415(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606414(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606416 = path.getOrDefault("resourceArn")
  valid_606416 = validateParameter(valid_606416, JString, required = true,
                                 default = nil)
  if valid_606416 != nil:
    section.add "resourceArn", valid_606416
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606417 = query.getOrDefault("tagKeys")
  valid_606417 = validateParameter(valid_606417, JArray, required = true, default = nil)
  if valid_606417 != nil:
    section.add "tagKeys", valid_606417
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
  var valid_606418 = header.getOrDefault("X-Amz-Signature")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Signature", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Content-Sha256", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Date")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Date", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Credential")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Credential", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Security-Token")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Security-Token", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Algorithm")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Algorithm", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-SignedHeaders", valid_606424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606425: Call_UntagResource_606413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_606425.validator(path, query, header, formData, body)
  let scheme = call_606425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606425.url(scheme.get, call_606425.host, call_606425.base,
                         call_606425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606425, url, valid)

proc call*(call_606426: Call_UntagResource_606413; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_606427 = newJObject()
  var query_606428 = newJObject()
  add(path_606427, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606428.add "tagKeys", tagKeys
  result = call_606426.call(path_606427, query_606428, nil, nil, nil)

var untagResource* = Call_UntagResource_606413(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606414,
    base: "/", url: url_UntagResource_606415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_606429 = ref object of OpenApiRestCall_605589
proc url_UpdateFlowSource_606431(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowSource_606430(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the source of a flow.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sourceArn: JString (required)
  ##            : The ARN of the source that you want to update.
  ##   flowArn: JString (required)
  ##          : The flow that is associated with the source that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `sourceArn` field"
  var valid_606432 = path.getOrDefault("sourceArn")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = nil)
  if valid_606432 != nil:
    section.add "sourceArn", valid_606432
  var valid_606433 = path.getOrDefault("flowArn")
  valid_606433 = validateParameter(valid_606433, JString, required = true,
                                 default = nil)
  if valid_606433 != nil:
    section.add "flowArn", valid_606433
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
  var valid_606434 = header.getOrDefault("X-Amz-Signature")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Signature", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Content-Sha256", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Date")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Date", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Credential")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Credential", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Security-Token")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Security-Token", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Algorithm")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Algorithm", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-SignedHeaders", valid_606440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606442: Call_UpdateFlowSource_606429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_606442.validator(path, query, header, formData, body)
  let scheme = call_606442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606442.url(scheme.get, call_606442.host, call_606442.base,
                         call_606442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606442, url, valid)

proc call*(call_606443: Call_UpdateFlowSource_606429; sourceArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  var path_606444 = newJObject()
  var body_606445 = newJObject()
  add(path_606444, "sourceArn", newJString(sourceArn))
  if body != nil:
    body_606445 = body
  add(path_606444, "flowArn", newJString(flowArn))
  result = call_606443.call(path_606444, nil, nil, nil, body_606445)

var updateFlowSource* = Call_UpdateFlowSource_606429(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_606430, base: "/",
    url: url_UpdateFlowSource_606431, schemes: {Scheme.Https, Scheme.Http})
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
